const ProjectName = artifacts.require("ProjectName");
// Uncomment this for the test on line:65-70, after copying HelperContracts/JustAnotherContract.sol to contracts directory and compiling
// const externalContract = artifacts.require("ExternalContract"); 
const { expect, assert } = require("chai");
const { ethers, web3 } = require("hardhat");
const truffleAssert = require('truffle-assertions');

describe("ProjectName Public Sale (Dutch Auction)", function () {

  let projectName, balance;
  let presaleConfig, dutchAuctionConfig, publicSaleConfig;
  let auctionPrice;
  let provider;

  before(async function () {
    accounts = await web3.eth.getAccounts();
    projectName = await ProjectName.new("ipfs://QmezoosjRhhrEG1ZdZRMqD2orFFBGcy7cGe5ervyLxBUdF",
    "0x33b5a37c7ad1c85013b61bf46c645ada6d26e0ff1675c773758e6c33564523bd", "0xc0A0aEa4f8457Caa8C47ED5B5DA410E40EFCbf3c", 100, 500);

    presaleConfig = await projectName.presaleConfig();
    dutchAuctionConfig = await projectName.dutchAuctionConfig();
    auctionPrice  = await projectName.getCurrentAuctionPrice();
    provider = ethers.getDefaultProvider();

  });


  it("auctions correctly", async()=>{

    let blockNumBefore = await web3.eth.getBlockNumber();
    let blockBefore = await web3.eth.getBlock(blockNumBefore);
    let timestampBefore = blockBefore.timestamp;

    await projectName.configureDutchAuction(timestampBefore + 10000, 60,
      ethers.utils.parseEther('0.0000001'), ethers.utils.parseEther('0.00000001'), ethers.utils.parseEther('0.000000001'));
    
    dutchAuctionConfig = await projectName.dutchAuctionConfig();
    let mintFee;
    let n; //number of nfts

    n=8;
    mintFee = (auctionPrice * n).toString();
 
    //sale not active
    await truffleAssert.reverts( projectName.buyPublic(n, {value: mintFee}));

    await ethers.provider.send('evm_increaseTime', [10000]);
    await ethers.provider.send('evm_mine');
    
    auctionPrice  = await projectName.getCurrentAuctionPrice();
    mintFee = (auctionPrice * (n+1)).toString();

    await truffleAssert.passes( projectName.buyPublic(n, {value: mintFee}));

    auctionPrice  = await projectName.getCurrentAuctionPrice();
    mintFee = (auctionPrice * n).toString();
    //insufficient payment
    await truffleAssert.reverts( projectName.buyPublic(n+1, {value: mintFee}));

    // contract buy fails
    /* uncomment these after
       copying HelperContracts/JustAnotherContract.sol to contracts directory and compiling
       also uncomment line 3 :  *const AContract = artifacts.require("ExternalContract"); *
    */
    // let aContract = await externalContract.new();
    // try{
    // await truffleAssert.reverts(aContract.buyAuction(projectName.address, "2", {value: ethers.utils.parseEther('1000')}));   
    // }catch(e){
    //   expect(e.message).to.equal("VM Exception while processing transaction: reverted with reason string 'Contract buys not allowed'");
    // }

    //comment till here

    n = await projectName.ProjectName_SUPPLY();

    auctionPrice  = await projectName.getCurrentAuctionPrice();
    mintFee = (auctionPrice * n).toString();
    //supply maxed out
    await truffleAssert.reverts( projectName.buyPublic(n, {value: mintFee}));

    await ethers.provider.send('evm_increaseTime', [100000]);
    await ethers.provider.send('evm_mine');

    auctionPrice  = await projectName.getCurrentAuctionPrice();
    //Price remains at bottom price after reaching bottom price
    assert.equal(auctionPrice.toString() , dutchAuctionConfig.bottomPrice.toString());

  })

  it("rolls start index", async()=>{
    let n = await projectName.totalLeftToMint();
    
    while(n>0){
      if(n <= 400){
      auctionPrice  = await projectName.getCurrentAuctionPrice();
      mintFee = (auctionPrice * n).toString();
      await truffleAssert.passes( projectName.buyPublic(n, {value: mintFee}));
      console.log("transferred", n ," tokens to", accounts[0]);
      n = 0;
      } else{
        auctionPrice  = await projectName.getCurrentAuctionPrice();
        mintFee = (auctionPrice * 400).toString();
        await truffleAssert.passes( projectName.buyPublic(400, {value: mintFee}));
        console.log("transferred 400 tokens to", accounts[0]);
        n -=400;
      }
    }

    try{
      await projectName.randomizedStartIndex();
    }catch(e){
      expect(e.message).to.equal("VM Exception while processing transaction: reverted with reason string 'All tokens are not yet minted'");
    }

    let left = await projectName.totalLeftToMint()
    auctionPrice  = await projectName.getCurrentAuctionPrice();
    mintFee = (auctionPrice * left).toString();

    try {
     await projectName.buyPublic(left, {value: mintFee});
    } catch(e) {
      // Should mint atleast 1 NFT
      expect(e.message).to.equal("VM Exception while processing transaction: reverted with reason string 'Should mint atleast 1 NFT'");
    }

    let blockNumBefore = await web3.eth.getBlockNumber();
    let blockBefore = await web3.eth.getBlock(blockNumBefore);
    let timestampBefore = blockBefore.timestamp;

    await projectName.setNFTRevealTime(timestampBefore + 10000);

    try {
    await projectName.rollStartIndex();
    } catch(e) {
      // Roll index can be performed only after NFT Reveal time has passed
      expect(e.message).to.equal("VM Exception while processing transaction: reverted with reason string 'NFT Reveal time not reached yet'");
    }

    await ethers.provider.send('evm_increaseTime', [10000]);
    await ethers.provider.send('evm_mine');

    // NFT Reveal time has passed
    await truffleAssert.passes( projectName.rollStartIndex());

    let startIndex = await projectName.randomizedStartIndex();
    console.log("randomized start index", startIndex.toNumber());

    try{
      await projectName.randomizedStartIndex();
    }catch(e){
      expect(e.message).to.equal("VM Exception while processing transaction: reverted with reason string 'Index already set'");
    }

  })

  
  it("token uri before setting base uri", async()=>{
    
    await projectName.setDummyURL('abcdefg');
    let dummyURI = await projectName.dummyURI();
    let tokenUri = await projectName.tokenURI(1);

    assert.equal(tokenUri, dummyURI);

  })

  it("sets correct base uri", async()=>{
    
    try{
      await projectName.setBaseURI("abcd")
    }catch(e){
      expect(e.message).to.equal("VM Exception while processing transaction: reverted with reason string 'Doesn't match with the provenance hash'");
    }

    await truffleAssert.passes(await projectName.setBaseURI("ipfs://QmarLsVA3caLyS1WhwyPtpsunQJ7P1AgC4dxbmSbmz7N4s/json/"));
  })

  it("token uri after setting base uri", async()=>{
    
    await projectName.setDummyURL('abcdefg');
    let dummyURI = await projectName.dummyURI();
    let tokenUri = await projectName.tokenURI(1);

    assert.notEqual(tokenUri, dummyURI);
  })


})