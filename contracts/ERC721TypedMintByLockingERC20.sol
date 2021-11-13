// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ERC721Typed.sol";

/**
 * @title Types ERC721 with an erc20 token lock to mint a token.
 * @notice Every type required a specific amount of a specific erc20 to be lock to mint tokens
 * @notice To unlock the erc20 tokens lock after a mint is to call the internal function _unlockMint()
 */
contract ERC721TypedMintByLockingERC20 is ERC721Typed {
    struct ERC20ToLock {
        address addr;
        uint256 amount;
    }

    // Mapping typeId => erc20 address to lock
    mapping(uint256 => ERC20ToLock) public _erc20ToLock;

    /**
     * @dev Constructor
     * @param name_ erc721 token name
     * @param symbol_ erc721 token symbol
     */
    constructor(string memory name_, string memory symbol_)
        ERC721Typed(name_, symbol_)
    {}

    /**
     * @dev Mint an ERC721 typed token from its id
     * @notice This will transferFrom() tokens to the contract
     * @notice Allowance of the erc20 to lock must be done before
     *
     * @param to address of reception
     * @param tokenId id of the token
     * @param data array bytes containing the type id (in first 32 bytes)
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual override {
        super._safeMint(to, tokenId, data);

        ERC20ToLock memory etl = _erc20ToLock[_tokenTypes[tokenId]];
        if (etl.amount != 0) {
            IERC20 erc20 = IERC20(etl.addr);
            // transfer the tokens to this very contract to lock them
            erc20.transferFrom(_msgSender(), address(this), etl.amount);
        }
    }

    /**
     * @dev Mint an ERC721 typed token from a type id
     * @notice This will transferFrom() tokens to the contract
     * @notice Allowance of the erc20 to lock must be done before
     *
     * @param to address of reception
     * @param typeId id of the type
     * @param data extra information
     *
     * @return minted token id
     */
    function _safeMintByType(
        address to,
        uint256 typeId,
        bytes memory data
    ) internal virtual override returns (uint256) {
        // min the token
        uint256 tokenId = super._safeMintByType(to, typeId, data);

        ERC20ToLock memory etl = _erc20ToLock[typeId];
        if (etl.amount != 0) {
            IERC20 erc20 = IERC20(etl.addr);
            // transfer the tokens to this very contract to lock them
            erc20.transferFrom(_msgSender(), address(this), etl.amount);
        }

        // return the token id
        return tokenId;
    }

    /**
     * @dev Mint a batch of ERC721 typed token from a type id
     * @notice This will transferFrom() tokens to the contract
     * @notice Allowance of the erc20 to lock must be done before
     *
     * @param to address of reception
     * @param typeId id of the type
     * @param data extra information
     *
     * @return minted tokens id
     */
    function _safeBatchMintByType(
        address[] calldata to,
        uint256 typeId,
        bytes memory data
    ) internal override returns (uint256[] memory) {
        // mint the tokens
        uint256[] memory tokensMinted = super._safeBatchMintByType(
            to,
            typeId,
            data
        );

        ERC20ToLock memory etl = _erc20ToLock[typeId];
        if (etl.amount != 0) {
            IERC20 erc20 = IERC20(etl.addr);
            // transfer the tokens to this very contract to lock them
            erc20.transferFrom(
                _msgSender(),
                address(this),
                etl.amount * to.length
            );
        }

        return tokensMinted;
    }

    /**
     * @dev Add one type with a range of token id
     *
     * @param id new id type
     * @param from first id for this type
     * @param to last id for this type
     * @param data array bytes containing:
     *                  - the erc20 addres to lock (in first 20 bytes)
     *                  - the amount to lock (in following 32 bytes)
     */
    function _addType(
        uint256 id,
        uint256 from,
        uint256 to,
        bytes calldata data
    ) internal virtual override {
        _erc20ToLock[id] = ERC20ToLock(
            Bytes._bytesToAddress(data, 0),
            Bytes._bytesToUint256(data, 20)
        );
        super._addType(id, from, to, data);
    }

    /**
     * @dev Release the erc20 locked for a token to the token owner
     *
     * @param tokenId id of the token
     */
    function _unlockMint(uint256 tokenId) internal virtual {
        ERC20ToLock memory etl = _erc20ToLock[_tokenTypes[tokenId]];
        if (etl.amount != 0) {
            IERC20 erc20 = IERC20(etl.addr);
            // transfer the tokens from this very contract to the owner of the treasure
            erc20.transfer(ownerOf(tokenId), etl.amount);
        }
    }
}
