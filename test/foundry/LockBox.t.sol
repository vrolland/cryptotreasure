// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/CryptoTreasure.sol";
import "contracts/BoxBase.sol";
import "contracts/IBox.sol";
import "contracts/test/ERC20PausableMock.sol";
import "contracts/test/ERC721PausableMock.sol";
import "contracts/test/ERC1155Mock.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./utils.t.sol";


contract LockBoxTest is TestTreasture {
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

    uint256 public lockTimeSpan = 3;

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

    event BoxLocked(uint256 indexed boxId, uint256 unlockTimestamp);

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

    function testLockBox() public {
        uint256 unlockTimestamp = block.timestamp + lockTimeSpan;
        // destroy
        vm.prank(address(1));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit BoxLocked(treasureId, unlockTimestamp);
        cryptoTreasure.lockBox(treasureId, unlockTimestamp);

        assertEq(cryptoTreasure._unlockTimestamp(treasureId), unlockTimestamp);
    }

    function testStoreOnLockedBox() public {
        uint256 unlockTimestamp = block.timestamp + lockTimeSpan;
        // destroy
        vm.prank(address(1));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit BoxLocked(treasureId, unlockTimestamp);
        cryptoTreasure.lockBox(treasureId, unlockTimestamp);

        assertEq(cryptoTreasure._unlockTimestamp(treasureId), unlockTimestamp);


        uint256 value = 1000;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // store
        vm.prank(address(1));
        vm.expectRevert(bytes("e8"));
        cryptoTreasure.store{value:value}(treasureId, erc20s, erc721s, erc1155s);
    }

    function testWithdrawOnLockedBox() public {
        uint256 unlockTimestamp = block.timestamp + lockTimeSpan;
        // destroy
        vm.prank(address(1));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit BoxLocked(treasureId, unlockTimestamp);
        cryptoTreasure.lockBox(treasureId, unlockTimestamp);

        assertEq(cryptoTreasure._unlockTimestamp(treasureId), unlockTimestamp);


        uint256 value = 1000;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // store
        vm.prank(address(1));
        vm.expectRevert(bytes("e8"));
        cryptoTreasure.withdraw(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        // vm.wrap(unlockTimestamp);
        vm.warp(block.timestamp+lockTimeSpan);

        vm.prank(address(1));
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Withdraw(treasureId, value, erc20s, erc721s, erc1155s, address(4));
        cryptoTreasure.withdraw(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));
    }

    function testDestroyOnLockedBox() public {
        uint256 unlockTimestamp = block.timestamp + lockTimeSpan;
        // destroy
        vm.prank(address(1));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit BoxLocked(treasureId, unlockTimestamp);
        cryptoTreasure.lockBox(treasureId, unlockTimestamp);

        assertEq(cryptoTreasure._unlockTimestamp(treasureId), unlockTimestamp);


        uint256 value = 1000;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // store
        vm.prank(address(1));
        vm.expectRevert(bytes("e8"));
        cryptoTreasure.destroy(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));
    }

    function testTransferBetweenBoxesOnLockedBox() public {
        uint256 unlockTimestamp = block.timestamp + lockTimeSpan;
        // destroy
        vm.prank(address(1));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit BoxLocked(treasureId, unlockTimestamp);
        cryptoTreasure.lockBox(treasureId, unlockTimestamp);

        assertEq(cryptoTreasure._unlockTimestamp(treasureId), unlockTimestamp);


        cryptoTreasure.safeMint(
            address(1),
            12,
            abi.encodePacked(typeId, uint8(0))
        );

        uint256 value = 1000;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // store
        vm.prank(address(1));
        vm.expectRevert(bytes("e8"));
        cryptoTreasure.transferBetweenBoxes(treasureId, 12, value, erc20s, erc721s, erc1155s);
    }
    
    function testLockBoxOnLockedBox() public {
        uint256 unlockTimestamp = block.timestamp + lockTimeSpan;
        // destroy
        vm.prank(address(1));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit BoxLocked(treasureId, unlockTimestamp);
        cryptoTreasure.lockBox(treasureId, unlockTimestamp);

        assertEq(cryptoTreasure._unlockTimestamp(treasureId), unlockTimestamp);

        // store
        vm.prank(address(1));
        vm.expectRevert(bytes("e8"));
        cryptoTreasure.lockBox(treasureId, unlockTimestamp+100);
    }

    function testTransferOfLockedBox() public {
        uint256 unlockTimestamp = block.timestamp + lockTimeSpan;
        // destroy
        vm.prank(address(1));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit BoxLocked(treasureId, unlockTimestamp);
        cryptoTreasure.lockBox(treasureId, unlockTimestamp);

        assertEq(cryptoTreasure._unlockTimestamp(treasureId), unlockTimestamp);

        // store
        vm.prank(address(1));
        vm.expectEmit(true, true, false, false, address(cryptoTreasure));
        emit Transfer(address(1), address(4), treasureId);
        cryptoTreasure.transferFrom(address(1), address(4), treasureId);

        assertEq(cryptoTreasure.ownerOf(treasureId), address(4));
    }
}
