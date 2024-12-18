import { ethers } from "ethers";
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const TokenModule = buildModule("MetaverseToken", (m: any) => {
  const token = m.contract("Metaverse", [
    "Metaverse",
    "METT",
    ethers.parseUnits("1000000000", 18),
  ]);
  return { token };
});

module.exports = TokenModule;
