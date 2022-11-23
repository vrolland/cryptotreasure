// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBox.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title Box storage
 * @notice Collection storage to handle boxes
 */
abstract contract BoxStorage is ERC165 {
    // ERC20: Mapping from hash(boxId, tokenAddress) to balance
    // ERC721: Mapping from hash(boxId, tokenAddress, tokenId) to 1 (owned) / 0 (not owned)
    // ER1155: Mapping from hash(boxId, tokenAddress, tokenId) to balance
    mapping(bytes32 => uint256) public _indexedTokens;

    // ETH: Mapping from boxId to balance
    mapping(uint256 => uint256) public _indexedEth;

    // Mapping of destroyed boxes
    mapping(uint256 => bool) public destroyedBoxes;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IBox).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
