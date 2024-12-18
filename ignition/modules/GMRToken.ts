import { ethers } from "ethers";
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const TokenModule = buildModule("GumroadToken", (m: any) => {
  const token = m.contract("GMR", ["Gumroad", "GMR", ethers.parseUnits("1000000000", 18)]);
  return { token };
});

module.exports = TokenModule;