const {
  buildModule: theBuildModule,
} = require("@nomicfoundation/hardhat-ignition/modules");

const MetaverseMarketplaceModule = theBuildModule(
  "MetaverseMarketplaceModule_V9",
  (m: any) => {
    const metaverseMarketplace = m.contract("MetaverseMarketplace", [
      "0xc3d5e089ecb33357E5A2e18E99B83A4651A190d6",
    ]);
    return { metaverseMarketplace };
  }
);

module.exports = MetaverseMarketplaceModule;
