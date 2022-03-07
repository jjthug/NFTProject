// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
let secret = require("../secret");
let data = require("../test/addressesAndTokens");

async function main() {

    const CD = await hre.ethers.getContractFactory("ProjectName");
        
    const cd = await CD.deploy("ipfs://QmcAhXxcvAYEYrt64aKnvyt86JoMRKc6N5RoeyUQeJR9YFtr1",
    "0x7e314d39a78ce847b6ddd76a3fdga5addfd990dbaaa5234ef2a5a56a1341c21b8d8",
    "0xc0A0aEa4f8457Caa8C47ED5Bdfg5DA410E40EFCbf3c", 10, 40); 

    // const cd = await CD.attach("0xF99CF1d6c5dfg1955F920a26Bb20D83C915184cBA76");

    // await cd.configureDutchAuction();
    // await cd.configurePresale(1645771541, 1645807541, "10000000000000000", 8000);

    // await cd.reserve(data.addresses, data.tokens);
    // await cd.reserve(['0xc0A0aEa4f8457Caasda8C47ED5B5DA410E40EFCbf3c'], [10]);
    // await cd.reserve(['0xc0A0aEa4f8457Caasda8C47ED5B5DA410E40EFCbf3c'], [100]);
    // await cd.reserve(['0x3C44CdDdB6a900asdfa2b585dd299e03d12FA4293BC'], [100]);
    // await cd.reserve(data.addresses10, data.tokens10);
    // await cd.reserve(data.addresses10same, data.tokens10);
    // await cd.batchTransfer(data.addresses10, data.tokenIds10);
    // await cd.batchTransfer(data.addresses10same, data.tokens10);

    // await cd.setDummyURL('ipfs://QmV3vFasduuRVkCErqpg6CVF2xEvGfsMi7YV6xMXH1ccHRdhKgB');


    // await cd.batchTransfer(data.addresses2, data.tokens);
    // await cd.batchTransfer(['0x60C1F061B4fd365389dEFa3596FfFC8749D83b3B'], [100]);

    await cd.deployed();
    console.log("Deployed to : ", cd.address);
    // let val = await cd.getCurrentAuctionPrice();
    // console.log(val.toString());


    // await cd.reserve([],[]);

    // await cd.rollStartIndex();

    // await cd.setIPFSCIDHash("QmarLsVA3caLyS1WhswyPtpsunQJ7Pf1AgC4dxbmdfSbmz7N4s/json/");


    // await
    // .then(function(err, res) {
    //   console.log(res);
    // });
    // await cd.verify('0x8de2bba38d282749853426ff943055c2cb8261fd4848856776ecea6deb1ad41b6df32789db58154d91abc4f91b45c90a882dda847154bd0376b8a2841faff9fa1b',1);
    // let sign = "0x8de2bba38d282749853426ff943055c2cb8261fd4848856776ecea6deb1ad41b6df32789db58154d91abc4f91b45c90a882dda847154bd0376b8a2841faff9fa1b";
    // await cd.verify("0x8de2bba38d282749853426ff943055c2cb8261fd4848856776ecea6deb1ad41b6df32789db58154d91abc4f91b45c90a882dda847154bd0376b8a2841faff9fa1b",1);

  }


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });