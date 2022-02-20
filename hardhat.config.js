require("@nomiclabs/hardhat-waffle");
require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("hardhat-deploy");
require("hardhat-gas-reporter");
require('hardhat-abi-exporter');

const networks = require("./config/networks.json");

process.env.NETWORKS = JSON.stringify(networks.goerli);

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.7",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.DEV_MAINNET_ALCHEMY_APP_PRIVATE_KEY}`,
        blockNumber: 13015117,
      },
    },
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${process.env.DEV_MAINNET_ALCHEMY_APP_PRIVATE_KEY}`,
      accounts: [`0x${process.env.TEST_WALLET_PRIVATE_KEY}`],
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.DEV_MAINNET_ALCHEMY_APP_PRIVATE_KEY}`,
      accounts: [`0x${process.env.TEST_WALLET_PRIVATE_KEY}`],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 100,
    coinmarketcap: '9896bb6e-1429-4e65-8ba8-eb45302f849b',
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  abiExporter: {
    path: './abis',
    runOnCompile: true,
    clear: true,
    flat: true,
    spacing: 2,
    pretty: true,
  }
};
