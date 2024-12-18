const {
  buildModule: theBuildModule,
} = require("@nomicfoundation/hardhat-ignition/modules");

const MetaverseMarketplaceModule = theBuildModule(
  "MetaverseMarketplace",
  (m: any) => {
    const metaverseMarketplace = m.contract("MetaverseMarketplace", [
      "0x1A2bEcad24E4561499aDa8bfBB00623996e5Eff0",
    ]);
    return { metaverseMarketplace };
  }
);

module.exports = MetaverseMarketplaceModule;
