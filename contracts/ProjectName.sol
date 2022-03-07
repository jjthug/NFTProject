// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./Address.sol";
import "./ECDSA.sol";
import "./SafeCast.sol";
import "./ERC721.sol";
import "./Treasury.sol";
import "./ERC2981.sol";

//TODO Change
contract ProjectName is Ownable, ERC721, ERC2981, Treasury {
  using Address for address;
  using SafeCast for uint256;
  using ECDSA for bytes32;
  using Strings for uint256;

  // EVENTS ****************************************************
  event StartingIndexSet(uint256 _value);
  event DutchAuctionConfigUpdated();
  event PresaleConfigUpdated();
  event ProvenanceHashUpdated(bytes32 _hash);
  event WhitelistSignerUpdated(address _signer);
  event baseURISet(string _uri);
  event DummyURIUpdated(string _uri);
  event NFTRevealTimeUpdated(uint256 NFTRevealTime);

  // MEMBERS ****************************************************

  struct DutchAuctionConfig {
    uint32 startTime;
    uint32 stepInterval;
    uint256 startPrice;
    uint256 bottomPrice;
    uint256 priceStep;
  }

  struct PresaleConfig {
    uint32 startTime;
    uint32 endTime;
    uint32 supplyLimit;
    uint256 mintPrice;
  }

  PresaleConfig public presaleConfig;
  DutchAuctionConfig public dutchAuctionConfig;

  
  uint256 public immutable MAX_OWNER_RESERVE;
  //TODO change name
  uint256 public immutable ProjectName_SUPPLY;

  // Number of currently supplied tokens
  uint256 public totalSupply = 0;
  // Number of currently minted tokens
  uint256 public presaleMintedTotal;
  uint256 public randomizedStartIndex;
  uint256 public NFTRevealTime;

  string public dummyURI;
  string public baseURI;

  address public whitelistSigner;

  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) public _ownedTokens;
  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) public _ownedTokensIndex;
  mapping(address => uint256) public presaleMinted;
  mapping(address => uint256) public presaleMintedFree;
  
  bytes32 public PROVENANCE_HASH;
  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private constant PRESALE_TYPEHASH =
    keccak256("presale(address buyer,uint256 limit)");

  bytes32 private constant FREEMINT_TYPEHASH =
    keccak256("freeMint(address buyer,uint256 limit)");

  //TODO change
  address[] private mintPayees = [
    0xc0A0aEa4f8457Caa8C47ED5B5DA410E40EFCbf3c
  ];

  uint256[] private mintShares = [100];

  Treasury public royaltyRecipient;

  // CONSTRUCTOR **************************************************

  constructor(string memory initialDummyURI, 
  bytes32 provenanceHash, 
  address whitelistSignerAddress, 
  uint256 _MAX_OWNER_RESERVE,
  //TODO change name
  uint256 _ProjectName_SUPPLY
  )
    //TODO change name
    ERC721("ProjectName", "ProjectSymbol")
    Treasury(mintPayees, mintShares)
    {
    //Sets the owner's reserved token supply
    MAX_OWNER_RESERVE = _MAX_OWNER_RESERVE;
    //Sets the max supply
    //TODO Change name
    ProjectName_SUPPLY = _ProjectName_SUPPLY;

    dummyURI = initialDummyURI;

    NFTRevealTime = 1646337600; // 03 March 8pm GMT

    PROVENANCE_HASH = provenanceHash;
    emit ProvenanceHashUpdated(provenanceHash);

    whitelistSigner = whitelistSignerAddress;
    emit WhitelistSignerUpdated(whitelistSignerAddress);
    
    //TODO change
    presaleConfig = PresaleConfig({
      startTime: 1656164800, // TODO date time
      endTime: 1656251199, // TODO date time
      mintPrice: 0.1 ether,
      supplyLimit: 5000
    });

    dutchAuctionConfig = DutchAuctionConfig({
      startTime: 1656251200, // TODO date time
      stepInterval: 300, // 5 minutes
      startPrice: 1 ether,
      bottomPrice: 0.1 ether,
      priceStep: 0.001 ether
    });

    address[] memory royaltyPayees = new address[](1);

    //TODO change
    royaltyPayees[0] = 0xc0A0aEa4f8457Caa8C47ED5B5DA410E40EFCbf3c;

    uint256[] memory royaltyShares = new uint256[](1);
    royaltyShares[0] = 100;
    
    royaltyRecipient = new Treasury(royaltyPayees, royaltyShares);

    _setRoyalties(address(royaltyRecipient), 1000); // 10% royalties

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        //TODO CHANGE
        keccak256(bytes("ProjectName")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  // PUBLIC METHODS ****************************************************
  
  /// @notice Allows users to buy during presale, only whitelisted addresses may call this function.
  ///         Whitelisting is enforced by requiring a signature from the whitelistSigner address
  /// @dev Whitelist signing is performed off chain, via the ProjectName website backend
  /// @param signature signed data authenticating the validity of this transaction
  /// @param numberOfTokens number of NFTs to buy
  /// @param approvedLimit the total number of NFTs this address is permitted to buy during presale, this number is also encoded in the signature
  function buyPresale(
    bytes calldata signature,
    uint256 numberOfTokens,
    uint256 approvedLimit
  ) external payable{
    
    require(numberOfTokens > 0, "Should mint atleast 1 NFT");
    // Checking total limit
    require((totalSupply + numberOfTokens) <= ProjectName_SUPPLY, "Total Supply limit reached");

    PresaleConfig memory _config = presaleConfig;

    require(block.timestamp >= _config.startTime && block.timestamp < _config.endTime, "Presale not active");
    require(whitelistSigner != address(0), "Whitelist signer not set");
    require((presaleMintedTotal + numberOfTokens) <= _config.supplyLimit, "Presale Supply limit reached");
    
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PRESALE_TYPEHASH, msg.sender, approvedLimit))
      )
    );
    
    address signer = digest.recover(signature);
    require(signer != address(0) && signer == whitelistSigner,"Invalid signature");

    require((presaleMinted[msg.sender] + numberOfTokens) <= approvedLimit, "Mint limit exceeded");
        require(msg.value == (_config.mintPrice * numberOfTokens), "Incorrect ETH provided");

    presaleMinted[msg.sender] = presaleMinted[msg.sender] + numberOfTokens;

    mint(msg.sender, numberOfTokens);
    presaleMintedTotal += numberOfTokens;
  }

  /// @notice Allows users to buy during presale for free, only whitelisted addresses may call this function.
  ///         Whitelisting is enforced by requiring a signature from the whitelistSigner address
  /// @dev Whitelist signing is performed off chain, via the ProjectName website backend
  /// @param signature signed data authenticating the validity of this transaction
  /// @param numberOfTokens number of NFTs to buy
  /// @param approvedLimit the total number of NFTs this address is permitted to buy during presale, this number is also encoded in the signature
  function buyPresaleFree(
    bytes calldata signature,
    uint256 numberOfTokens,
    uint256 approvedLimit
  ) external payable{

    require(numberOfTokens > 0, "Should mint atleast 1 NFT");
    require((totalSupply + numberOfTokens) <= ProjectName_SUPPLY, "Total Supply limit reached");

    PresaleConfig memory _config = presaleConfig;

    require(block.timestamp >= _config.startTime && block.timestamp < _config.endTime,"Presale not active");
    require(whitelistSigner != address(0), "Whitelist signer has not been set");
    require((presaleMintedTotal + numberOfTokens) <= _config.supplyLimit, "Presale Supply limit reached");
    
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(FREEMINT_TYPEHASH, msg.sender, approvedLimit))
      )
    );

    address signer = digest.recover(signature);
    require(signer != address(0) && signer == whitelistSigner, "Invalid signature");

    require((presaleMintedFree[msg.sender] + numberOfTokens) <= approvedLimit,"Mint limit exceeded");
    presaleMintedFree[msg.sender] = presaleMintedFree[msg.sender] + numberOfTokens;

    mint(msg.sender, numberOfTokens);
    presaleMintedTotal += numberOfTokens;
  }


  /// @notice Allows users to buy during public sale, pricing follows a dutch auction format and a constant set price after the dutch auction ends
  /// @dev Preventing contract buys has some downsides, but it seems to be what the NFT market generally wants as a bot mitigation measure
  /// @param numberOfTokens the number of NFTs to buy
  function buyPublic(uint256 numberOfTokens) external payable {

    require(numberOfTokens > 0, "Should mint atleast 1 NFT");
    require(totalSupply + numberOfTokens <= ProjectName_SUPPLY, "Total supply maxed out");
    require(block.timestamp >= dutchAuctionConfig.startTime, "Public sale not active");

    // disallow contracts from buying
    require(
      (!msg.sender.isContract() && msg.sender == tx.origin),
      "Contract buys not allowed"
    );

    uint256 mintPrice = getCurrentAuctionPrice() * numberOfTokens;
    require(msg.value >= mintPrice, "Insufficient payment");

    // refund if customer paid more than the cost to mint
    if (msg.value > mintPrice) {
      Address.sendValue(payable(msg.sender), msg.value - mintPrice);
    }

    mint(msg.sender, numberOfTokens);
  }

  /// @notice Gets an array of tokenIds owned by a wallet
  /// @param wallet wallet address to query contents for
  /// @return an array of tokenIds owned by wallett
  function tokensOwnedBy(address wallet)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      ownedTokenIds[i] = _ownedTokens[wallet][i];
    }

    return ownedTokenIds;
  }

  /// @inheritdoc ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  //Returns the number of remaining tokens available for mint
  function totalLeftToMint() view external returns(uint256){
    return ProjectName_SUPPLY - totalSupply;
  }

  /**
  Batch transfers NFTs to users
  @param to : Array of to addresses
  @param tokenIds : Array of corresponding token ids
  @return true if batch transfer succeeds
  */
  function batchTransfer(address[] memory to, uint256[] memory tokenIds) external returns(bool){

    require(to.length > 0, "Minimum one entry");
    require(to.length == tokenIds.length, "Unequal length of to addresses and number of tokens");
    require(tokenIds.length <= balanceOf(msg.sender),"Not enough tokens owned");
    
    for(uint256 i = 0; i < to.length; i++){
      safeTransferFrom(
        msg.sender,
        to[i],
        tokenIds[i]
    );
    }
    return true;
  }

  // OWNER METHODS *********************************************************

  /// @notice Allows the contract owner to reserve NFTs for team members or promotional purposes
  /// @dev This should be called before presale or public sales start, as only the first MAX_OWNER_RESERVE tokens can be reserved
  /// @param to address for the reserved NFTs to be minted to
  /// @param numberOfTokens number of NFTs to reserve
  function reserve(address[] memory to, uint256[] memory numberOfTokens) external onlyOwner {
    require(to.length > 0, "Minimum one entry");
    require(to.length == numberOfTokens.length, "Unequal length of to addresses and number of tokens");
    
    uint256 totalNumber;
    uint256 i;

    for(i = 0; i < numberOfTokens.length; i++){
      totalNumber += numberOfTokens[i];
    }

    require((totalSupply + totalNumber) <= MAX_OWNER_RESERVE,"Exceeds owner reserve limit");
    
    for(i = 0; i < to.length; i++){
      mint(to[i], numberOfTokens[i]);
    }
  }

  /// @notice Allows the contract owner to update config for the public dutch auction
  function configureDutchAuction(
    uint256 startTime,
    uint256 stepInterval,
    uint256 startPrice,
    uint256 bottomPrice,
    uint256 priceStep
  ) external onlyOwner {
    uint32 _startTime = startTime.toUint32();
    uint32 _stepInterval = stepInterval.toUint32();
    
    require(0 < bottomPrice, "Invalid bottom price");
    require(0 < stepInterval, "0 step interval");
    require(bottomPrice < startPrice, "Start price must be greater than bottom price");
    require(0 < priceStep && priceStep < startPrice, "Invalid price step");

    dutchAuctionConfig.startTime = _startTime;
    dutchAuctionConfig.stepInterval = _stepInterval;
    dutchAuctionConfig.startPrice = startPrice;
    dutchAuctionConfig.bottomPrice = bottomPrice;
    dutchAuctionConfig.priceStep = priceStep;

    emit DutchAuctionConfigUpdated();
  }

  
  /// @notice Allows the contract owner to update start and end time for the presale
  function configurePresale(uint256 startTime, uint256 endTime, uint256 mintPrice, uint256 supplyLimit)
    external
    onlyOwner
  {
    uint32 _startTime = startTime.toUint32();
    uint32 _endTime = endTime.toUint32();
    uint32 _supplyLimit = supplyLimit.toUint32();

    require(0 < _startTime, "Invalid time");
    require(_endTime > _startTime, "Invalid time");
    require(mintPrice > 0, "Invalid mint price");
    require(supplyLimit <= ProjectName_SUPPLY, "Invalid supply limit");

    presaleConfig.startTime = _startTime;
    presaleConfig.endTime = _endTime;
    presaleConfig.mintPrice = mintPrice;
    presaleConfig.supplyLimit = _supplyLimit;

    emit PresaleConfigUpdated();
  }

  /// @notice Gets the current price for the duction auction, based on current block timestamp, will return a set price value after dutch auction ends
  /// @dev Dutch auction parameters configured via dutchAuctionConfig
  /// @return currentPrice Current mint price per NFT
  function getCurrentAuctionPrice() public view returns (uint256 currentPrice) {
    DutchAuctionConfig memory _config = dutchAuctionConfig;

    uint256 timestamp = block.timestamp;
    
    if (timestamp < _config.startTime) {
      currentPrice = _config.startPrice;
    }
    else {
      uint256 elapsedIntervals = (timestamp - _config.startTime) /_config.stepInterval;

      if(_config.startPrice > (elapsedIntervals * _config.priceStep) && 
      ((_config.startPrice - (elapsedIntervals * _config.priceStep)) >= _config.bottomPrice))
        currentPrice =_config.startPrice - (elapsedIntervals * _config.priceStep);
      else{
        currentPrice = _config.bottomPrice;
      }
    }
    return currentPrice;
  }

  function setNFTRevealTime(uint256 newNFTRevealTime) external onlyOwner{
    NFTRevealTime = newNFTRevealTime;
    emit NFTRevealTimeUpdated(newNFTRevealTime);
  }

  /// @notice Allows the owner to roll a pseudo-random number once, which will be used as the starting index for the token metadata.
  ///         This is used to prove randomness and fairness in the metadata distribution, in conjunction with the PROVENANCE_HASH
  /// @dev The starting index can only be set once, and only if the PROVENANCE_HASH has been set
  function rollStartIndex() external onlyOwner {
    require(PROVENANCE_HASH != 0, "Provenance hash not set");
    require(randomizedStartIndex == 0, "Index already set");
    require(block.timestamp >= NFTRevealTime, "NFT Reveal time not reached yet");

    uint256 number = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          block.coinbase,
          block.difficulty,
          block.timestamp
        )
      )
    );

    randomizedStartIndex = (number % ProjectName_SUPPLY) + 1;

    emit StartingIndexSet(randomizedStartIndex);
  }
  
  /**
  @param provenanceHash : The new provenance hash
  Sets the provenance hash, if the randomizedStartIndex hasn't been rolled yet
  */
  function setProvenance(bytes32 provenanceHash) external onlyOwner {
    require(randomizedStartIndex == 0, "Starting index already set");

    emit ProvenanceHashUpdated(provenanceHash);
    PROVENANCE_HASH = provenanceHash;
  }

  // Calculated the provenance hash of the base URI provided
  function calculateProvenanceHash(string calldata _baseURI) public pure returns(bytes32) {
    return keccak256(abi.encode(_baseURI));
  }

  /**
  @param _baseURI : The base URI string
  @return Boolean value true/false if the provenance hash of the base uri matches with the set PROVENANCE_HASH
  Verifies whether the input base URI's hash matches with the set PROVENANCE_HASH
  */
  function verifyProvenanceHash(string calldata _baseURI) view public returns(bool) {
    require(calculateProvenanceHash(_baseURI) == PROVENANCE_HASH, "Doesn't match with the provenance hash");
    return true;
  }

  /**
  @param _baseURI : The base URI string
  @return Boolean value true/false if base URI was successfully set
  Verifies whether the input base URI's hash matches with the set PROVENANCE_HASH and sets the base URI
  */
  function setBaseURI(string calldata _baseURI) external onlyOwner returns(bool) {
    require(randomizedStartIndex != 0, "Please roll the start index first");
    require(verifyProvenanceHash(_baseURI), "Verification of provenance hash failed");
    baseURI = _baseURI;
    emit baseURISet(_baseURI);
    return true;
  }

  /**
  @param theDummyURI : The dummy base URI string
  Sets the dummy base URI. This URI will be used by all tokens until the startIndex has been randomized and base URI is set
  */
  function setDummyURL(string memory theDummyURI) external onlyOwner{
    dummyURI = theDummyURI;
    emit DummyURIUpdated(theDummyURI);
  }

  /**
  @param tokenId : The token id
  Fetches the token URI of token id = tokenId. It will return dummy URI if the base URI has not been set.
  */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, (((tokenId + randomizedStartIndex) % ProjectName_SUPPLY) + 1).toString(), ".json") ) : dummyURI;
  }

  /**
  @param newWhitelistSigner : The token id
  Sets a new whitelist signer address. This address will be used to verify signatures in buyPresale and buyPresaleFree.
  */
  function setWhitelistSigner(address newWhitelistSigner) external onlyOwner {
    emit WhitelistSignerUpdated(newWhitelistSigner);
    whitelistSigner = newWhitelistSigner;
  }

  // PRIVATE/INTERNAL METHODS ****************************************************

  function mint(address to, uint256 numberOfTokens) private {
    uint256 newId = totalSupply;

    for (uint256 i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(to, newId);
    }
    totalSupply = newId;
  }

  // ************************************************************************************************************************
  // The following methods are borrowed from OpenZeppelin's ERC721Enumerable contract, to make it easier to query a wallet's
  // contents without incurring the extra storage gas costs of the full ERC721Enumerable extension
  // ************************************************************************************************************************

  /**
   * @dev Private function to add a token to ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
    private
  {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from != address(0)) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to != address(0)) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }
}