// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CryptoTreasure.sol";
import "../src/BoxBase.sol";
import "../src/IBox.sol";
import "../src/test/ERC20PausableMock.sol";
import "../src/test/ERC721PausableMock.sol";
import "../src/test/ERC1155Mock.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./utils.t.sol";


contract DestroyTest is TestTreasture {
    ERC20PausableMock public erc20Mock;
    ERC20PausableMock public erc20Mock2;
    
    ERC721PausableMock public erc721Mock1;
    ERC721PausableMock public erc721Mock2;

    ERC1155Mock public erc1155Mock1;
    BoxBase public boxBase;
    CryptoTreasure public cryptoTreasure;
    
    uint256 public typeId = 1;
    uint256 public from = 10;
    uint256 public to = 99;
    uint256 public amountToLock = 0;
    uint256 public durationLockDestroy = 0;
    uint256 public mintingDurationLock = 0;
    uint256 public numberReserved = 30;
    uint256 public treasureId = 11;


    uint256 public typeId2 = 2;
    uint256 public from2 = 100;
    uint256 public to2 = 999;
    uint256 public amountToLock2 = 30000;
    uint256 public treasureId2 = 100;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Store(
        uint256 indexed boxId,
        uint256 ethAmount,
        IBox.ERC20TokenInfos[] erc20s,
        IBox.ERC721TokenInfos[] erc721s,
        IBox.ERC1155TokenInfos[] erc1155s
    );

    event Withdraw(
        uint256 indexed boxId,
        uint256 ethAmount,
        IBox.ERC20TokenInfos[] erc20s,
        IBox.ERC721TokenInfos[] erc721s,
        IBox.ERC1155TokenInfos[] erc1155s,
        address to
    );

    event Destroyed(uint256 indexed boxId);

    function setUp() public {
        vm.deal(address(1), 10000000000000000000);
        vm.deal(address(3), 10000000000000000000);

        erc20Mock = new ERC20PausableMock(
            "erc20Mock",
            "MOCK",
            address(1),
            100000000000000
        );
        erc20Mock2 = new ERC20PausableMock(
            "erc20Mock",
            "MOCK",
            address(1),
            100000000000000
        );

        erc721Mock1 = new ERC721PausableMock(
            "MockERC721",
            "MOCK721"
        );
        erc721Mock1.safeMint(address(1), 11);
        erc721Mock1.safeMint(address(1), 12);
        erc721Mock2 = new ERC721PausableMock(
            "MockERC721",
            "MOCK721"
        );
        erc721Mock2.safeMint(address(1), 21);
        erc721Mock2.safeMint(address(1), 22);

        erc1155Mock1 = new ERC1155Mock();
        uint256[] memory ids = new uint256[](2);
        ids[0] = 111; ids[1] = 112;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1000; amounts[1] = 2000;
        erc1155Mock1.mintBatch(
            address(1),
            ids,
            amounts
        );

        boxBase = new BoxBase();
        cryptoTreasure = new CryptoTreasure(address(boxBase));

        // not collateralized type
        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(amountToLock), uint256(durationLockDestroy), uint256(mintingDurationLock), uint256(numberReserved));
        cryptoTreasure.addType(typeId, from, to, data);


        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );

        // set up store
        uint256 value = 1000;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](2);
        erc20s[0] = IBox.ERC20TokenInfos({addr: address(erc20Mock), amount: 1000});
        erc20s[1] = IBox.ERC20TokenInfos({addr: address(erc20Mock2), amount: 200});

        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](2);
        uint256[] memory ids721 = new uint256[](2);
        ids721[0] = 11; ids721[1] = 12;
        erc721s[0] = IBox.ERC721TokenInfos({addr: address(erc721Mock1), ids: ids721});
        
        uint256[] memory ids721_2 = new uint256[](2);
        ids721_2[0] = 21; ids721_2[1] = 22;
        erc721s[1] = IBox.ERC721TokenInfos({addr: address(erc721Mock2), ids: ids721_2});

        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](1);
        ids = new uint256[](1);
        amounts = new uint256[](1);
        ids[0] = 111; amounts[0] = 123;
        erc1155s[0] = IBox.ERC1155TokenInfos({addr: address(erc1155Mock1), ids: ids, amounts: amounts});

        // approve everything
        vm.prank(address(1));
        erc20Mock.approve(address(cryptoTreasure), 1000);
        vm.prank(address(1));
        erc20Mock2.approve(address(cryptoTreasure), 200);
        vm.prank(address(1));
        erc721Mock1.approve(address(cryptoTreasure), 11);
        vm.prank(address(1));
        erc721Mock1.approve(address(cryptoTreasure), 12);
        vm.prank(address(1));
        erc721Mock2.approve(address(cryptoTreasure), 21);
        vm.prank(address(1));
        erc721Mock2.approve(address(cryptoTreasure), 22);
        vm.prank(address(1));
        erc1155Mock1.setApprovalForAll(address(cryptoTreasure), true);

        vm.prank(address(1));
        cryptoTreasure.store{value:value}(treasureId, erc20s, erc721s, erc1155s);

    }


    function testDestroy() public {
        // set up withdraw
        uint256 value = 1000;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](2);
        erc20s[0] = IBox.ERC20TokenInfos({addr: address(erc20Mock), amount: 1000});
        erc20s[1] = IBox.ERC20TokenInfos({addr: address(erc20Mock2), amount: 200});

        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](2);
        uint256[] memory ids721 = new uint256[](2);
        ids721[0] = 11; ids721[1] = 12;
        erc721s[0] = IBox.ERC721TokenInfos({addr: address(erc721Mock1), ids: ids721});
        
        uint256[] memory ids721_2 = new uint256[](2);
        ids721_2[0] = 21; ids721_2[1] = 22;
        erc721s[1] = IBox.ERC721TokenInfos({addr: address(erc721Mock2), ids: ids721_2});

        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](1);
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 111; amounts[0] = 123;
        erc1155s[0] = IBox.ERC1155TokenInfos({addr: address(erc1155Mock1), ids: ids, amounts: amounts});


        // destroy
        vm.prank(address(1));
        // vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        // emit Withdraw(treasureId, value, erc20s, erc721s, erc1155s, address(4));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit Destroyed(treasureId);
        cryptoTreasure.destroy(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        assertEq(cryptoTreasure.destroyedBoxes(treasureId), true);

        // set up for treasure check:
        IBox.ERC721TokenInfos[] memory notErc721s= new IBox.ERC721TokenInfos[](2);
        notErc721s[0] = IBox.ERC721TokenInfos({addr: address(erc721Mock1), ids: ids721});
        notErc721s[1] = IBox.ERC721TokenInfos({addr: address(erc721Mock2), ids: ids721_2});

        erc20s[0] = IBox.ERC20TokenInfos({addr: address(erc20Mock), amount: 0});
        erc20s[1] = IBox.ERC20TokenInfos({addr: address(erc20Mock2), amount: 0});

        erc721s = new IBox.ERC721TokenInfos[](0);
    
        amounts[0] = 0;
        erc1155s[0] = IBox.ERC1155TokenInfos({addr: address(erc1155Mock1), ids: ids, amounts: amounts});


        // check treasure
        checkTreasure(
            cryptoTreasure,
            treasureId,
            0,
            erc20s,
            erc721s,
            notErc721s,
            erc1155s
        );

        // check balances
        assertEq(address(cryptoTreasure).balance, 0);
        assertEq(address(4).balance, value);

        assertEq(erc20Mock.balanceOf(address(cryptoTreasure)), 0);
        assertEq(erc20Mock.balanceOf(address(4)), 1000);

        assertEq(erc20Mock2.balanceOf(address(cryptoTreasure)), 0);
        assertEq(erc20Mock2.balanceOf(address(4)), 200);

        assertEq(erc721Mock1.ownerOf(11), address(4));
        assertEq(erc721Mock1.ownerOf(12), address(4));

        assertEq(erc721Mock1.balanceOf(address(cryptoTreasure)), 0);
        assertEq(erc721Mock1.balanceOf(address(4)), 2);
        
        assertEq(erc721Mock2.ownerOf(21), address(4));
        assertEq(erc721Mock2.ownerOf(22), address(4));
        assertEq(erc721Mock2.balanceOf(address(cryptoTreasure)), 0);
        assertEq(erc721Mock2.balanceOf(address(4)), 2);

        assertEq(erc1155Mock1.balanceOf(address(4), 111), 123);
        assertEq(erc1155Mock1.balanceOf(address(cryptoTreasure), 111), 0);
    }


    function testDestroyWithdrawPart() public {
        // set up withdraw
        uint256 value = 300;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](2);
        erc20s[0] = IBox.ERC20TokenInfos({addr: address(erc20Mock), amount: 800});
        erc20s[1] = IBox.ERC20TokenInfos({addr: address(erc20Mock2), amount: 50});

        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](2);
        uint256[] memory ids721 = new uint256[](1);
        ids721[0] = 11;
        erc721s[0] = IBox.ERC721TokenInfos({addr: address(erc721Mock1), ids: ids721});
        
        uint256[] memory ids721_2 = new uint256[](1);
        ids721_2[0] = 22;
        erc721s[1] = IBox.ERC721TokenInfos({addr: address(erc721Mock2), ids: ids721_2});

        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](1);
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 111; amounts[0] = 23;
        erc1155s[0] = IBox.ERC1155TokenInfos({addr: address(erc1155Mock1), ids: ids, amounts: amounts});
    
        // destroy
        vm.prank(address(1));
        // vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        // emit Withdraw(treasureId, value, erc20s, erc721s, erc1155s, address(4));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit Destroyed(treasureId);
        cryptoTreasure.destroy(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        assertEq(cryptoTreasure.destroyedBoxes(treasureId), true);

        // set up for treasure check:
        IBox.ERC721TokenInfos[] memory notErc721s= new IBox.ERC721TokenInfos[](2);
        uint256[] memory ids721Not = new uint256[](1);
        ids721Not[0] = 11;
        notErc721s[0] = IBox.ERC721TokenInfos({addr: address(erc721Mock1), ids: ids721Not});

        uint256[] memory ids721Not_2 = new uint256[](1);
        ids721Not_2[0] = 22;
        notErc721s[1] = IBox.ERC721TokenInfos({addr: address(erc721Mock2), ids: ids721Not_2});


        ids721[0] = 12;
        erc721s[0] = IBox.ERC721TokenInfos({addr: address(erc721Mock1), ids: ids721});
        ids721_2[0] = 21;
        erc721s[1] = IBox.ERC721TokenInfos({addr: address(erc721Mock2), ids: ids721_2});


        erc20s[0] = IBox.ERC20TokenInfos({addr: address(erc20Mock), amount: 200});
        erc20s[1] = IBox.ERC20TokenInfos({addr: address(erc20Mock2), amount: 150});

    
        amounts[0] = 100;
        erc1155s[0] = IBox.ERC1155TokenInfos({addr: address(erc1155Mock1), ids: ids, amounts: amounts});


        // check treasure
        checkTreasure(
            cryptoTreasure,
            treasureId,
            700,
            erc20s,
            erc721s,
            notErc721s,
            erc1155s
        );

        // check balances
        assertEq(address(cryptoTreasure).balance, 700);
        assertEq(address(4).balance, 300);

        assertEq(erc20Mock.balanceOf(address(cryptoTreasure)), 200);
        assertEq(erc20Mock.balanceOf(address(4)), 800);

        assertEq(erc20Mock2.balanceOf(address(cryptoTreasure)), 150);
        assertEq(erc20Mock2.balanceOf(address(4)), 50);

        assertEq(erc721Mock1.ownerOf(11), address(4));
        assertEq(erc721Mock1.ownerOf(12), address(cryptoTreasure));

        assertEq(erc721Mock1.balanceOf(address(cryptoTreasure)), 1);
        assertEq(erc721Mock1.balanceOf(address(4)), 1);
        
        assertEq(erc721Mock2.ownerOf(21), address(cryptoTreasure));
        assertEq(erc721Mock2.ownerOf(22), address(4));
        assertEq(erc721Mock2.balanceOf(address(cryptoTreasure)), 1);
        assertEq(erc721Mock2.balanceOf(address(4)), 1);

        assertEq(erc1155Mock1.balanceOf(address(4), 111), 23);
        assertEq(erc1155Mock1.balanceOf(address(cryptoTreasure), 111), 100);
     
    }

    function testDestroyCollateralized() public {

        // collateralized type
        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(amountToLock2), uint256(durationLockDestroy), uint256(mintingDurationLock), uint256(numberReserved));
        cryptoTreasure.addType(typeId2, from2, to2, data);

        vm.prank(address(1));
        erc20Mock.approve(address(cryptoTreasure), 30000);

        vm.prank(address(1));
        cryptoTreasure.safeMint(
            address(1),
            treasureId2,
            abi.encodePacked(typeId2, uint8(0))
        );

        // set up withdraw
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // destroy
        vm.prank(address(1));
        // vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        // emit Withdraw(treasureId2, value, erc20s, erc721s, erc1155s, address(4));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit Destroyed(treasureId2);
        cryptoTreasure.destroy(treasureId2, value, erc20s, erc721s, erc1155s, payable(address(4)));

        assertEq(cryptoTreasure.destroyedBoxes(treasureId2), true);

        // release the token to the righ address
        assertEq(erc20Mock.balanceOf(address(cryptoTreasure)), 1000);
        assertEq(erc20Mock.balanceOf(address(4)), 0);
        assertEq(erc20Mock.balanceOf(address(1)), 100000000000000-1000);
    }

    function testDestroyAlreadyDestroyed() public {
        // set up withdraw
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // destroy
        vm.prank(address(1));
        // vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        // emit Withdraw(treasureId, value, erc20s, erc721s, erc1155s, address(4));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit Destroyed(treasureId);
        cryptoTreasure.destroy(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        assertEq(cryptoTreasure.destroyedBoxes(treasureId), true);

        vm.prank(address(1));
        vm.expectRevert(bytes("e3"));
        cryptoTreasure.destroy(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));
    }


    function testStoreAlreadyDestroyed() public {
        // set up withdraw
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // destroy
        vm.prank(address(1));
        // vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        // emit Withdraw(treasureId, value, erc20s, erc721s, erc1155s, address(4));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit Destroyed(treasureId);
        cryptoTreasure.destroy(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        assertEq(cryptoTreasure.destroyedBoxes(treasureId), true);

        vm.prank(address(1));
        vm.expectRevert(bytes("e3"));
        cryptoTreasure.store{value:value}(treasureId, erc20s, erc721s, erc1155s);
    }

    function testWithdrawOnDestroyed() public {
        // set up withdraw
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // destroy
        vm.prank(address(1));
        // vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        // emit Withdraw(treasureId, value, erc20s, erc721s, erc1155s, address(4));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit Destroyed(treasureId);
        cryptoTreasure.destroy(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        assertEq(cryptoTreasure.destroyedBoxes(treasureId), true);

        // set up withdraw
        value = 1000;
        erc20s = new IBox.ERC20TokenInfos[](2);
        erc20s[0] = IBox.ERC20TokenInfos({addr: address(erc20Mock), amount: 1000});
        erc20s[1] = IBox.ERC20TokenInfos({addr: address(erc20Mock2), amount: 200});

        erc721s= new IBox.ERC721TokenInfos[](2);
        uint256[] memory ids721 = new uint256[](2);
        ids721[0] = 11; ids721[1] = 12;
        erc721s[0] = IBox.ERC721TokenInfos({addr: address(erc721Mock1), ids: ids721});
        
        uint256[] memory ids721_2 = new uint256[](2);
        ids721_2[0] = 21; ids721_2[1] = 22;
        erc721s[1] = IBox.ERC721TokenInfos({addr: address(erc721Mock2), ids: ids721_2});

        erc1155s= new IBox.ERC1155TokenInfos[](1);
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 111; amounts[0] = 123;
        erc1155s[0] = IBox.ERC1155TokenInfos({addr: address(erc1155Mock1), ids: ids, amounts: amounts});

        // withdraw
        vm.prank(address(1));
        cryptoTreasure.withdraw(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        // set up for treasure check:
        IBox.ERC721TokenInfos[] memory notErc721s= new IBox.ERC721TokenInfos[](2);
        notErc721s[0] = IBox.ERC721TokenInfos({addr: address(erc721Mock1), ids: ids721});
        notErc721s[1] = IBox.ERC721TokenInfos({addr: address(erc721Mock2), ids: ids721_2});

        erc20s[0] = IBox.ERC20TokenInfos({addr: address(erc20Mock), amount: 0});
        erc20s[1] = IBox.ERC20TokenInfos({addr: address(erc20Mock2), amount: 0});

        erc721s = new IBox.ERC721TokenInfos[](0);
    
        amounts[0] = 0;
        erc1155s[0] = IBox.ERC1155TokenInfos({addr: address(erc1155Mock1), ids: ids, amounts: amounts});


        // check treasure
        checkTreasure(
            cryptoTreasure,
            treasureId,
            0,
            erc20s,
            erc721s,
            notErc721s,
            erc1155s
        );

        // check balances
        assertEq(address(cryptoTreasure).balance, 0);
        assertEq(address(4).balance, value);

        assertEq(erc20Mock.balanceOf(address(cryptoTreasure)), 0);
        assertEq(erc20Mock.balanceOf(address(4)), 1000);

        assertEq(erc20Mock2.balanceOf(address(cryptoTreasure)), 0);
        assertEq(erc20Mock2.balanceOf(address(4)), 200);

        assertEq(erc721Mock1.ownerOf(11), address(4));
        assertEq(erc721Mock1.ownerOf(12), address(4));

        assertEq(erc721Mock1.balanceOf(address(cryptoTreasure)), 0);
        assertEq(erc721Mock1.balanceOf(address(4)), 2);
        
        assertEq(erc721Mock2.ownerOf(21), address(4));
        assertEq(erc721Mock2.ownerOf(22), address(4));
        assertEq(erc721Mock2.balanceOf(address(cryptoTreasure)), 0);
        assertEq(erc721Mock2.balanceOf(address(4)), 2);

        assertEq(erc1155Mock1.balanceOf(address(4), 111), 123);
        assertEq(erc1155Mock1.balanceOf(address(cryptoTreasure), 111), 0);
    }

    function testDestroySomeonelse() public {
        // set up withdraw
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // destroy
        vm.prank(address(4));
        vm.expectRevert(bytes("e4"));
        cryptoTreasure.destroy(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));
    }

    function testDestroyWithTimeLock() public {
        // collateralized type
        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(amountToLock), uint256(3), uint256(mintingDurationLock), uint256(numberReserved));
        cryptoTreasure.addType(typeId2, from2, to2, data);

        vm.prank(address(1));
        erc20Mock.approve(address(cryptoTreasure), 30000);

        vm.prank(address(1));
        cryptoTreasure.safeMint(
            address(1),
            treasureId2,
            abi.encodePacked(typeId2, uint8(0))
        );

        // set up withdraw
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // destroy
        vm.prank(address(1));
        vm.expectRevert(bytes("e17"));
        cryptoTreasure.destroy(treasureId2, value, erc20s, erc721s, erc1155s, payable(address(4)));

        vm.warp(block.timestamp+4);
        
        // destroy
        vm.prank(address(1));
        // vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        // emit Withdraw(treasureId, value, erc20s, erc721s, erc1155s, address(4));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit Destroyed(treasureId);
        cryptoTreasure.destroy(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        assertEq(cryptoTreasure.destroyedBoxes(treasureId), true);

    }

    function testDestroyWithTimeLockMintByType() public {
        // collateralized type
        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(amountToLock), uint256(3), uint256(mintingDurationLock), uint256(numberReserved));
        cryptoTreasure.addType(typeId2, from2, to2, data);

        vm.prank(address(1));
        erc20Mock.approve(address(cryptoTreasure), 30000);

        vm.prank(address(1));
        cryptoTreasure.safeMintByType(
            address(1),
            typeId2,
            abi.encodePacked(bytes1(0))
        );

        // set up withdraw
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // destroy
        vm.prank(address(1));
        vm.expectRevert(bytes("e17"));
        cryptoTreasure.destroy(treasureId2, value, erc20s, erc721s, erc1155s, payable(address(4)));

        vm.warp(block.timestamp+4);
        
        // destroy
        vm.prank(address(1));
        // vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        // emit Withdraw(treasureId, value, erc20s, erc721s, erc1155s, address(4));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit Destroyed(treasureId);
        cryptoTreasure.destroy(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        assertEq(cryptoTreasure.destroyedBoxes(treasureId), true);

    }


    function testDestroyWithTimeLockBatchMintByType() public {
        // collateralized type
        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(amountToLock), uint256(3), uint256(mintingDurationLock), uint256(numberReserved));
        cryptoTreasure.addType(typeId2, from2, to2, data);

        erc20Mock.approve(address(cryptoTreasure), 30000);
        
        address[] memory addresses = new address[](3);
        addresses[0]= address(1);
        addresses[1]= address(2);
        addresses[2]= address(3);

        cryptoTreasure.safeBatchMintByType(
            addresses,
            typeId2,
            abi.encodePacked(bytes1(0))
        );

        // set up withdraw
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // destroy
        vm.prank(address(1));
        vm.expectRevert(bytes("e17"));
        cryptoTreasure.destroy(treasureId2, value, erc20s, erc721s, erc1155s, payable(address(4)));

        vm.warp(block.timestamp+4);
        
        // destroy
        vm.prank(address(1));
        // vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        // emit Withdraw(treasureId, value, erc20s, erc721s, erc1155s, address(4));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit Destroyed(treasureId);
        cryptoTreasure.destroy(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        assertEq(cryptoTreasure.destroyedBoxes(treasureId), true);

    }
}
