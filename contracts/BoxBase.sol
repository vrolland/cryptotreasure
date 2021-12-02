// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IBox.sol";
import "./BoxStorage.sol";
import "./OnlyDelegateCall.sol";

/**
 * @title Box with functions to store, withdraw, transferBetweenBoxes and destroy
 * @notice This contract is meant to be delegateCalled by a contract inheriting from BoxExternal
 * @notice This contract forbid reception of ERC1155 and ERC721
 * @notice Don't send ERC20 to this contract !
 */
contract BoxBase is IBox, BoxStorage, Context, OnlyDelegateCall {
    /**
     * @dev Store tokens inside a box
     * @notice allowance for the tokens must be done to the BoxExternal contract
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
    ) external payable override onlyDelegateCall {
        // store ETH tokens
        _storeEth(boxId, msg.value);

        // store ERC721 tokens
        for (uint256 j = 0; j < erc721s.length; j++) {
            _storeErc721(boxId, erc721s[j].addr, erc721s[j].ids);
        }

        // store ERC20 tokens
        for (uint256 j = 0; j < erc20s.length; j++) {
            _storeErc20(boxId, erc20s[j].addr, erc20s[j].amount);
        }

        // store ERC1155 tokens
        for (uint256 j = 0; j < erc1155s.length; j++) {
            _storeErc1155(
                boxId,
                erc1155s[j].addr,
                erc1155s[j].ids,
                erc1155s[j].amounts
            );
        }

        emit Store(boxId, msg.value, erc20s, erc721s, erc1155s);
    }

    /**
     * @dev Withdraw tokens from a box to an address
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
    ) external override onlyDelegateCall {
        // withdraw ETH tokens
        _withdrawEth(boxId, ethAmount, to);

        // withdraw ERC721 tokens
        for (uint256 j = 0; j < erc721s.length; j++) {
            _withdrawERC721(boxId, erc721s[j].addr, erc721s[j].ids, to);
        }

        // withdraw ERC20 tokens
        for (uint256 j = 0; j < erc20s.length; j++) {
            _withdrawERC20(boxId, erc20s[j].addr, erc20s[j].amount, to);
        }

        // withdraw ERC1155 tokens
        for (uint256 j = 0; j < erc1155s.length; j++) {
            _withdrawERC1155(
                boxId,
                erc1155s[j].addr,
                erc1155s[j].ids,
                erc1155s[j].amounts,
                to
            );
        }

        emit Withdraw(boxId, ethAmount, erc20s, erc721s, erc1155s, to);
    }

    /**
     * @dev Transfer tokens from a box to another
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
    ) external override onlyDelegateCall {
        // transferBetweenBoxes Ethers
        _transferEthBetweenBoxes(srcBoxId, destBoxId, ethAmount);

        // transferBetweenBoxes ERC721 tokens
        _transferErc721BetweenBoxes(srcBoxId, destBoxId, erc721s);

        // transferBetweenBoxes ERC20 tokens
        _transferErc20BetweenBoxes(srcBoxId, destBoxId, erc20s);

        // transferBetweenBoxes ERC1155 tokens
        _transferErc1155BetweenBoxes(srcBoxId, destBoxId, erc1155s);

        emit TransferBetweenBoxes(
            srcBoxId,
            destBoxId,
            ethAmount,
            erc20s,
            erc721s,
            erc1155s
        );
    }

    /**
     * @dev Destroy a box
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
    ) external override onlyDelegateCall {
        // destroy the box
        destroyedBoxes[boxId] = true;
        emit Destroyed(boxId);

        // withdraw ETH tokens
        _withdrawEth(boxId, ethAmount, to);

        // withdraw ERC721 tokens
        for (uint256 j = 0; j < erc721ToWithdraw.length; j++) {
            _withdrawERC721(
                boxId,
                erc721ToWithdraw[j].addr,
                erc721ToWithdraw[j].ids,
                to
            );
        }

        // withdraw ERC20 tokens
        for (uint256 j = 0; j < erc20ToWithdraw.length; j++) {
            _withdrawERC20(
                boxId,
                erc20ToWithdraw[j].addr,
                erc20ToWithdraw[j].amount,
                to
            );
        }

        // withdraw ERC1155 tokens
        for (uint256 j = 0; j < erc1155ToWithdraw.length; j++) {
            _withdrawERC1155(
                boxId,
                erc1155ToWithdraw[j].addr,
                erc1155ToWithdraw[j].ids,
                erc1155ToWithdraw[j].amounts,
                to
            );
        }

        emit Withdraw(
            boxId,
            ethAmount,
            erc20ToWithdraw,
            erc721ToWithdraw,
            erc1155ToWithdraw,
            to
        );
    }

    /**
     * @dev Get the balance of ethers in a box
     * @notice will always revert
     */
    function EthBalanceOf(uint256) public pure override returns (uint256) {
        revert();
    }

    /**
     * @dev Get the balance of an erc20 token in a box
     * @notice will always revert
     */
    function erc20BalanceOf(uint256, address)
        public
        pure
        override
        returns (uint256)
    {
        revert();
    }

    /**
     * @dev Get the balance of an erc1155 token in a box
     * @notice will always revert
     */
    function erc1155BalanceOf(
        uint256,
        address,
        uint256
    ) public pure override returns (uint256) {
        revert();
    }

    /**
     * @dev Check if an ERC721 token is in a box
     * @notice will always revert
     */
    function erc721BalanceOf(
        uint256,
        address,
        uint256
    ) public pure override returns (uint256) {
        revert();
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
     * @notice will always revert
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert();
    }

    /**
     * @dev Handles the receipt of a multiple ERC721 token types
     * @notice will always revert
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert();
    }

    /**
     * @dev Withdraw ethers from a box to an address
     *
     * @param boxId id of the box
     * @param amount amount of eth to withdraw
     */
    function _withdrawEth(
        uint256 boxId,
        uint256 amount,
        address payable to
    ) private {
        // update the box and check if the amount in the box in sufficient
        _indexedEth[boxId] -= amount;

        payable(to).transfer(amount);
    }

    /**
     * @dev Withdraw erc721 tokens from a box to an address
     *
     * @param boxId id of the box
     * @param tokenAddress address of the token
     * @param tokenIds list of token ids to withdraw
     * @param to address of reception
     */
    function _withdrawERC721(
        uint256 boxId,
        address tokenAddress,
        uint256[] calldata tokenIds,
        address to
    ) private {
        IERC721 token = IERC721(tokenAddress);

        for (uint256 k = 0; k < tokenIds.length; k++) {
            uint256 tokenId = tokenIds[k];
            bytes32 index = keccak256(
                abi.encodePacked(boxId, tokenAddress, tokenId)
            );

            // check if the token is in the box
            require(_indexedTokens[index] == 1, "e6");

            // update balance to avoid reentrancy
            delete _indexedTokens[index];

            // transfer the token to the owner of the box
            token.transferFrom(address(this), to, tokenId);
        }
    }

    /**
     * @dev Withdraw erc20 tokens from a box to an address
     *
     * @param boxId id of the box
     * @param tokenAddress address of the token
     * @param amountToWithdraw amount to withdraw
     * @param to address of reception
     */
    function _withdrawERC20(
        uint256 boxId,
        address tokenAddress,
        uint256 amountToWithdraw,
        address to
    ) private {
        bytes32 index = keccak256(abi.encodePacked(boxId, tokenAddress));

        // update the box and check if the amount in the box is sufficient
        _indexedTokens[index] -= amountToWithdraw;

        // Safely transfer the token
        IERC20 token = IERC20(tokenAddress);

        SafeERC20.safeTransfer(token, to, amountToWithdraw);
    }

    /**
     * @dev Withdraw erc1155 tokens from a box to an address
     *
     * @param boxId id of the box
     * @param tokenAddress address of the token
     * @param tokenIds list of token ids to withdraw
     * @param amounts amount to withdraw for each token id
     * @param to address of reception
     */
    function _withdrawERC1155(
        uint256 boxId,
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address to
    ) private {
        for (uint256 j = 0; j < tokenIds.length; j++) {
            bytes32 index = keccak256(
                abi.encodePacked(boxId, tokenAddress, tokenIds[j])
            );

            // update the box and check if the amount in the box in sufficient
            _indexedTokens[index] -= amounts[j];
        }

        IERC1155 token = IERC1155(tokenAddress);
        token.safeBatchTransferFrom(address(this), to, tokenIds, amounts, "");
    }

    /**
     * @dev store eth inside a box
     *
     * @param boxId id of the box
     * @param amount amount of eth to store
     */
    function _storeEth(uint256 boxId, uint256 amount) private {
        // update the box
        _indexedEth[boxId] += amount;
    }

    /**
     * @dev store erc721 tokens inside a box
     *
     * @param boxId id of the box
     * @param tokenAddress address of the token
     * @param tokenIds list of token ids to store
     */
    function _storeErc721(
        uint256 boxId,
        address tokenAddress,
        uint256[] calldata tokenIds
    ) private {
        // Avoid storing a box in a box
        require(tokenAddress != address(this), "e20");

        IERC721 token = IERC721(tokenAddress);

        for (uint256 j = 0; j < tokenIds.length; j++) {
            bytes32 index = keccak256(
                abi.encodePacked(boxId, tokenAddress, tokenIds[j])
            );

            require(_indexedTokens[index] == 0, "e1");

            // update the box
            _indexedTokens[index] = 1;

            // transfer the token to this very contract
            token.safeTransferFrom(_msgSender(), address(this), tokenIds[j]);
        }
    }

    /**
     * @dev store erc20 tokens in a box
     *
     * @param boxId id of the box
     * @param tokenAddress address of the token
     * @param amount amount to store
     */
    function _storeErc20(
        uint256 boxId,
        address tokenAddress,
        uint256 amount
    ) private {
        bytes32 index = keccak256(abi.encodePacked(boxId, tokenAddress));

        // update the box
        _indexedTokens[index] += amount;

        IERC20 token = IERC20(tokenAddress);

        // Safely transfer the token to this very contract
        SafeERC20.safeTransferFrom(
            token,
            _msgSender(),
            address(this),
            amount
        );
    }

    /**
     * @dev store erc1155 tokens in a box
     *
     * @param boxId id of the box
     * @param tokenAddress address of the token
     * @param tokenIds list of token ids to store
     * @param amounts amount to store for each token id
     */
    function _storeErc1155(
        uint256 boxId,
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private {
        for (uint256 j = 0; j < tokenIds.length; j++) {
            bytes32 index = keccak256(
                abi.encodePacked(boxId, tokenAddress, tokenIds[j])
            );

            // update the box
            _indexedTokens[index] += amounts[j];
        }

        IERC1155 token = IERC1155(tokenAddress);

        // transfer the token to this very contract
        token.safeBatchTransferFrom(
            _msgSender(),
            address(this),
            tokenIds,
            amounts,
            ""
        );
    }

    /**
     * @dev transfer ethers from a box to another
     *
     * @param srcBoxId id of the source box
     * @param srcBoxId id of the destination box
     * @param ethAmount amount of eth to transfer
     */
    function _transferEthBetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        uint256 ethAmount
    ) private {
        // remove from the source box
        _indexedEth[srcBoxId] -= ethAmount;

        // destination index
        _indexedEth[destBoxId] += ethAmount;
    }

    /**
     * @dev transfer erc721 from a box to another
     *
     * @param srcBoxId id of the source box
     * @param srcBoxId id of the destination box
     * @param erc721s list of erc721s token to transfer
     */
    function _transferErc721BetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        ERC721TokenInfos[] calldata erc721s
    ) private {
        for (uint256 j = 0; j < erc721s.length; j++) {
            for (uint256 k = 0; k < erc721s[j].ids.length; k++) {
                // source index
                bytes32 index = keccak256(
                    abi.encodePacked(
                        srcBoxId,
                        erc721s[j].addr,
                        erc721s[j].ids[k]
                    )
                );
                require(_indexedTokens[index] == 1, "e16");
                // remove from the source box
                delete _indexedTokens[index];

                // destination index
                index = keccak256(
                    abi.encodePacked(
                        destBoxId,
                        erc721s[j].addr,
                        erc721s[j].ids[k]
                    )
                );
                // add to the destination box
                _indexedTokens[index] = 1;
            }
        }
    }

    /**
     * @dev transfer erc20 from a box to another
     *
     * @param srcBoxId id of the source box
     * @param srcBoxId id of the destination box
     * @param erc20s list of erc20s token to transfer
     */
    function _transferErc20BetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        ERC20TokenInfos[] calldata erc20s
    ) private {
        for (uint256 j = 0; j < erc20s.length; j++) {
            // source index
            bytes32 index = keccak256(
                abi.encodePacked(srcBoxId, erc20s[j].addr)
            );

            // remove from the source box
            _indexedTokens[index] -= erc20s[j].amount;

            // destination index
            index = keccak256(abi.encodePacked(destBoxId, erc20s[j].addr));
            // add to the destination box
            _indexedTokens[index] += erc20s[j].amount;
        }
    }

    /**
     * @dev transfer erc1155 from a box to another
     *
     * @param srcBoxId id of the source box
     * @param srcBoxId id of the destination box
     * @param erc1155s list of erc1155 tokens to transfer
     */
    function _transferErc1155BetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        ERC1155TokenInfos[] calldata erc1155s
    ) private {
        for (uint256 j = 0; j < erc1155s.length; j++) {
            for (uint256 k = 0; k < erc1155s[j].ids.length; k++) {
                // source index
                bytes32 index = keccak256(
                    abi.encodePacked(
                        srcBoxId,
                        erc1155s[j].addr,
                        erc1155s[j].ids[k]
                    )
                );

                // remove from the source box
                _indexedTokens[index] -= erc1155s[j].amounts[k];

                // destination index
                index = keccak256(
                    abi.encodePacked(
                        destBoxId,
                        erc1155s[j].addr,
                        erc1155s[j].ids[k]
                    )
                );
                // add to the destination box
                _indexedTokens[index] += erc1155s[j].amounts[k];
            }
        }
    }
}
