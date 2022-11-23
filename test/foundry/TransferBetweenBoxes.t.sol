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


contract TransferBetweenBoxesTest is TestTreasture {
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
    uint256 public treasureId2 = 12;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Store(
        uint256 indexed boxId,
        uint256 ethAmount,
        IBox.ERC20TokenInfos[] erc20s,
        IBox.ERC721TokenInfos[] erc721s,
        IBox.ERC1155TokenInfos[] erc1155s
    );

    event TransferBetweenBoxes(
        uint256 indexed srcBoxId,
        uint256 indexed destBoxId,
        uint256 ethAmount,
        IBox.ERC20TokenInfos[] erc20s,
        IBox.ERC721TokenInfos[] erc721s,
        IBox.ERC1155TokenInfos[] erc1155s
    );

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

        bytes memory data = abi.encodePacked(address(erc20Mock), uint256(amountToLock), uint256(durationLockDestroy), uint256(mintingDurationLock), uint256(numberReserved));
        cryptoTreasure.addType(typeId, from, to, data);

        cryptoTreasure.safeMint(
            address(1),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );

        cryptoTreasure.safeMint(
            address(4),
            treasureId2,
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


    function testTransfer() public {
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


        // transfer
        vm.prank(address(1));
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit TransferBetweenBoxes(treasureId, treasureId2, value, erc20s, erc721s, erc1155s);
        cryptoTreasure.transferBetweenBoxes(treasureId, treasureId2, value, erc20s, erc721s, erc1155s);


        IBox.ERC721TokenInfos[] memory notErc721s= new IBox.ERC721TokenInfos[](0);
        checkTreasure(
            cryptoTreasure,
            treasureId2,
            value,
            erc20s,
            erc721s,
            notErc721s,
            erc1155s
        );


        // set up for treasure check:
        notErc721s= new IBox.ERC721TokenInfos[](2);
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
        assertEq(address(cryptoTreasure).balance, value);

        assertEq(erc20Mock.balanceOf(address(cryptoTreasure)), 1000);

        assertEq(erc20Mock2.balanceOf(address(cryptoTreasure)), 200);

        assertEq(erc721Mock1.ownerOf(11), address(cryptoTreasure));
        assertEq(erc721Mock1.ownerOf(12), address(cryptoTreasure));

        assertEq(erc721Mock1.balanceOf(address(cryptoTreasure)), 2);
        
        assertEq(erc721Mock2.ownerOf(21), address(cryptoTreasure));
        assertEq(erc721Mock2.ownerOf(22), address(cryptoTreasure));
        assertEq(erc721Mock2.balanceOf(address(cryptoTreasure)), 2);

        assertEq(erc1155Mock1.balanceOf(address(cryptoTreasure), 111), 123);
     
    }


    function testTransferToNotMintedBox() public {
        uint256 value = 600;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // withdraw
        vm.prank(address(1));
        vm.expectRevert(bytes("e15"));
        cryptoTreasure.transferBetweenBoxes(treasureId, 13, value, erc20s, erc721s, erc1155s);

    }

    function testTransferEthAlreadyDone() public {
        uint256 value = 600;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        vm.prank(address(1));
        cryptoTreasure.withdraw(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        // withdraw
        vm.prank(address(1));
        vm.expectRevert(bytes("e23"));
        cryptoTreasure.transferBetweenBoxes(treasureId, treasureId2, value, erc20s, erc721s, erc1155s);

    }

    function testTransferErc20AlreadyDone() public {
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](1);
        erc20s[0] = IBox.ERC20TokenInfos({addr: address(erc20Mock), amount: 800});
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        vm.prank(address(1));
        cryptoTreasure.withdraw(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        // withdraw
        vm.prank(address(1));
        vm.expectRevert(bytes("e23"));
        cryptoTreasure.transferBetweenBoxes(treasureId, treasureId2, value, erc20s, erc721s, erc1155s);
    }

    function testTransferErc721AlreadyDone() public {
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](1);
        uint256[] memory ids721 = new uint256[](1);
        ids721[0] = 11;
        erc721s[0] = IBox.ERC721TokenInfos({addr: address(erc721Mock1), ids: ids721});
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        vm.prank(address(1));
        cryptoTreasure.withdraw(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        // withdraw
        vm.prank(address(1));
        vm.expectRevert(bytes("e23"));
        cryptoTreasure.transferBetweenBoxes(treasureId, treasureId2, value, erc20s, erc721s, erc1155s);
    }

    function testTransferErc1155AlreadyDone() public {
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](1);
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 111; amounts[0] = 80;
        erc1155s[0] = IBox.ERC1155TokenInfos({addr: address(erc1155Mock1), ids: ids, amounts: amounts});

        vm.prank(address(1));
        cryptoTreasure.withdraw(treasureId, value, erc20s, erc721s, erc1155s, payable(address(4)));

        // withdraw
        vm.prank(address(1));
        vm.expectRevert(bytes("e23"));
        cryptoTreasure.transferBetweenBoxes(treasureId, treasureId2, value, erc20s, erc721s, erc1155s);
    }

    function testTransferSomeoneElse() public {
        uint256 value = 600;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // withdraw
        vm.prank(address(2));
        vm.expectRevert(bytes("e4"));
        cryptoTreasure.transferBetweenBoxes(treasureId, treasureId2, value, erc20s, erc721s, erc1155s);
    }

    function testTransferErc20OnContractButNotOnTreasure() public {
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](1);
        erc20s[0] = IBox.ERC20TokenInfos({addr: address(erc20Mock), amount: 800});
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // withdraw
        vm.prank(address(4));
        vm.expectRevert(bytes("e23"));
        cryptoTreasure.transferBetweenBoxes(treasureId2, treasureId, value, erc20s, erc721s, erc1155s);
    }


    function testTransferErc721OnContractButNotOnTreasure() public {
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](1);
        uint256[] memory ids721 = new uint256[](1);
        ids721[0] = 11;
        erc721s[0] = IBox.ERC721TokenInfos({addr: address(erc721Mock1), ids: ids721});
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // withdraw
        vm.prank(address(4));
        vm.expectRevert(bytes("e23"));
        cryptoTreasure.transferBetweenBoxes(treasureId2, treasureId, value, erc20s, erc721s, erc1155s);
    }

    function testTransferErc1155OnContractButNotOnTreasure() public {
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](0);
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](1);
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 111; amounts[0] = 80;
        erc1155s[0] = IBox.ERC1155TokenInfos({addr: address(erc1155Mock1), ids: ids, amounts: amounts});

        // withdraw
        vm.prank(address(4));
        vm.expectRevert(bytes("e23"));
        cryptoTreasure.transferBetweenBoxes(treasureId2, treasureId, value, erc20s, erc721s, erc1155s);
    }

}
