// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error MetaverseMarketplace__PriceMustBeAboveZero();
error MetaverseMarketplace__NotApprovedForMarketplace();
error MetaverseMarketplace__PriceNotMet(
    address nftAddress,
    uint256 tokenId,
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

  mapping(address => Listing) private s_listings;
  mapping(address => Proceed) private s_proceeds;
  mapping(address => string) private usernames;
  mapping(address => uint256) public addressToLastGetMetaverseToken;
  IERC20 public metaverseToken;

  event ItemListed(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    string action
  );

  event ItemCanceled(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
  );

  event ItemBought(
    address indexed buyer,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
  );

  // modifier isListed(
  //   address nftAddress,
  //   uint256 tokenId,
  //   bool shouldBeListed
  // ) {
  //     Listing memory listedItem = s_listings[nftAddress][tokenId];
  //     if (listedItem.price > 0 && shouldBeListed == false) {
  //       revert MetaverseMarketplace__AlreadyListed(nftAddress, tokenId);
  //     } else if (listedItem.price <= 0 && shouldBeListed == true) {
  //       revert MetaverseMarketplace__NotListed(nftAddress, tokenId);
  //     }
  //     _;
  // }

  // modifier isOwner(
  //   address nftAddress,
  //   uint256 tokenId,
  //   address spender,
  //   bool shouldBeOwner
  // ) {
  //   IERC721 nft = IERC721(nftAddress);
  //   address owner = nft.ownerOf(tokenId);
  //   if (owner != spender && shouldBeOwner == true) {
  //     revert MetaverseMarketplace__NotOwner();
  //   } else if (owner == spender && shouldBeOwner == false) {
  //     revert MetaverseMarketplace__TheOwner();
  //   }
  //   _;
  // }

  constructor(address _metaverseTokenAddress) {
    metaverseToken = IERC20(_metaverseTokenAddress);
  }

  function listItem(
    uint256 price,
    string productType,
    string title,
    string description,
    string imageUrl,
    string currency,
    string productUrl,
    string productInfo,
    uint256 nftTokenId
  )
    external
  {
    if (price <= 0) {
      revert MetaverseMarketplace__PriceMustBeAboveZero();
    }
    s_listings[msg.sender] = Listing(
      price,
      msg.sender
    );
    emit ItemListed(
      msg.sender,
      nftAddressTemp,
      tokenIdTemp,
      priceTemp,
      "list_item"
    );
  }

  function cancelListing(address nftAddress, uint256 tokenId)
    external
  {
    uint256 price = s_listings[nftAddress][tokenId].price;
    delete s_listings[nftAddress][tokenId];
    emit ItemCanceled(msg.sender, nftAddress, tokenId, price);
  }

  function buyItem(address nftAddress, uint256 tokenId)
    external
    payable
    nonReentrant
  {
    Listing memory listedItem = s_listings[nftAddress][tokenId];
    if (msg.value < listedItem.price) {
      revert MetaverseMarketplace__PriceNotMet(
        nftAddress,
        tokenId,
        listedItem.price
      );
    }
    s_proceeds[listedItem.seller] += msg.value;
    delete s_listings[nftAddress][tokenId];
    IERC721(nftAddress).safeTransferFrom(
      listedItem.seller,
      msg.sender,
      tokenId
    );
    emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
  }

  function updateListing(
    address nftAddress,
    uint256 tokenId,
    uint256 newPrice
  )
    external
    nonReentrant
  {
    if (newPrice <= 0) {
      revert MetaverseMarketplace__PriceMustBeAboveZero();
    }
    s_listings[nftAddress][tokenId].price = newPrice;
    emit ItemListed(
      msg.sender,
      nftAddress,
      tokenId,
      newPrice,
      "update_price"
    );
  }

  function withdrawProceeds() external {
    uint256 proceeds = s_proceeds[msg.sender];
    if (proceeds <= 0) {
      revert MetaverseMarketplace__NoProceeds();
    }
    s_proceeds[msg.sender] = 0;
    (bool success, ) = payable(msg.sender).call{value: proceeds}("");
    require(success, "Transfer failed!");
  }

  function getListing(address nftAddress, uint256 tokenId)
    external
    view
    returns (Listing memory)
  {
    return s_listings[nftAddress][tokenId];
  }

  function getProceeds(address seller) external view returns (uint256) {
    return s_proceeds[seller];
  }

  function get1000MetaverseToken() public {
    if (block.timestamp - addressToLastGetMetaverseToken[msg.sender] < 1 days) {
      revert MetaverseMarketplace__AddressLessThan1DayForMetaverseToken(msg.sender);
    }
    addressToLastGetMetaverseToken[msg.sender] = block.timestamp;
    metaverseToken.transfer(msg.sender, 1000 ether);
  }
}