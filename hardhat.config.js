require("@nomiclabs/hardhat-waffle");
let secret = require("./secret");
require('hardhat-contract-sizer');
require("@nomiclabs/hardhat-truffle5");
require('solidity-coverage')

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 module.exports = {
  defaultNetwork: "hardhat",
  solidity: {
    version:"0.8.12",
    settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
},
  networks: {
    hardhat: {
      // gasPrice : 500 * 1000000000
    },
    // rinkeby:{
    //   // gasPrice : secret.gasPrice * 1000000000,
    //   url: secret.urlRinkeby,
    //   accounts: [secret.pkAccount1]
    // }
  }
};
