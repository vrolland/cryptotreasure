// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/CryptoTreasure.sol";
import "contracts/IBox.sol";

contract TestTreasture is Test {

    function checkTreasure(
        CryptoTreasure _cryptoTreasure,
        uint256 _srcBoxId,
        uint256 _ethBalance,
        IBox.ERC20TokenInfos[] memory erc20s,
        IBox.ERC721TokenInfos[] memory erc721s,
        IBox.ERC721TokenInfos[] memory notErc721s,
        IBox.ERC1155TokenInfos[] memory erc1155s
    ) public {
        assertEq(_cryptoTreasure.EthBalanceOf(_srcBoxId), _ethBalance );

        for (uint256 j = 0; j < erc20s.length; j++) {
            assertEq(_cryptoTreasure.erc20BalanceOf(_srcBoxId, erc20s[j].addr), erc20s[j].amount);
        }

        for (uint256 j = 0; j < erc721s.length; j++) {
            for (uint256 k = 0; k < erc721s[j].ids.length; k++) {
                assertEq(_cryptoTreasure.erc721BalanceOf(_srcBoxId, erc721s[j].addr, erc721s[j].ids[k]), 1);
            }
        }

        for (uint256 j = 0; j < notErc721s.length; j++) {
            for (uint256 k = 0; k < notErc721s[j].ids.length; k++) {
                assertEq(_cryptoTreasure.erc721BalanceOf(_srcBoxId, notErc721s[j].addr, notErc721s[j].ids[k]), 0);
            }
        }
    

        for (uint256 j = 0; j < erc1155s.length; j++) {
            for (uint256 k = 0; k < erc1155s[j].ids.length; k++) {
                assertEq(_cryptoTreasure.erc1155BalanceOf(_srcBoxId, erc1155s[j].addr, erc1155s[j].ids[k]), erc1155s[j].amounts[k]);
            }
        }
    }
}
