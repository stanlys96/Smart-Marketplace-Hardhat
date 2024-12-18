// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error MetaverseMarketplace__PriceMustBeAboveZero();
error MetaverseMarketplace__PriceNotMet(
    string productCode,
    address seller,
    uint256 price
);
error MetaverseMarketplace__NoProceeds();
error MetaverseMarketplace__AddressLessThan1DayForMetaverseToken(address senderAddress);

contract MetaverseMarketplace is ReentrancyGuard {
  struct Buyer {
    address buyer;
    uint256 quantity;
    uint256 totalPrice;
  }

  struct Comment {
    address commenter;
    uint256 rating;
    string comment;
    uint time;
    string dateString;
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
    string productCode;
    uint256 nftTokenId;
    Comment[] comments;
    Buyer[] buyers;
  }

  mapping(address => mapping(string => uint256)) private s_proceeds;
  mapping(address => string) private usernames;
  mapping(address => uint256) public addressToLastGetMetaverseToken;
  IERC20 public metaverseToken;

  Listing[] private s_allListings;

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

  event ItemBought(
    address indexed buyer,
    string indexed productCode,
    uint256 indexed price
  );

  event CommentAdded(
    address indexed commenter,
    string indexed comment,
    string indexed productCode,
    address seller
  );

  event SetUsername(
    address indexed owner,
    string indexed username
  );

  event MetaverseAirdrop(
    address indexed person
  );

  event ProceedsWithdrawn(
    address indexed person,
    string indexed currency,
    uint256 indexed amount
  );

  event ListingUpdated(
    address indexed seller,
    string indexed productCode,
    string indexed title,
    uint256 price
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
    Buyer[] memory buyers;
    Listing memory newListing = Listing(
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
      productCode,
      nftTokenId,
      comments,
      buyers
    );
    s_allListings.push(newListing);
    emit ItemListed(
      msg.sender,
      price,
      productCode,
      title
    );
  }

  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  function changeListingVisibility(string memory productCode, bool publish) public {
    for (uint256 i = 0; i < s_allListings.length; i++) {
      if (compareStrings(s_allListings[i].productCode, productCode)) {
        s_allListings[i].published = publish;
        emit ItemPublished(msg.sender, productCode, publish);
        break;
      }
    }
  }

  function buyItem(string memory productCode, address seller, uint256 quantity)
    external
    payable
    nonReentrant
  {
    for (uint256 i = 0; i < s_allListings.length; i++) {
      if (compareStrings(s_allListings[i].productCode, productCode)) {
        Listing memory listedItem = s_allListings[i];
        if (msg.value < listedItem.price) {
          revert MetaverseMarketplace__PriceNotMet(
            productCode,
            seller,
            listedItem.price
          );
        }
        Buyer memory currentBuyer = Buyer(
          msg.sender,
          quantity,
          quantity * listedItem.price
        );
        s_proceeds[listedItem.seller][listedItem.currency] += msg.value;
        s_allListings[i].buyers.push(currentBuyer);
        emit ItemBought(msg.sender, productCode, listedItem.price);
        break;
      }
    }
  }

  function addComment(
    string memory comment, 
    uint256 rating, 
    string memory dateString, 
    string memory productCode, 
    address seller
  ) public {
    for (uint i = 0; i < s_allListings.length; i++) {
      if (compareStrings(s_allListings[i].productCode, productCode)) {
        s_allListings[i].comments.push(Comment(
          msg.sender,
          rating,
          comment,
          block.timestamp,
          dateString
        ));
        emit CommentAdded(msg.sender, comment, productCode, seller);
        break;
      }
    }
  }

  function updateListing(
    string memory productCode, 
    uint256 price, 
    string memory title, 
    string memory description, 
    string memory productInfo, 
    string memory productUrl, 
    string memory imageUrl
  ) public {
    for (uint i = 0; i < s_allListings.length; i++) {
      if (compareStrings(s_allListings[i].productCode, productCode)) {
        Listing memory listingTemp = Listing(
          price,
          s_allListings[i].seller,
          s_allListings[i].published,
          s_allListings[i].productType,
          title,
          description,
          imageUrl,
          s_allListings[i].currency,
          productUrl,
          productInfo,
          s_allListings[i].productCode,
          s_allListings[i].nftTokenId,
          s_allListings[i].comments,
          s_allListings[i].buyers
        );
        s_allListings[i] = listingTemp;
        emit ListingUpdated(msg.sender, productCode, title, price);
        break;
      }
    }
  }

  function withdrawProceeds(string memory currency) external {
    uint256 proceeds = s_proceeds[msg.sender][currency];
    if (proceeds <= 0) {
      revert MetaverseMarketplace__NoProceeds();
    }
    s_proceeds[msg.sender][currency] = 0;
    (bool success, ) = payable(msg.sender).call{value: proceeds}("");
    if (success) {
      emit ProceedsWithdrawn(msg.sender, currency, proceeds);
    }
    require(success, "Transfer failed!");
  }

  function getUserListing()
    external
    view
    returns (Listing[] memory)
  {
    Listing[] memory currentListing = new Listing[](s_allListings.length);
    for (uint256 i = 0; i < s_allListings.length; i++) {
      if (s_allListings[i].seller == msg.sender) {
        currentListing[i] = s_allListings[i];
      }
    }
    return currentListing;
  }

  function getListingByProductType(string memory productType)
    external
    view
    returns (Listing[] memory)
  {
    Listing[] memory currentListing = new Listing[](s_allListings.length);
    for (uint256 i = 0; i < s_allListings.length; i++) {
      if (compareStrings(s_allListings[i].productType, productType)) {
        currentListing[i] = s_allListings[i];
      }
    }
    return currentListing;
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
    emit MetaverseAirdrop(msg.sender);
  }

  function setUsername(string memory newUsername) public {
    usernames[msg.sender] = newUsername;
    emit SetUsername(msg.sender, newUsername);
  }

  function getAllUserListings() public view returns (Listing[] memory) {
    return s_allListings;
  }
}