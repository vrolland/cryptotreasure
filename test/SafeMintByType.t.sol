// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CryptoTreasure.sol";
import "../src/BoxBase.sol";
import "../src/test/ERC20PausableMock.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract SafeMintByTypeFreeTest is Test {
    ERC20PausableMock public erc20Mock;
    BoxBase public boxBase;
    CryptoTreasure public cryptoTreasure;
    
    uint256 public typeId = 1;
    uint256 public from = 10;
    uint256 public to = 13;
    uint256 public amountToLock = 0;
    uint256 public durationLockDestroy = 0;
    uint256 public mintingDurationLock = 10;
    uint256 public numberReserved = 1;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);


    function setUp() public {
        erc20Mock = new ERC20PausableMock(
            "erc20Mock",
            "MOCK",
            address(1),
            100000000000000
        );
        boxBase = new BoxBase();
        cryptoTreasure = new CryptoTreasure(address(boxBase));

        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(amountToLock), uint256(durationLockDestroy), uint256(mintingDurationLock), uint256(numberReserved));
        cryptoTreasure.addType(typeId, from, to, data);
    }

    function testMintOne() public {
        vm.warp(block.timestamp + 11);
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), from);

        cryptoTreasure.safeMintByType(
            address(1),
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

    function testMintTwo() public {
        vm.warp(block.timestamp + 11);

        cryptoTreasure.safeMint(
            address(1),
            from,
            abi.encodePacked(typeId, uint8(0))
        );

        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), from + 1);

        cryptoTreasure.safeMintByType(
            address(1),
            typeId,
            abi.encodePacked(bytes1(0))
        );

        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), from + 2);

        cryptoTreasure.safeMintByType(
            address(1),
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

    function testMintTooLate() public {
        vm.warp(block.timestamp + 11);

        for(uint256 i = 0; i < 4; i++) {
            cryptoTreasure.safeMint(
                address(1),
                from + i,
                abi.encodePacked(typeId, uint8(0))
            );
        }
        
        vm.expectRevert(bytes("e18"));
        cryptoTreasure.safeMintByType(
            address(1),
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

    function testMintOneTooEarly() public {
        vm.expectRevert(bytes("e19"));
        cryptoTreasure.safeMintByType(
            address(1),
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

    function testMintReservedToken() public {
        vm.warp(block.timestamp + 11);

        for(uint256 i = 0; i < 3; i++) {
            vm.prank(address(1));
            cryptoTreasure.safeMint(
                address(1),
                from + i,
                abi.encodePacked(typeId, uint8(0))
            );
        }

        vm.prank(address(1));
        vm.expectRevert(bytes("e22"));
        cryptoTreasure.safeMintByType(
            address(1),
            typeId,
            abi.encodePacked(bytes1(0))
        );

        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), from + 3);       
        cryptoTreasure.safeMintByType(
            address(1),
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

    function testMintNoType() public {
        vm.warp(block.timestamp + 11);

        vm.expectRevert(bytes("e10"));
        cryptoTreasure.safeMintByType(
            address(1),
            2,
            abi.encodePacked(bytes1(0))
        );
    } 
}

contract SafeMintTokenLockedTest is Test {
    ERC20PausableMock public erc20Mock;
    BoxBase public boxBase;
    CryptoTreasure public cryptoTreasure;
    
    uint256 public typeId = 1;
    uint256 public from = 10;
    uint256 public to = 99;
    uint256 public amountToLock = 1000;
    uint256 public durationLockDestroy = 0;
    uint256 public mintingDurationLock = 0;
    uint256 public numberReserved = 30;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);


    function setUp() public {
        erc20Mock = new ERC20PausableMock(
            "erc20Mock",
            "MOCK",
            address(this),
            100000000000000
        );
        boxBase = new BoxBase();
        cryptoTreasure = new CryptoTreasure(address(boxBase));

        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(amountToLock), uint256(durationLockDestroy), uint256(mintingDurationLock), uint256(numberReserved));
        cryptoTreasure.addType(typeId, from, to, data);
    }


    function testMintOne() public {
        erc20Mock.approve(address(cryptoTreasure), amountToLock);

        vm.warp(block.timestamp + 11);
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), from);

        cryptoTreasure.safeMintByType(
            address(1),
            typeId,
            abi.encodePacked(bytes1(0))
        );

        assertEq(erc20Mock.balanceOf(address(cryptoTreasure)), 1000);
    }

    function testMintWithoutApproval() public {
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        cryptoTreasure.safeMintByType(
            address(1),
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

    function testMintWithoutTokens() public {

        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        vm.prank(address(2));
        cryptoTreasure.safeMintByType(
            address(1),
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

}