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
        
    // const cd = await CD.deploy("ipfs://QmcAhXxcvAYEYrt64aKnvyt86JoMRKc6N5RoeyUQeJR9YFtr1","0xb5a5478dd573239c95ee85e989d5ed2f20b1019620136026d3f009654d1f806d","0x74D4163f4d5B4D435BD44FBbE03Aad92daAF240f", 100, 10000); 
    const cd = await CD.attach("0xb34fFD31a9bD8a261b4E415274442d5E39966637"); 

    await cd.buyPublic(400, {value: ethers.utils.parseEther("0.05")});

    // await cd.deployed();
    // console.log("Deployed to : ", cd.address);

  }


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });