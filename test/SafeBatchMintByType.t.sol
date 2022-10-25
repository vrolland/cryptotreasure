// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CryptoTreasure.sol";
import "../src/BoxBase.sol";
import "../src/test/ERC20PausableMock.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract SafeBatchMintByTypeFreeTest is Test {
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

    function testBatchMint() public {
        address[] memory addresses = new address[](3);
        addresses[0]= address(1);
        addresses[1]= address(2);
        addresses[2]= address(3);

        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), from);
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(2), from + 1);
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(3), from + 2);

        cryptoTreasure.safeBatchMintByType(
            addresses,
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

    function testBatchMintTwo() public {
        vm.warp(block.timestamp + 11);
        cryptoTreasure.safeMint(
            address(1),
            from,
            abi.encodePacked(typeId, uint8(0))
        );

        address[] memory addresses = new address[](3);
        addresses[0]= address(1);
        addresses[1]= address(2);
        addresses[2]= address(3);

        vm.warp(block.timestamp + 11);
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), from + 1);
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(2), from + 2);
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(3), from + 3);

        cryptoTreasure.safeBatchMintByType(
            addresses,
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

    function testBatchMintNotAdmin() public {
        address[] memory addresses = new address[](1);
        addresses[0]= address(1);

        vm.prank(address(1));
        
        vm.expectRevert(bytes("AccessControl: account 0x0000000000000000000000000000000000000001 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"));
        cryptoTreasure.safeBatchMintByType(
            addresses,
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

    function testBatchMintTooLate() public {
        address[] memory addresses = new address[](5);

        for(uint160 i = 1; i <= 5; i++) {
            addresses[i-1]= address(i);
        }
        
        vm.expectRevert(bytes("e18"));
        cryptoTreasure.safeBatchMintByType(
            addresses,
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

    function testBatchMintNoType() public {
        address[] memory addresses = new address[](3);
        for(uint160 i = 1; i <= 3; i++) {
            addresses[i-1]= address(i);
        }

        vm.expectRevert(bytes("e10"));
        cryptoTreasure.safeBatchMintByType(
            addresses,
            2,
            abi.encodePacked(bytes1(0))
        );
    }

}


contract SafeBatchMintTokenLockedTest is Test {
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


    function testBatchMint() public {
        erc20Mock.approve(address(cryptoTreasure), 3000);
        address[] memory addresses = new address[](3);
        addresses[0]= address(1);
        addresses[1]= address(2);
        addresses[2]= address(3);

        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), from);
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(2), from + 1);
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(3), from + 2);

        cryptoTreasure.safeBatchMintByType(
            addresses,
            typeId,
            abi.encodePacked(bytes1(0))
        );

        assertEq(erc20Mock.balanceOf(address(cryptoTreasure)), 3000);
    }

    function testMintWithoutApproval() public {
        address[] memory addresses = new address[](3);
        addresses[0]= address(1);
        addresses[1]= address(2);
        addresses[2]= address(3);

        vm.expectRevert(bytes("ERC20: insufficient allowance"));

        cryptoTreasure.safeBatchMintByType(
            addresses,
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

    function testMintWithoutTokens() public {
        erc20Mock.transfer(address(2), 100000000000000);
        
        address[] memory addresses = new address[](3);
        addresses[0]= address(1);
        addresses[1]= address(2);
        addresses[2]= address(3);

        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        cryptoTreasure.safeBatchMintByType(
            addresses,
            typeId,
            abi.encodePacked(bytes1(0))
        );
    }

}