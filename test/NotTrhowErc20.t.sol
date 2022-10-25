// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CryptoTreasure.sol";
import "../src/BoxBase.sol";
import "../src/IBox.sol";
import "../src/test/ERC20NoThrowMock.sol";
import "./utils.t.sol";


contract NotThrowErc20Test is TestTreasture {
    ERC20NoThrowMock public erc20NotThrow;
    
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
    uint256 public treasureIdAttacker = 12;

    address public attacker = address(0xbad);
    address public victim = address(0x900d);

    uint256 public amount = 10000;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Store(
        uint256 indexed boxId,
        uint256 ethAmount,
        IBox.ERC20TokenInfos[] erc20s,
        IBox.ERC721TokenInfos[] erc721s,
        IBox.ERC1155TokenInfos[] erc1155s
    );

    function setUp() public {
        vm.deal(address(victim), 10000000000000000000);
        vm.deal(address(attacker), 10000000000000000000);

        erc20NotThrow = new ERC20NoThrowMock(
            "erc20NotThrow",
            "MOCK",
            address(victim),
            amount
        );
       
        boxBase = new BoxBase();
        cryptoTreasure = new CryptoTreasure(address(boxBase));
        bytes memory data = abi.encodePacked(address(0), uint256(amountToLock), uint256(durationLockDestroy), uint256(mintingDurationLock), uint256(numberReserved));
        cryptoTreasure.addType(typeId, from, to, data);

        cryptoTreasure.safeMint(
            address(victim),
            treasureId,
            abi.encodePacked(typeId, uint8(0))
        );


        // set up store
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](1);
        erc20s[0] = IBox.ERC20TokenInfos({addr: address(erc20NotThrow), amount: amount});
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // approve
        vm.prank(address(victim));
        erc20NotThrow.approve(address(cryptoTreasure), amount);

        // store
        vm.prank(address(victim));
        vm.expectEmit(true, true, true, true, address(cryptoTreasure));
        emit Store(treasureId, value, erc20s, erc721s, erc1155s);
        cryptoTreasure.store{value:value}(treasureId, erc20s, erc721s, erc1155s);

    }

    function testAttack() public {
        cryptoTreasure.safeMint(
            address(attacker),
            treasureIdAttacker,
            abi.encodePacked(typeId, uint8(0))
        );

        // set up store
        uint256 value = 0;
        IBox.ERC20TokenInfos[] memory erc20s = new IBox.ERC20TokenInfos[](1);
        erc20s[0] = IBox.ERC20TokenInfos({addr: address(erc20NotThrow), amount: amount});
        IBox.ERC721TokenInfos[] memory erc721s= new IBox.ERC721TokenInfos[](0);
        IBox.ERC1155TokenInfos[] memory erc1155s= new IBox.ERC1155TokenInfos[](0);

        // store
        vm.prank(address(attacker));
        vm.expectRevert(bytes("e23"));
        cryptoTreasure.store{value:value}(treasureIdAttacker, erc20s, erc721s, erc1155s);
    }

}
