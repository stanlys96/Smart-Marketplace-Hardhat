const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const MetaverseNFT = buildModule("MetaverseNFT", (m: any) => {
  const metaverseNFT = m.contract("MetaverseNFT");
  return { metaverseNFT };
});

module.exports = MetaverseNFT;
