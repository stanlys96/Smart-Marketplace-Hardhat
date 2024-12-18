import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";

const PRIVATE_KEY = vars.get("PRIVATE_KEY");

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },

  networks: {
    "lisk-sepolia-testnet": {
      url: "https://rpc.sepolia-api.lisk.com",
      accounts: [PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: {
      "lisk-sepolia-testnet": "empty",
    },
    customChains: [
      {
        network: "lisk-sepolia-testnet",
        chainId: 4202,
        urls: {
          apiURL: "https://sepolia-blockscout.lisk.com/api",
          browserURL: "https://sepolia-blockscout.lisk.com",
        },
      },
    ],
  },
  sourcify: {
    enabled: false,
  },
};

export default config;
