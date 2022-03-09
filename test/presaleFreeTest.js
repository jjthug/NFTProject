// const ProjectName = artifacts.require("ProjectName");
const { expect, assert } = require("chai");
const { ethers, web3 } = require("hardhat");
const truffleAssert = require('truffle-assertions');

describe("ProjectName Presale Free Mint", function () {
  
  let projectName, totalSupply;
  let presaleConfig, dutchAuctionConfig, publicSaleConfig;
  let auctionPrice;
  let provider, owner, notOwner;
//   let domain, types, value;
    let addr1,addr2,addr3;
  before(async function () {

    let ProjectName = await ethers.getContractFactory("ProjectName");  
    projectName = await ProjectName.deploy("ipfs://QmezoosjRhhrEG1ZdZRMqD2orFFBGcy7cGe5ervyLxBUdF",
    "0x1abbd2457d497fb5054bf780aba3e67de04596e7c6ddec13afbbd57654e74a8f", "0xc0A0aEa4f8457Caa8C47ED5B5DA410E40EFCbf3c", 100, 9999);

    [addr1, addr2, addr3] = await ethers.getSigners();

    presaleConfig = await projectName.presaleConfig();
    dutchAuctionConfig = await projectName.dutchAuctionConfig();
    owner = await new ethers.Wallet('d7cf1f0e6a8f85844e74c04a02d9b0e740a081ba4f9fd18f8ce6b8f9a5f5e75e');
    notOwner = await new ethers.Wallet('e7cf1f0e6a8f85844e74c04a02d9b0e740a081ba4f9fd18f8ce6b8f9a5f5e75e');
    totalSupply = await projectName.ProjectName_SUPPLY();
  });

  it("presale free correctly", async()=>{

    let blockNumBefore = await web3.eth.getBlockNumber();
    let blockBefore = await web3.eth.getBlock(blockNumBefore);
    let timestampBefore = blockBefore.timestamp;

    let n;
    n = await projectName.ProjectName_SUPPLY();
    let supplyLimit = (n/2);
    
    await projectName.configurePresale(timestampBefore + 10000, timestampBefore + 20000,
      ethers.utils.parseEther('0.001'), 4000);

    let domain = {
    name: 'ProjectName',
    version: '1',
    chainId: 31337 ,
    verifyingContract: projectName.address
    };

    // The named list of all type definitions
    let types = {
        freeMint: [
        {name: "buyer", type: "address"},
        {name: "limit", type: "uint256"}
        ]
    };

    // The data to sign
    let value = {
    buyer: addr2.address,
    limit: 3
    };
    let signature = await owner._signTypedData(domain, types, value);

    presaleConfig = await projectName.presaleConfig();
    let mintFee = (presaleConfig.mintPrice).toString();

    // Presale not active
    try{
      await projectName.connect(addr2).buyPresaleFree( signature, 1 ,3, {value: mintFee})
    } catch(e){
      expect(e.message).to.equal("VM Exception while processing transaction: reverted with reason string 'Presale not active'");
    }

    await ethers.provider.send('evm_increaseTime', [10000]);
    await ethers.provider.send('evm_mine');
    
    await truffleAssert.passes( await projectName.connect(addr2).buyPresaleFree( signature, 1 ,3));

    let anotherSignature = await notOwner._signTypedData(domain, types, value);

    try{
      // Invalid signature
      await projectName.connect(addr2).buyPresaleFree( anotherSignature, 1 ,3);
    } catch(e){
      expect(e.message).to.equal("VM Exception while processing transaction: reverted with reason string 'Invalid signature'");
    }

    types = {
        presale: [
        {name: "buyer", type: "address"},
        {name: "limit", type: "uint256"}
        ]
    };

     signature = await owner._signTypedData(domain, types, value);

    try{
        // Invalid signature
        await projectName.connect(addr2).buyPresaleFree( signature, 1 ,3);
      } catch(e){
        expect(e.message).to.equal("VM Exception while processing transaction: reverted with reason string 'Invalid signature'");
      }

    types = {
        freeMint: [
        {name: "buyer", type: "address"},
        {name: "limit", type: "uint256"}
        ]
    };

    signature = await owner._signTypedData(domain, types, value);

    await truffleAssert.passes( await projectName.connect(addr2).buyPresaleFree( signature, 1 ,3));
    
    mintFee = (presaleConfig.mintPrice*2).toString();
    try{
      // Mint limit exceeded
      await projectName.connect(addr2).buyPresaleFree( signature, 2 ,3, {value: mintFee})
    } catch(e){
      expect(e.message).to.equal("VM Exception while processing transaction: reverted with reason string 'Mint limit exceeded'");
    }

    try{
      // Total Supply limit reached
      await projectName.connect(addr2).buyPresaleFree( signature, totalSupply+1 ,3)
    } catch(e){
      expect(e.message).to.equal("VM Exception while processing transaction: reverted with reason string 'Total Supply limit reached'");
    }

    try{
      // Presale Supply limit reached
      await projectName.connect(addr2).buyPresaleFree( signature, presaleConfig.supplyLimit+1 ,3)
    } catch(e){
      expect(e.message).to.equal("VM Exception while processing transaction: reverted with reason string 'Presale Supply limit reached'");
    }

  })

  it("cannot burn", async()=>{

    try{
        await projectName.connect(addr2).transferFrom(addr2.address, '0x0000000000000000000000000000000000000000', 1);
    }catch(e){
      expect(e.message).to.equal("VM Exception while processing transaction: reverted with custom error 'TransferToZeroAddress()'");

    }
    
  })

})