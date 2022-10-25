// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BoxBase.sol";


contract AdminTest is Test {

    BoxBase public boxBase;
    
    function setUp() public {
        boxBase = new BoxBase();
    }

    function testStore() public {
        BoxBase.ERC20TokenInfos[] memory erc20s = new BoxBase.ERC20TokenInfos[](1);
        BoxBase.ERC721TokenInfos[] memory erc721s = new BoxBase.ERC721TokenInfos[](1);
        BoxBase.ERC1155TokenInfos[] memory erc1155s = new BoxBase.ERC1155TokenInfos[](1);

        vm.expectRevert("only delegateCall");
        boxBase.store(1, erc20s, erc721s, erc1155s);
    }

    function testWithdraw() public {
        BoxBase.ERC20TokenInfos[] memory erc20s = new BoxBase.ERC20TokenInfos[](1);
        BoxBase.ERC721TokenInfos[] memory erc721s = new BoxBase.ERC721TokenInfos[](1);
        BoxBase.ERC1155TokenInfos[] memory erc1155s = new BoxBase.ERC1155TokenInfos[](1);

        vm.expectRevert("only delegateCall");
        boxBase.withdraw(1, 0, erc20s, erc721s, erc1155s, payable(address(1)));
    }

    function testDestroy() public {
        BoxBase.ERC20TokenInfos[] memory erc20s = new BoxBase.ERC20TokenInfos[](1);
        BoxBase.ERC721TokenInfos[] memory erc721s = new BoxBase.ERC721TokenInfos[](1);
        BoxBase.ERC1155TokenInfos[] memory erc1155s = new BoxBase.ERC1155TokenInfos[](1);

        vm.expectRevert("only delegateCall");
        boxBase.destroy(1, 0, erc20s, erc721s, erc1155s, payable(address(1)));
    }

    function testTransferBetweenBoxes() public {
        BoxBase.ERC20TokenInfos[] memory erc20s = new BoxBase.ERC20TokenInfos[](1);
        BoxBase.ERC721TokenInfos[] memory erc721s = new BoxBase.ERC721TokenInfos[](1);
        BoxBase.ERC1155TokenInfos[] memory erc1155s = new BoxBase.ERC1155TokenInfos[](1);

        vm.expectRevert("only delegateCall");
        boxBase.transferBetweenBoxes(1, 2, 0, erc20s, erc721s, erc1155s);
    }

}
