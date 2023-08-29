require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require('dotenv').config({ path: __dirname + '/.env' })

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        },
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        },
      }
    ],
  },
  networks: {
    mainnet: {
      url: process.env.RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
    goerli: {
      url: process.env.RPC_URL,
      accounts: [process.env.PRIVATE_KEY,process.env.PRIVATE_KEY2],
    },
    sepolia: {
      url: process.env.RPC_URL,
      gasPrice: 29000000000,
      accounts: [process.env.PRIVATE_KEY,process.env.PRIVATE_KEY2],
    },

  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ABI_KEY,
      goerli: process.env.ABI_KEY,
      sepolia: process.env.ABI_KEY
    }
  }

};
