// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./IBox.sol";
import "./BoxStorage.sol";

/**
 * @title Box with public functions to store, withdraw, transferBetweenBoxes and destroy
 * @notice This contract delegateCall the contract BoxBase
 */
abstract contract BoxProxy is IBox, BoxStorage, ReentrancyGuard {
    /// contract boxBase to delegateCall
    address public boxBase;

    /**
     * @dev Constructor
     * @param _boxBaseAddress boxBase address
     */
    constructor(address _boxBaseAddress) {
        boxBase = _boxBaseAddress;
    }

    /**
     * @dev Store tokens to a box
     * @notice allowance for the tokens must be done to this contract
     * @notice _beforeStore(boxId) is called before actually storing
     *
     * @param boxId id of the box
     * @param erc20s list of erc20 to store
     * @param erc721s list of erc721 to store
     * @param erc1155s list of erc1155 to store
     */
    function store(
        uint256 boxId,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s
    ) external payable override nonReentrant {
        _beforeStore(boxId);

        (bool status, ) = boxBase.delegatecall(
            abi.encodeWithSignature(
                "store(uint256,(address,uint256)[],(address,uint256[])[],(address,uint256[],uint256[])[])",
                boxId,
                erc20s,
                erc721s,
                erc1155s
            )
        );
        require(status, "e23");
    }

    /**
     * @dev Withdraw tokens from a box to an address
     * @notice _beforeWithdraw(boxId) is called before actually withdrawing
     *
     * @param boxId id of the box
     * @param ethAmount amount of eth to withdraw
     * @param erc20s list of erc20 to withdraw
     * @param erc721s list of erc721 to withdraw
     * @param erc1155s list of erc1155 to withdraw
     * @param to address of reception
     */
    function withdraw(
        uint256 boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s,
        address payable to
    ) external override nonReentrant {
        _beforeWithdraw(boxId);

        (bool status, ) = boxBase.delegatecall(
            abi.encodeWithSignature(
                "withdraw(uint256,uint256,(address,uint256)[],(address,uint256[])[],(address,uint256[],uint256[])[],address)",
                boxId,
                ethAmount,
                erc20s,
                erc721s,
                erc1155s,
                to
            )
        );
        require(status, "e23");
    }

    /**
     * @dev Transfer tokens from a box to another
     * @notice _beforeStore(destBoxId) and _beforeWithdraw(srcBoxId) are called before actually transfering
     *
     * @param srcBoxId source box
     * @param destBoxId destination box
     * @param ethAmount amount of eth to transfer
     * @param erc20s list of erc20 to transfer
     * @param erc721s list of erc721 to transfer
     * @param erc1155s list of erc1155 to transfer
     */
    function transferBetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s
    ) external override nonReentrant {
        _beforeWithdraw(srcBoxId);
        _beforeStore(destBoxId);

        (bool status, ) = boxBase.delegatecall(
            abi.encodeWithSignature(
                "transferBetweenBoxes(uint256,uint256,uint256,(address,uint256)[],(address,uint256[])[],(address,uint256[],uint256[])[])",
                srcBoxId,
                destBoxId,
                ethAmount,
                erc20s,
                erc721s,
                erc1155s
            )
        );
        require(status, "e23");
    }

    /**
     * @dev Destroy a box
     * @notice _beforeDestroy(boxId) is called before actually destroying
     *
     * @param boxId id of the box
     * @param ethAmount amount of eth to withdraw
     * @param erc20ToWithdraw list of erc20 to withdraw
     * @param erc721ToWithdraw list of erc721 to withdraw
     * @param erc1155ToWithdraw list of erc1155 to withdraw
     * @param to address of reception
     */
    function destroy(
        uint256 boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20ToWithdraw,
        ERC721TokenInfos[] calldata erc721ToWithdraw,
        ERC1155TokenInfos[] calldata erc1155ToWithdraw,
        address payable to
    ) external override nonReentrant {
        _beforeDestroy(boxId);

        (bool status, ) = boxBase.delegatecall(
            abi.encodeWithSignature(
                "destroy(uint256,uint256,(address,uint256)[],(address,uint256[])[],(address,uint256[],uint256[])[],address)",
                boxId,
                ethAmount,
                erc20ToWithdraw,
                erc721ToWithdraw,
                erc1155ToWithdraw,
                to
            )
        );
        require(status, "e23");

        _afterDestroy(boxId);
    }

    /**
     * @dev Get the balance of ethers in a box
     *
     * @param boxId id of the box
     *
     * @return balance
     */
    function EthBalanceOf(uint256 boxId)
        public
        view
        override
        returns (uint256 balance)
    {
        return _indexedEth[boxId];
    }

    /**
     * @dev Get the balance of an erc20 token in a box
     *
     * @param boxId id of the box
     * @param tokenAddress erc20 token address
     *
     * @return balance
     */
    function erc20BalanceOf(uint256 boxId, address tokenAddress)
        public
        view
        override
        returns (uint256 balance)
    {
        bytes32 index = keccak256(abi.encodePacked(boxId, tokenAddress));
        return _indexedTokens[index];
    }

    /**
     * @dev Get the balance of an erc1155 token in a box
     *
     * @param boxId id of the box
     * @param tokenAddress erc1155 token address
     * @param tokenId token id
     *
     * @return balance
     */
    function erc1155BalanceOf(
        uint256 boxId,
        address tokenAddress,
        uint256 tokenId
    ) public view override returns (uint256 balance) {
        bytes32 index = keccak256(
            abi.encodePacked(boxId, tokenAddress, tokenId)
        );
        return _indexedTokens[index];
    }

    /**
     * @dev Check if an ERC721 token is in a box
     *
     * @param boxId id of the box
     * @param tokenAddress erc1155 token address
     * @param tokenId token id
     *
     * @return present 1 if present, 0 otherwise
     */
    function erc721BalanceOf(
        uint256 boxId,
        address tokenAddress,
        uint256 tokenId
    ) public view override returns (uint256 present) {
        bytes32 index = keccak256(
            abi.encodePacked(boxId, tokenAddress, tokenId)
        );
        return _indexedTokens[index];
    }

    /**
     * @dev Handles the receipt of ERC1155 token types
     * @notice will always revert
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert();
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types
     * @notice Authorized only if the transfer is operated by this contract
     */
    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public view override returns (bytes4) {
        require(operator == address(this), "e2");

        // reception accepted
        return 0xbc197c81;
    }

    /**
     * @dev Handles the receipt of a multiple ERC721 token types
     * @notice Authorized only if the transfer is operated by this contract
     */
    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) public view override returns (bytes4) {
        require(operator == address(this), "e2");

        // reception accepted
        return 0x150b7a02;
    }

    /**
     * @dev Throw if box is destroyed
     *
     * @param boxId id of the box
     */
    function onlyNotDestroyedBox(uint256 boxId) internal view {
        require(!destroyedBoxes[boxId], "e3");
    }

    /**
     * @dev executed before a withdraw
     *
     * @param boxId id of the box
     */
    function _beforeWithdraw(uint256 boxId) internal virtual {}

    /**
     * @dev executed before a store
     * @notice forbid store if crypto treasure has been destroyed
     *
     * @param boxId id of the box
     */
    function _beforeStore(uint256 boxId) internal virtual {
        onlyNotDestroyedBox(boxId);
    }

    /**
     * @dev executed before a destroy
     * @notice forbid destroy if crypto treasure has been destroyed
     *
     * @param boxId id of the box
     */
    function _beforeDestroy(uint256 boxId) internal virtual {
        onlyNotDestroyedBox(boxId);
    }

    /**
     * @dev executed after a destroy
     *
     * @param boxId id of the box
     */
    function _afterDestroy(uint256 boxId) internal virtual {}
}
