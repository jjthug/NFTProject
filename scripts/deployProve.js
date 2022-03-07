// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
let secret = require("../secret");

async function main() {

    const CD = await hre.ethers.getContractFactory("ProveTest");
    const cd = await CD.deploy();
    await cd.deployed();
    console.log("Deployed to : ", cd.address);

    // const cd  = await CD.attach("0x5FbDB2315678afecb367f032d93F642f64180aa3");

    await cd.setHash('ipfs://QmarLsVA3caLyS1WhwyPtpsunQJ7P1AgC4dxbmSbmz7N4s/json/');
    let hash = await cd.getHash();
    console.log("hash = ",hash);
    // await cd.setURL("acbd/json/");

    // await cd.setURL("QmeDAWZmwXzoALWesjRCHDonuVD1t8xQTed4c1gdhmTxwU/json/");

    // let theURL = await cd.theURL();
    // console.log("theURL =",theURL);
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