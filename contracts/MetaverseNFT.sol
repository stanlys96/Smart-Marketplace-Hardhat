// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MetaverseNFT is ERC721URIStorage {
  uint256 private _currentTokenId;

  constructor() ERC721("Metaverse NFT", "MFT") {}

  function mintNFT(string memory tokenURI) public returns (uint) {
    _currentTokenId++;

    _mint(msg.sender, _currentTokenId);
    _setTokenURI(_currentTokenId, tokenURI);  
    return _currentTokenId;
  }
}