// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Box storage
 * @notice Collection storage to handle boxes
 */
abstract contract BoxStorage {
    // ERC20: Mapping from hash(boxId, tokenAddress) to balance
    // ERC721: Mapping from hash(boxId, tokenAddress, tokenId) to 1 (owned) / 0 (not owned)
    // ER1155: Mapping from hash(boxId, tokenAddress, tokenId) to balance
    mapping(bytes32 => uint256) public _indexedTokens;

    // ETH: Mapping from boxId to balance
    mapping(uint256 => uint256) public _indexedEth;

    // Mapping of destroyed boxes
    mapping(uint256 => bool) public destroyedBoxes;
}
