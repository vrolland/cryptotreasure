// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/CryptoTreasure.sol";
import "contracts/BoxBase.sol";
import "contracts/erc20keys/ERC20Key.sol";

contract Erc20KeyTest is Test {
    ERC20Key public erc20Key;
    BoxBase public boxBase;
    CryptoTreasure public cryptoTreasure;
    
    uint256 public typeId = 1;
    uint256 public from = 10;
    uint256 public to = 99;
    uint256 public amountToLock = 1;
    uint256 public durationLockDestroy = 0;
    uint256 public mintingDurationLock = 0;
    uint256 public numberReserved = 30;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);


    function setUp() public {
        boxBase = new BoxBase();
        cryptoTreasure = new CryptoTreasure(address(boxBase));
        erc20Key = new ERC20Key(
            "erc20KeyMock",
            "MOCK",
            address(cryptoTreasure)
        );

        erc20Key.mint(address(1), 100);

        bytes memory data = abi.encodePacked(address(erc20Key), uint256(amountToLock), uint256(durationLockDestroy), uint256(mintingDurationLock), uint256(numberReserved));
        cryptoTreasure.addType(typeId, from, to, data);
    }


    function testMintOne(uint256 treasureId) public {
        vm.warp(block.timestamp + 11);
        vm.assume(treasureId <= to - numberReserved);
        vm.assume(treasureId >= from);

        vm.prank(address(1));
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), treasureId);
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );

        assertEq(erc20Key.balanceOf(address(cryptoTreasure)), 1);
    }

    function testAllowance() public {
        assertEq(erc20Key.allowance(
            address(1),
            address(cryptoTreasure)
        ), type(uint256).max);

        vm.prank(address(1));
        erc20Key.approve(address(4), 50);

        assertEq(erc20Key.allowance(
            address(1),
            address(4)
        ), 50);
    }

}