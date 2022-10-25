// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CryptoTreasure.sol";
import "../src/BoxBase.sol";
import "../src/test/ERC20PausableMock.sol";


contract AdminTest is Test {
    ERC20PausableMock public erc20Mock;
    BoxBase public boxBase;
    CryptoTreasure public cryptoTreasure;
    uint256 MAX_TIME = 10000000000;
    

    function setUp() public {
        erc20Mock = new ERC20PausableMock(
            "erc20Mock",
            "MOCK",
            address(1),
            100000000000000
        );
        boxBase = new BoxBase();
        cryptoTreasure = new CryptoTreasure(address(boxBase));
    }

    function testAddOneType(uint256 from, uint256 to, uint256 amountToLock, uint256 durationLockDestroy, uint256 mintingDurationLock,  uint256 numberReserved) public {
        vm.assume(from < to);
        // overflow if from 0 and to type(uint256).max
        vm.assume(from != 0 || to != type(uint256).max);
        vm.assume(numberReserved <= to - from);
        
        vm.assume(durationLockDestroy < MAX_TIME);
        vm.assume(mintingDurationLock < MAX_TIME);


        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(amountToLock), uint256(durationLockDestroy), uint256(mintingDurationLock), uint256(numberReserved));
        cryptoTreasure.addType(1, from, to, data);

        checkType(1, from, to, amountToLock, durationLockDestroy, mintingDurationLock, numberReserved);

    }

    function testAddTypeNotOwner() public {
        bytes memory data1 = abi.encodePacked(address(erc20Mock), uint256(1000), uint256(0), uint256(0), uint256(30));
        bytes memory data2 = abi.encodePacked(address(erc20Mock), uint256(0), uint256(0), uint256(0), uint256(0));
        
        vm.prank(address(1));
        vm.expectRevert("AccessControl: account 0x0000000000000000000000000000000000000001 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
        cryptoTreasure.addType(1, 10, 99, data1);

        uint256[] memory ids = new uint256[](2);
        ids[0]=1; ids[1]=2;
        uint256[] memory froms = new uint256[](2);
        ids[0]=10; ids[1]=100;
        uint256[] memory tos = new uint256[](2);
        ids[0]=99; ids[1]=199;
        bytes[] memory datas = new bytes[](2);
        datas[0]=data1; datas[1]=data2;

        vm.prank(address(1));
        vm.expectRevert("AccessControl: account 0x0000000000000000000000000000000000000001 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
        cryptoTreasure.addTypes(ids, froms, tos, datas);
    }

    function testAddTypeFromOverTo() public {
        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(1000), uint256(0), uint256(0), uint256(30));
        // from > to
        vm.expectRevert(bytes("e14"));
        cryptoTreasure.addType(1, 100, 99, data);

        // from = to
        vm.expectRevert(bytes("e14"));
        cryptoTreasure.addType(1, 100, 100, data);        
    }

    function testAddTypeOverReserved() public {
        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(1000), uint256(0), uint256(0), uint256(101));

        vm.expectRevert(bytes("e21"));
        cryptoTreasure.addType(1, 10, 99, data);        
    }

    function testAddTypeTwice() public {
        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(1000), uint256(0), uint256(0), uint256(10));

        cryptoTreasure.addType(1, 10, 99, data);   

        vm.expectRevert(bytes("e13"));
        cryptoTreasure.addType(1, 10, 99, data);        
    }

    function testAddTwoTypes() public {
        bytes memory data1 = abi.encodePacked(address(erc20Mock), uint256(1000), uint256(1), uint256(2), uint256(30));
        bytes memory data2 = abi.encodePacked(address(erc20Mock), uint256(0), uint256(0), uint256(0), uint256(0));

        uint256[] memory ids = new uint256[](2);
        ids[0]=1; ids[1]=2;
        uint256[] memory froms = new uint256[](2);
        froms[0]=10; froms[1]=100;
        uint256[] memory tos = new uint256[](2);
        tos[0]=99; tos[1]=199;
        bytes[] memory datas = new bytes[](2);
        datas[0]=data1; datas[1]=data2;

        cryptoTreasure.addTypes(ids, froms, tos, datas);

        checkType(1, 10, 99, 1000, 1, 2, 30);
        checkType(2, 100, 199, 0, 0, 0, 0);
    }

    function testUpdateBaseURI() public {
        string memory newUri = "http://127.0.0.1/";
        cryptoTreasure.updateBaseURI(newUri);

        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(0), uint256(0), uint256(0), uint256(0));
        cryptoTreasure.addType(1, 1, 10, data);
        cryptoTreasure.safeMint(address(1), 1, abi.encodePacked(uint256(1), uint8(0)));

        assertEq(cryptoTreasure.tokenURI(1), "http://127.0.0.1/1");
    }

    function testUpdateBaseURINotOwner() public {
        vm.prank(address(1));
        vm.expectRevert("AccessControl: account 0x0000000000000000000000000000000000000001 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
        cryptoTreasure.updateBaseURI("http://127.0.0.1/");
    }

    function testSupportedInterface() public {
        bytes4 _InterfaceId_ERC165 = 0x01ffc9a7;
        bytes4 _InterfaceId_ERC721 = 0x80ac58cd;
        bytes4 _InterfaceId_ERC721MetaData = 0x5b5e139f;
        bytes4 _InterfaceId_BOX = 0xaf0eefe8;
        bytes4 _InterfaceId_ERC721TokenReceiver = 0x150b7a02;
        bytes4 _InterfaceId_ERC1155TokenReceiver = 0x4e2312e0;

        assertTrue(cryptoTreasure.supportsInterface(_InterfaceId_ERC165));
        assertTrue(cryptoTreasure.supportsInterface(_InterfaceId_ERC721));
        assertTrue(cryptoTreasure.supportsInterface(_InterfaceId_ERC721MetaData));
        assertTrue(cryptoTreasure.supportsInterface(_InterfaceId_ERC721TokenReceiver));
        assertTrue(cryptoTreasure.supportsInterface(_InterfaceId_ERC1155TokenReceiver));
        assertTrue(cryptoTreasure.supportsInterface(_InterfaceId_BOX));    
    }

    // Utils ----------------------------------------------------
    function checkType(uint256 id, uint256 from, uint256 to, uint256 amountToLock, uint256 durationLockDestroy, uint256 mintingDurationLock, uint256 numberReserved) private {
        (   uint256 fromResult,
            uint256 toResult,
            bytes memory _dataResult,
            uint256 nextToMint
        ) = cryptoTreasure._types(id);
        
        assertEq(fromResult, from);
        assertEq(to, toResult);
        assertEq(nextToMint, from);
        assertEq(cryptoTreasure._lockedDestructionDuration(id), durationLockDestroy);

        (   address addr,
            uint256 amountResult
        ) = cryptoTreasure._erc20ToLock(id);
        assertEq(addr, address(erc20Mock));
        assertEq(amountToLock, amountResult);

        assertEq(cryptoTreasure._lastIdNotReserved(id), to - numberReserved);

        assertEq(cryptoTreasure._mintStartTimestamp(id), block.timestamp + mintingDurationLock);
    }
}
