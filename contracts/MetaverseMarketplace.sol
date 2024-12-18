// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error MetaverseMarketplace__PriceMustBeAboveZero();
error MetaverseMarketplace__NotApprovedForMarketplace();
error MetaverseMarketplace__PriceNotMet(
    string productCode,
    address seller,
    uint256 price
);
error MetaverseMarketplace__NoProceeds();
error MetaverseMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error MetaverseMarketplace__NotListed(address nftAddress, uint256 tokenId);
error MetaverseMarketplace__TheOwner();
error MetaverseMarketplace__NotOwner();
error MetaverseMarketplace__AddressLessThan1DayForMetaverseToken(address senderAddress);

contract MetaverseMarketplace is ReentrancyGuard {
  struct Comment {
    address commenter;
    uint256 rating;
    string comment;
    uint time;
  }

  struct Listing {
    uint256 price;
    address seller;
    bool published;
    string productType;
    string title;
    string description;
    string imageUrl;
    string currency;
    string productUrl;
    string productInfo;
    uint256 nftTokenId;
    Comment[] comments;
  }

  struct Proceed {
    uint256 ethereum;
    uint256 lisk;
    uint256 metaverse;
  }

  mapping(address => mapping(string => Listing)) private s_listings;
  mapping(address => mapping(string => uint256)) private s_proceeds;
  mapping(address => string) private usernames;
  mapping(address => uint256) public addressToLastGetMetaverseToken;
  IERC20 public metaverseToken;

  event ItemListed(
    address indexed seller,
    uint256 indexed price,
    string indexed productCode,
    string title
  );

  event ItemPublished(
    address indexed seller,
    string indexed productCode,
    bool indexed publish
  );

  event ItemCanceled(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
  );

  event ItemBought(
    address indexed buyer,
    string indexed productCode,
    uint256 indexed price
  );

  constructor(address _metaverseTokenAddress) {
    metaverseToken = IERC20(_metaverseTokenAddress);
  }

  function listItem(
    uint256 price,
    string memory productType,
    string memory title,
    string memory description,
    string memory imageUrl,
    string memory currency,
    string memory productUrl,
    string memory productInfo,
    string memory productCode,
    uint256 nftTokenId
  )
    external
  {
    if (price <= 0) {
      revert MetaverseMarketplace__PriceMustBeAboveZero();
    }
    Comment[] memory comments;
    s_listings[msg.sender][productCode] = Listing(
      price,
      msg.sender,
      false,
      productType,
      title,
      description,
      imageUrl,
      currency,
      productUrl,
      productInfo,
      nftTokenId,
      comments
    );
    emit ItemListed(
      msg.sender,
      price,
      productCode,
      title
    );
  }

  function changeListingVisibility(string memory productCode, bool publish) public {
    s_listings[msg.sender][productCode].published = publish;
    emit ItemPublished(msg.sender, productCode, publish);
  }

  function buyItem(string memory productCode, address seller)
    external
    payable
    nonReentrant
  {
    Listing memory listedItem = s_listings[seller][productCode];
    if (msg.value < listedItem.price) {
      revert MetaverseMarketplace__PriceNotMet(
        productCode,
        seller,
        listedItem.price
      );
    }
    s_proceeds[listedItem.seller][listedItem.currency] += msg.value;
    emit ItemBought(msg.sender, productCode, listedItem.price);
  }

  function withdrawProceeds(string memory currency) external {
    uint256 proceeds = s_proceeds[msg.sender][currency];
    if (proceeds <= 0) {
      revert MetaverseMarketplace__NoProceeds();
    }
    s_proceeds[msg.sender][currency] = 0;
    (bool success, ) = payable(msg.sender).call{value: proceeds}("");
    require(success, "Transfer failed!");
  }

  function getListing(string memory productCode)
    external
    view
    returns (Listing memory)
  {
    return s_listings[msg.sender][productCode];
  }

  function getProceeds(address seller, string memory currency) external view returns (uint256) {
    return s_proceeds[seller][currency];
  }

  function get1000MetaverseToken() public {
    if (block.timestamp - addressToLastGetMetaverseToken[msg.sender] < 1 days) {
      revert MetaverseMarketplace__AddressLessThan1DayForMetaverseToken(msg.sender);
    }
    addressToLastGetMetaverseToken[msg.sender] = block.timestamp;
    metaverseToken.transfer(msg.sender, 1000 ether);
  }
}