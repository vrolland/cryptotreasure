// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./Bytes.sol";

/**
 * @title typed ERC721 
 * @notice every token has a type with optional data
 */
abstract contract ERC721Typed is ERC721 {
    // Structure to defined a type
    struct Type {
        // First id for this token type
        uint256 from;
        // Last id for this token type
        uint256 to;
        bytes data;
        uint256 nextToMint;
    }

    // Mapping types information
    mapping(uint256 => Type) public _types;

    // Mapping token id => type id
    mapping(uint256 => uint256) public _tokenTypes;

    event NewType(uint256 id, uint256 from, uint256 to, bytes data);

    /**
     * @dev Constructor
     * @param name_ erc721 token name
     * @param symbol_ erc721 token symbol
     */
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /**
     * @dev Mint an ERC721 typed token from its id
     * @notice throw if type does not exist
     * @notice throw if tokenId is not in the range of the type (between from and to)
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
        uint256 typeId = Bytes._bytesToUint256(data, 0);
        require(typeId != 0, "e9");

        Type memory requestedType = _types[typeId];
        require(requestedType.to != 0, "e10");
        require(tokenId >= requestedType.from, "e11");
        require(tokenId <= requestedType.to, "e12");
        _tokenTypes[tokenId] = typeId;

        super._safeMint(to, tokenId, data);
    }

    /**
     * @dev Mint an ERC721 typed token from a type id
     * @notice throw if type does not exist
     * @notice throw if all the tokens are already minted for this type
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
    ) internal virtual returns (uint256) {
        Type memory requestedType = _types[typeId];
        require(requestedType.to != 0, "e10");

        uint256 tokenId = requestedType.nextToMint;
        // skip the token already minted
        while (_exists(tokenId)) {
            tokenId++;
            // Revert if all tokens have been minted for the allocated type range
            require(tokenId <= requestedType.to, "e18");
        }

        _tokenTypes[tokenId] = typeId;

        // mint the token
        super._safeMint(to, tokenId, data);

        // increment the next to mint
        requestedType.nextToMint = tokenId + 1;

        return tokenId;
    }

    /**
     * @dev Mint a batch of ERC721 typed token from a type id
     * @notice throw if type does not exist
     * @notice throw if there is not enough tokens to minted for this type
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
    ) internal virtual returns (uint256[] memory) {
        Type memory requestedType = _types[typeId];
        require(requestedType.to != 0, "e10");

        uint256[] memory tokensMinted = new uint256[](to.length);
        uint256 tokenId = requestedType.nextToMint;
        for (uint256 j = 0; j < to.length; j++) {
            // skip the token already minted
            while (_exists(tokenId)) {
                tokenId++;
                // Revert if all tokens have been minted for the allocated type range
                require(tokenId <= requestedType.to, "e18");
            }

            // mint the token
            super._safeMint(to[j], tokenId, data);
            tokensMinted[j] = tokenId;

            _tokenTypes[tokenId] = typeId;

            // increment the next to mint
            requestedType.nextToMint = tokenId + 1;
        }

        return tokensMinted;
    }

    /**
     * @dev Add one type with a range of token id
     * @notice throw if type id already exist
     * @notice throw if to is lower than from
     *
     * @param id new id type
     * @param from first id for this type
     * @param to last id for this type
     * @param data extra information
     */
    function _addType(
        uint256 id,
        uint256 from,
        uint256 to,
        bytes calldata data
    ) internal virtual {
        require(_types[id].to == 0, "e13");
        require(from < to, "e14");
        _types[id] = Type(from, to, data, from);
        emit NewType(id, from, to, data);
    }

    /**
     * @dev Add list of types
     * @notice throw if a type id already exist
     * @notice throw if a to is lower than a from
     *
     * @param ids new ids type
     * @param from first ids for this type
     * @param to last ids for this type
     * @param data extra information
     */
    function _addTypes(
        uint256[] calldata ids,
        uint256[] calldata from,
        uint256[] calldata to,
        bytes[] calldata data
    ) internal virtual {
        for (uint256 i = 0; i < ids.length; i++) {
            _addType(ids[i], from[i], to[i], data[i]);
        }
    }
}
