// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Box events and storage
 * @notice Collection of events and storage to handle boxes
 */
interface IBox is IERC165, IERC721Receiver, IERC1155Receiver {
    // ERC721 token information {address and token ids} used for function parameters
    struct ERC721TokenInfos {
        address addr;
        uint256[] ids;
    }
    // ERC20 token information {address and amount} used for function parameters
    struct ERC20TokenInfos {
        address addr;
        uint256 amount;
    }
    // ERC1155 token information {address, token ids and token amounts} used for function parameters
    struct ERC1155TokenInfos {
        address addr;
        uint256[] ids;
        uint256[] amounts;
    }

    event Store(
        uint256 indexed boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] erc20s,
        ERC721TokenInfos[] erc721s,
        ERC1155TokenInfos[] erc1155s
    );

    event Withdraw(
        uint256 indexed boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] erc20s,
        ERC721TokenInfos[] erc721s,
        ERC1155TokenInfos[] erc1155s,
        address to
    );

    event TransferBetweenBoxes(
        uint256 indexed srcBoxId,
        uint256 indexed destBoxId,
        uint256 ethAmount,
        ERC20TokenInfos[] erc20s,
        ERC721TokenInfos[] erc721s,
        ERC1155TokenInfos[] erc1155s
    );

    event Destroyed(uint256 indexed boxId);

    function store(
        uint256 boxId,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s
    ) external payable;

    function withdraw(
        uint256 boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s,
        address payable to
    ) external;

    function transferBetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s
    ) external;

    function destroy(
        uint256 boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20ToWithdraw,
        ERC721TokenInfos[] calldata erc721ToWithdraw,
        ERC1155TokenInfos[] calldata erc1155ToWithdraw,
        address payable to
    ) external;

    function EthBalanceOf(uint256 _boxId) external view returns (uint256);

    function erc20BalanceOf(uint256 _boxId, address _tokenAddress)
        external
        view
        returns (uint256);

    function erc721BalanceOf(
        uint256 _boxId,
        address _tokenAddress,
        uint256 _tokenId
    ) external view returns (uint256);

    function erc1155BalanceOf(
        uint256 _boxId,
        address _tokenAddress,
        uint256 _tokenId
    ) external view returns (uint256);

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override returns (bytes4);

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override returns (bytes4);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4);
}
