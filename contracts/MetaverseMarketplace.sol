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

  struct UserProfile {
    string username;
    string profileImageUrl;
  }

  mapping(address => mapping(string => uint256)) private s_proceeds;
  mapping(address => UserProfile) private userProfiles;
  mapping(address => uint256) public addressToLastGetMetaverseToken;
  mapping(string => mapping(address => bool)) public productCodeCommentToAddress;
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

  event SetUserProfile(
    address indexed owner,
    string indexed username,
    string indexed profileImageUrl
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

  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
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

  function changeListingVisibility(string memory productCode, bool publish) public {
    for (uint256 i = 0; i < s_allListings.length; i++) {
      if (compareStrings(s_allListings[i].productCode, productCode)) {
        require(s_allListings[i].seller == msg.sender, "Not your own product!");
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
        require(listedItem.seller != msg.sender, "Can not buy your own product!");
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
        if (compareStrings(listedItem.currency, "METT")) {
          metaverseToken.transferFrom(msg.sender, address(this), msg.value);
        }
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
        require(s_allListings[i].seller != msg.sender, "Can not comment on your own products!");
        require(productCodeCommentToAddress[s_allListings[i].productCode][msg.sender] == false, "Can not comment more than once!");
        productCodeCommentToAddress[s_allListings[i].productCode][msg.sender] = true;
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
        require(s_allListings[i].seller == msg.sender, "Can not edit another person's product!");
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
    if (compareStrings(currency, "ETH")) {
      (bool success, ) = payable(msg.sender).call{value: proceeds}("");
      if (success) {
        emit ProceedsWithdrawn(msg.sender, currency, proceeds);
      }
      require(success, "Transfer failed!");  
    } else if (compareStrings(currency, "METT")) {
      metaverseToken.transfer(msg.sender, proceeds);
    }
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

  function getListingByProductCode(string memory productCode) external view returns (Listing memory) {
    for (uint256 i = 0; i < s_allListings.length; i++) {
      if (compareStrings(s_allListings[i].productCode, productCode)) {
        return s_allListings[i];
      }
    }
    Comment[] memory comments;
    Buyer[] memory buyers;
    return Listing(0, address(0), false, "", "", "", "", "", "", "", "", 0, comments, buyers);
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

  function setUserProfile(string memory newUsername, string memory profileImageUrl) public {
    userProfiles[msg.sender] = UserProfile(
      newUsername,
      profileImageUrl
    );
    emit SetUserProfile(msg.sender, newUsername, profileImageUrl);
  }

  function getAllUserListings() public view returns (Listing[] memory) {
    return s_allListings;
  }

  function productCodeExists(string memory productCode) public view returns (bool) {
    for (uint256 i = 0; i < s_allListings.length; i++) {
      if (compareStrings(s_allListings[i].productCode, productCode)) {
        return true;
      }
    }
    return false;
  }

  function getUserProfile(address profileOwner) external view returns (UserProfile memory) {
    return userProfiles[profileOwner];
  }
}