// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./ERC721TypedMintByLockingERC20.sol";
import "./BoxWithTimeLock.sol";

/**
 * @title CryptoTreasure is a typed ERC721 token able to store other tokens (ETH, ERC20, ERC721 & ERC1155)
 * @notice The types define the erc20 token (and the amount) to lock to mint a crypto treasure
 * @notice The locked erc20 tokens can be release by "destroying" the crypto treasure
 * @notice A destroyed crypto treasure allows to withdraw stored tokens but forbids the storing.
 * @notice The types define the timestamp from when it is allowed for non admin to mint a crypto treasure
 * @notice The types define a number of crypto treasure reserved for the admins
 */
contract CryptoTreasure is
    BoxWithTimeLock,
    ERC721TypedMintByLockingERC20,
    AccessControl
{
    string private baseURI =
        "https://crypto-treasures.com/treasure-metadata/4/";

    // Mapping from box id to restriction
    mapping(uint256 => bool) public _storeRestrictedToOwnerAndApproval;

    // Mapping from type id to blocked destruction duration
    mapping(uint256 => uint256) public _lockedDestructionDuration;

    // Mapping from type id to minting start timestamp
    mapping(uint256 => uint256) public _mintStartTimestamp;

    // Mapping from type id to last id not reserved to admin
    mapping(uint256 => uint256) public _lastIdNotReserved;

    // Mapping from box id to destroy unlock timestamp
    mapping(uint256 => uint256) public _lockedDestructionEnd;

    /**
     * @dev Constructor
     * @notice add msg.sender as DEFAULT_ADMIN_ROLE
     * @param _baseBoxAddress boxBase address
     */
    constructor(address _baseBoxAddress)
        ERC721TypedMintByLockingERC20("CryptoTreasures", "CTR")
        BoxWithTimeLock(_baseBoxAddress)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Mint crypto treasure  from its id
     * @notice This will transferFrom() erc20 token to lock to the contract
     * @notice Allowance of the erc20 to lock must be done before
     * @notice Throw if the minting start is not yet passed
     * @notice Throw if the crypto treasure is reserved to an admin
     *
     * @param to address of reception
     * @param boxId id of the box
     * @param data array bytes containing:
     *                      - the type id (in first 32 bytes)
     *                      - the storing restriction (in following 8 bytes) - 1 only owner can store, 0 everyone can store
     */
    function safeMint(
        address to,
        uint256 boxId,
        bytes memory data
    ) external nonReentrant {
        super._safeMint(to, boxId, data);

        uint256 typeId = _tokenTypes[boxId];
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                boxId <= _lastIdNotReserved[typeId],
            "e22"
        );
        require(_mintStartTimestamp[typeId] <= block.timestamp, "e19");

        _storeRestrictedToOwnerAndApproval[boxId] =
            Bytes._bytesToUint8(data, 32) == 1;

        uint256 destroyLockDuration = _lockedDestructionDuration[typeId];
        if (destroyLockDuration != 0) {
            _lockedDestructionEnd[boxId] =
                block.timestamp +
                destroyLockDuration;
        }
    }

    /**
     * @dev Mint a crypto treasure from a type id
     * @notice This will transferFrom() tokens to the contract
     * @notice Allowance of the erc20 to lock must be done before
     * @notice Throw if the minting start is not yet passed
     * @notice Throw if there is no more crypto treasure available for this type
     *
     * @param to address of reception
     * @param typeId id of the type
     * @param data array bytes containing the storing restriction (in first 8 bytes) - 1 only owner can store, 0 everyone can store
     *
     * @return minted crypto treasure id
     */
    function safeMintByType(
        address to,
        uint256 typeId,
        bytes memory data
    ) external nonReentrant returns (uint256) {
        require(_mintStartTimestamp[typeId] <= block.timestamp, "e19");

        // mint the token
        uint256 tokenId = _safeMintByType(to, typeId, data);
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                tokenId <= _lastIdNotReserved[typeId],
            "e22"
        );

        _storeRestrictedToOwnerAndApproval[tokenId] =
            Bytes._bytesToUint8(data, 0) == 1;

        uint256 destroyLockDuration = _lockedDestructionDuration[typeId];
        if (destroyLockDuration != 0) {
            _lockedDestructionEnd[tokenId] =
                block.timestamp +
                destroyLockDuration;
        }

        // return the token id
        return tokenId;
    }

    /**
     * @dev Mint a batch of crypto treasures from a type id
     * @notice only admins cal execute this function
     * @notice This will transferFrom() tokens to the contract
     * @notice Allowance of the erc20 to lock must be done before
     * @notice Minting can be done before the minting start for everyone
     * @notice Throw if there is no more crypto treasure available for this type
     *
     * @param to addresses of reception
     * @param typeId id of the type
     * @param data array bytes containing the storing restriction (in first 8 bytes) - 1 only owner can store, 0 everyone can store
     *
     * @return tokensMinted minted crypto treasure id list
     */
    function safeBatchMintByType(
        address[] calldata to,
        uint256 typeId,
        bytes memory data
    )
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256[] memory tokensMinted)
    {
        // mint the tokens
        tokensMinted = super._safeBatchMintByType(to, typeId, data);

        uint256 destroyLockDuration = _lockedDestructionDuration[typeId];

        // define the restriction mode
        for (uint256 j = 0; j < to.length; j++) {
            _storeRestrictedToOwnerAndApproval[tokensMinted[j]] =
                Bytes._bytesToUint8(data, 0) == 1;
            if (destroyLockDuration != 0) {
                _lockedDestructionEnd[tokensMinted[j]] =
                    block.timestamp +
                    destroyLockDuration;
            }
        }
    }

    /**
     * @dev lock a crypto treasure until a timestamp
     * @notice Only owner or approved can execute this
     * @notice Throw if the crypto treasure is already locked
     *
     * @param boxId id of the box
     * @param unlockTimestamp unlock timestamp
     */
    function lockBox(uint256 boxId, uint256 unlockTimestamp) external {
        require(_isApprovedOrOwner(_msgSender(), boxId), "e4");
        onlyNotLockedBox(boxId);
        _lockBox(boxId, unlockTimestamp);
    }

    /**
     * @dev Set the restriction mode of the storing
     * @notice Only owner or approved can execute this
     * @notice Throw if the crypto treasure is already locked
     *
     * @param boxId id of the box
     * @param restriction true: only owner can store, false: everyone can store
     */
    function setStoreRestrictionToOwnerAndApproval(
        uint256 boxId,
        bool restriction
    ) external {
        require(_isApprovedOrOwner(_msgSender(), boxId), "e4");
        onlyNotLockedBox(boxId);

        _storeRestrictedToOwnerAndApproval[boxId] = restriction;
    }

    /**
     * @dev Add one type with a range of token id
     * @notice Only admin can execute this function
     * @notice Throw if the number reserved is bigger than the range
     *
     * @param id new id type
     * @param from first id for this type
     * @param to last id for this type
     * @param data array bytes containing:
     *                  - the erc20 addres to lock (in first 20 bytes)
     *                  - the amount to lock (in following 32 bytes)
     *                  - the duration before destroy() is allowed after minting (in following 32 bytes)
     *                  - the duration before mint() is allowed for everyone (in following 32 bytes)
     *                  - the number of tokens reserved to admins (in following 32 bytes)
     */
    function addType(
        uint256 id,
        uint256 from,
        uint256 to,
        bytes calldata data
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _addType(id, from, to, data);
        _lockedDestructionDuration[id] = Bytes._bytesToUint256(data, 52);
        _mintStartTimestamp[id] =
            block.timestamp +
            Bytes._bytesToUint256(data, 84);
        uint256 numberToReserved = Bytes._bytesToUint256(data, 116);

        require(numberToReserved <= to - from + 1, "e21");
        _lastIdNotReserved[id] = to - numberToReserved;
    }

    /**
     * @dev Add a list of types
     * @notice Only admin can execute this function
     *
     * @param ids new ids
     * @param from first id for each type
     * @param to last id for each type
     * @param data array bytes containing: see addType()
     */
    function addTypes(
        uint256[] calldata ids,
        uint256[] calldata from,
        uint256[] calldata to,
        bytes[] calldata data
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < ids.length; i++) {
            addType(ids[i], from[i], to[i], data[i]);
        }
    }

    /**
     * @dev Updates the base URI
     * @notice Only admin can execute this function
     *
     * @param _newBaseURI new base URI
     */
    function updateBaseURI(string calldata _newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Executed before a withdraw
     * @notice Throw if box is locked (from BoxWithTimeLock)
     * @notice Throw if not owner or approved
     *
     * @param boxId id of the box
     */
    function _beforeWithdraw(uint256 boxId) internal override {
        super._beforeWithdraw(boxId);
        // Useless as the balance will be computed in the withdraw
        // require(_exists(boxId), "e15");
        require(_isApprovedOrOwner(_msgSender(), boxId), "e4");
    }

    /**
     * @dev Executed before a store
     * @notice Throw if box is locked (from BoxWithTimeLock)
     * @notice Throw if crypto treasure does not exist
     * @notice Throw if not approved AND if store restriction is true
     * @notice Throw if crypto treasure has been destroyed (from BoxExternal)
     *
     * @param boxId id of the box
     */
    function _beforeStore(uint256 boxId) internal override {
        super._beforeStore(boxId);
        require(_exists(boxId), "e15");
        require(
            !_storeRestrictedToOwnerAndApproval[boxId] ||
                _isApprovedOrOwner(_msgSender(), boxId),
            "e7"
        );
    }

    /**
     * @dev Executed before a destroy
     * @notice Throw if box is locked (from BoxWithTimeLock)
     * @notice Throw if not approved
     * @notice Throw if crypto treasure has been destroyed (from BoxExternal)
     * @notice Throw if before destroy allowed timestamp
     *
     * @param boxId id of the box
     */
    function _beforeDestroy(uint256 boxId) internal override {
        super._beforeDestroy(boxId);
        require(_isApprovedOrOwner(_msgSender(), boxId), "e4");
        require(_isDestructionUnlocked(boxId), "e17");
    }

    /**
     * @dev Executed after a destroy
     * @notice Release the erc20 locked to the owner
     *
     * @param boxId id of the box
     */
    function _afterDestroy(uint256 boxId) internal override {
        _unlockMint(boxId);
    }

    /**
     * @dev Check if the crypto treasure passed the destroy lock
     *
     * @param boxId id of the box
     * @return true if the crypto treasure passed the destroy lock, false otherwise
     */
    function _isDestructionUnlocked(uint256 boxId)
        internal
        view
        returns (bool)
    {
        return _lockedDestructionEnd[boxId] <= block.timestamp;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Base URI for computing {tokenURI}
     * @return string baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
