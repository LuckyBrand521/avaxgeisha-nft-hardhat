// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
  ERC721[] public collections;

  struct NFTStructure {
    uint256 id;
    uint256 tokenId;
    address minter;
    uint256 price;
    bool isForSale;
  }

  uint256 internal constant PERCENT100 = 1e6; // 100%
  uint256 public royalty = 3e4; // royalty = 3%
  uint256 public marketing = 2e4; // royalty = 2%
  uint256 public marketingFee;

  mapping(ERC721 => NFTStructure[]) public itemsOnMarket;
  mapping(address => uint256) public royaltyFees;
  mapping(ERC721 => mapping(uint256 => bool)) public deployedCollectionItems;

  event DeployedItemForSale(ERC721 collection, uint256 id, uint256 tokenId, address minter, uint256 price);
  event ItemSold(ERC721 collection, uint256 id, uint256 tokenId, address minter, address buyer, uint256 price);
  event UpdateItem(ERC721 collection, uint256 id, uint256 tokenId, bool isForSale, uint256 price);
  event AddCollection(ERC721 collection);
  event RemoveCollection(ERC721 collection);

  constructor() {
  }

  modifier CollectionExists(ERC721 collection_){
    bool _isReg;
    for(uint i = 0 ; i < collections.length ; i++) {
      if(collections[i] == collection_) {
        _isReg = true;
      }
    }
    require(_isReg, "Collection is not deployed on market-place.");
    _;
  }

  modifier ItemExists(ERC721 collection_, uint256 id_){
    require(id_ < itemsOnMarket[collection_].length && itemsOnMarket[collection_][id_].id == id_, "Could not find item");
    _;
  }

  modifier OnlyItemOwner(ERC721 collection_, uint256 tokenId_){
    require(collection_.ownerOf(tokenId_) == msg.sender, "Sender does not own the item");
    _;
  }

  modifier HasTransferApproval(ERC721 collection_, uint256 tokenId_){
    require(collection_.getApproved(tokenId_) == address(this), "Market is not approved");
    _;
  }

  modifier IsForSale(ERC721 collection_, uint256 id_){
    require(itemsOnMarket[collection_][id_].isForSale, "Item is not for sale.");
    _;
  }

  function setItemForSale(ERC721 collection_, uint256 tokenId_, uint256 price_)
    CollectionExists(collection_)
    OnlyItemOwner(collection_, tokenId_)
    HasTransferApproval(collection_, tokenId_)
    external
    returns (uint256){
      require(!deployedCollectionItems[collection_][tokenId_], "This token is already deployed.");
      uint256 _newItemId = itemsOnMarket[collection_].length;
      itemsOnMarket[collection_].push(NFTStructure({
        id: _newItemId,
        tokenId: tokenId_,
        minter: msg.sender,
        price: price_,
        isForSale: true
      }));

      assert(itemsOnMarket[collection_][_newItemId].id == _newItemId);
      deployedCollectionItems[collection_][tokenId_] = true;
      emit DeployedItemForSale(collection_, _newItemId, tokenId_, msg.sender, price_);
      return _newItemId;
  }

  function buyItem(ERC721 collection_, uint256 id_)
    ItemExists(collection_, id_)
    IsForSale(collection_, id_)
    payable
    external {
      require(collection_.getApproved(itemsOnMarket[collection_][id_].tokenId) == address(this), "Market is not approved");
      require(msg.value >= itemsOnMarket[collection_][id_].price, "Not enough funds sent.");
      require(msg.sender != collection_.ownerOf(itemsOnMarket[collection_][id_].tokenId), "Owner of item can't buy item.");

      address _ownerOfItem = collection_.ownerOf(itemsOnMarket[collection_][id_].tokenId);

      uint256 _royaltyFee = 0;
      uint256 _marketingFee = 0;

      _royaltyFee = (msg.value) * (royalty) / (PERCENT100);
      _marketingFee = (msg.value) * (marketing) / (PERCENT100);

      marketingFee += _marketingFee;

      address _minter = itemsOnMarket[collection_][id_].minter;

      royaltyFees[_minter] += _royaltyFee;

      uint256 _remain = msg.value - _royaltyFee - _marketingFee;
      itemsOnMarket[collection_][id_].isForSale = false;

      uint256 _tokenId = itemsOnMarket[collection_][id_].tokenId;
      uint256 _price = itemsOnMarket[collection_][id_].price;

      collection_.safeTransferFrom(_ownerOfItem, msg.sender, _tokenId);
      payable(_ownerOfItem).transfer(_remain);

      emit ItemSold(collection_, id_, _tokenId, _minter, msg.sender, _price);
  }

  function updateItem(ERC721 collection_, uint256 id_, bool isForSale_, uint256 newPrice_)
    ItemExists(collection_, id_)
    public {
      uint256 _tokenId = itemsOnMarket[collection_][id_].tokenId;
      address _ownerOfItem = collection_.ownerOf(_tokenId);

      require(_ownerOfItem == msg.sender, "Sender does not own the item");
      require((newPrice_ > 0 && newPrice_ != itemsOnMarket[collection_][id_].price) || isForSale_ != itemsOnMarket[collection_][id_].isForSale,
        "price must be bigger than 0 or you don't feel to need update for sale.");

      itemsOnMarket[collection_][id_].price = newPrice_;
      itemsOnMarket[collection_][id_].isForSale = isForSale_;
      emit UpdateItem(collection_, id_, _tokenId, isForSale_, newPrice_);
  }

  function amountCollections() external view returns(uint256) {
    return collections.length;
  }

  function amountItemsForSale(ERC721 collection_) external view returns(uint256) {
    return itemsOnMarket[collection_].length;
  }

  function setRoyalty(uint256 royalty_) public onlyOwner {
    royalty = royalty_;
  }

  function addCollection(ERC721 collection_)
    onlyOwner
    external {
      bool _isReg;
      for(uint i = 0 ; i < collections.length ; i++) {
        if(collections[i] == collection_) {
          _isReg = true;
        }
      }
      require(!_isReg, "Item is already deployed on market.");
      collections.push(collection_);
      emit AddCollection(collection_);
  }

  function removeCollection(ERC721 collection_) public onlyOwner {
    for (uint256 index = 0; index < collections.length; index++) {
      if (collections[index] == collection_) {
        collections[index] = collections[collections.length - 1];
        collections.pop();
      }
    }
    emit RemoveCollection(collection_);
  }

  function getRoyaltyAmount(address royaltyFeeOwner_) public view returns(uint256) {
    uint256 _royaltyAmount = royaltyFees[royaltyFeeOwner_];
    return _royaltyAmount;
  }

  function claimRoyaltyFee() external returns(bool) {
    require(getRoyaltyAmount(msg.sender) > 0, "Claim Amount is not enough.");
    payable(msg.sender).transfer(royaltyFees[msg.sender]);
    royaltyFees[msg.sender] = 0;
    return true;
  }

  function claimMarketingFee() public onlyOwner {
    require(marketingFee > 0, "Marketing fee is not enough.");
    payable(msg.sender).transfer(marketingFee);
    marketingFee = 0;
  }
}