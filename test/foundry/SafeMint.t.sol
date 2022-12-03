// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/CryptoTreasure.sol";
import "contracts/BoxBase.sol";
import "contracts/test/ERC20PausableMock.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract SafeMintFreeTest is Test {
    ERC20PausableMock public erc20Mock;
    BoxBase public boxBase;
    CryptoTreasure public cryptoTreasure;
    
    uint256 public typeId = 1;
    uint256 public from = 10;
    uint256 public to = 99;
    uint256 public amountToLock = 0;
    uint256 public durationLockDestroy = 0;
    uint256 public mintingDurationLock = 10;
    uint256 public numberReserved = 30;

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


    function testMintOne(uint256 treasureId) public {
        vm.assume(treasureId <= to - numberReserved);
        vm.assume(treasureId >= from);
        vm.warp(block.timestamp + 11);
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), treasureId);

        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );
    }

    function testMintReservedToken(uint256 treasureId) public {
        vm.warp(block.timestamp + 11);
        vm.assume(treasureId <= to);
        vm.assume(treasureId > to - numberReserved);

        vm.prank(address(1));
        vm.expectRevert(bytes("e22"));
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );

        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), treasureId);       
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );
    }
    
    function testMintOneTooEarly() public {
        uint256 treasureId = to - numberReserved;

        vm.expectRevert(bytes("e19"));
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );
    }

    function testMintTwice() public {
        uint256 treasureId = to - numberReserved;
        vm.warp(block.timestamp + 11);

        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), treasureId);  
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );

        vm.expectRevert(bytes("ERC721: token already minted"));
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );
    }

    function testMintNotExistingType(uint256 typeIdCurrent) public {
        uint256 treasureId = 11;
        vm.assume(typeId != typeIdCurrent && typeIdCurrent != 0);

        vm.expectRevert(bytes("e10"));
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeIdCurrent, uint8(0))
        );
    }

    function testMintIdTooHigh(uint256 treasureId) public {
        vm.assume(treasureId > to);

        vm.expectRevert(bytes("e12"));
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );
    }

    function testMintIdTooLow(uint256 treasureId) public {
        vm.assume(treasureId < from);

        vm.expectRevert(bytes("e11"));
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );
    }

    function testMintNoType(uint256 treasureId) public {
        vm.assume(treasureId < from);

        vm.expectRevert(bytes("e0"));
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            bytes("")
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


    function testMintOne(uint256 treasureId) public {
        vm.warp(block.timestamp + 11);
        vm.assume(treasureId <= to - numberReserved);
        vm.assume(treasureId >= from);

        erc20Mock.approve(address(cryptoTreasure), amountToLock);

        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Transfer(address(0), address(1), treasureId);
        
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );

        assertEq(erc20Mock.balanceOf(address(cryptoTreasure)), 1000);
    }

    function testMintWithoutApproval(uint256 treasureId) public {
        vm.assume(treasureId <= to - numberReserved);
        vm.assume(treasureId >= from);

        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );
    }

    function testMintWithoutTokens(uint256 treasureId) public {
        vm.assume(treasureId <= to - numberReserved);
        vm.assume(treasureId >= from);

        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        vm.prank(address(2));
        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );
    }

}