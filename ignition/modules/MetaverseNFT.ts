const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const MetaverseNFT = buildModule("MetaverseNFT", (m: any) => {
  const metaverseNFT = m.contract("MetaverseNFT", [
    "0xA8C878309A154Fe764307885d9ccDC3b58BAffF3",
  ]);
  return { metaverseNFT };
});

module.exports = MetaverseNFT;
