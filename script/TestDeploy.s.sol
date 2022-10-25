// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/CryptoTreasure.sol";
import "../src/BoxBase.sol";

import "../src/test/ERC20PausableMock.sol";
import "../src/test/ERC721PausableMock.sol";
import "../src/test/ERC1155Mock.sol";
import "../src/erc20keys/ERC20Key.sol";

contract DeployTestEnv is Script {

    function run() external {
        address admin = vm.envAddress("ADMIN_PUB");
        address user1 = vm.envAddress("USER1_PUB");
        address user2 = vm.envAddress("USER2_PUB");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        BoxBase boxBase = new BoxBase();
        CryptoTreasure cryptoTreasure = new CryptoTreasure(address(boxBase));


        ERC20PausableMock reqToken = new ERC20PausableMock(
            "REQ",
            "REQ",
            admin,
            1000000000000000000000000000000000);
        ERC20PausableMock daiToken = new ERC20PausableMock(
            "DAI",
            "DAI",
            admin,
            1000000000000000000000000000000000);
        ERC721PausableMock meebits = new ERC721PausableMock("MEEBITS", "MEEBITS");
        ERC721PausableMock cryptoPunk = new ERC721PausableMock("CRYPTPUNKS", "CRYPTPUNKS");
        ERC1155Mock erc1155Mock1 = new ERC1155Mock();
        ERC1155Mock erc1155Mock2 = new ERC1155Mock();

        ERC20Key erc20key = new ERC20Key(address(cryptoTreasure));

        // mint tokens
        reqToken.transfer(user1, 100000000000000000000000000000);
        reqToken.transfer(user2, 100000000000000000000000000000);
        daiToken.transfer(user1, 100000000000000000000000000000);
        daiToken.transfer(user2, 100000000000000000000000000000);

        cryptoPunk.mint(user1, 1);
        cryptoPunk.mint(user1, 2);
        cryptoPunk.mint(user1, 3);
        cryptoPunk.mint(user1, 4);
        cryptoPunk.mint(user2, 5);
        cryptoPunk.mint(user2, 6);
        cryptoPunk.mint(user2, 7);
        cryptoPunk.mint(user2, 8);

        meebits.mint(user1, 10);
        meebits.mint(user1, 11);
        meebits.mint(user1, 12);
        meebits.mint(user1, 13);
        meebits.mint(user2, 14);
        meebits.mint(user2, 15);
        meebits.mint(user2, 16);
        meebits.mint(user2, 17);

        erc1155Mock1.mintBatch(user1, [111, 112], [1000, 2000]);
        erc1155Mock1.mintBatch(user2, [113, 114], [3000, 4000]);

        erc1155Mock2.mintBatch(user1, [221, 222], [1000, 2000]);
        erc1155Mock2.mintBatch(user2, [223, 224], [3000, 4000]);

        // add some treasure types
        bytes memory data = abi.encodePacked(address(0), uint256(0), uint256(300), uint256(0), uint256(0));
        cryptoTreasure.addType(
            1,
            10,
            999,
            data
        );

        data = abi.encodePacked(address(reqToken), uint256(1000000000000000000), uint256(300), uint256(0), uint256(0));
        cryptoTreasure.addType(
            2,
            1000,
            9999,
            data
        );

        data = abi.encodePacked(address(0), uint256(0), uint256(0), uint256(0), uint256(0));
        cryptoTreasure.addType(
            3,
            10000,
            99999,
            data
        );

        data = abi.encodePacked(address(erc20key), uint256(1), uint256(60*5), uint256(0), uint256(50));
        cryptoTreasure.addType(
            4,
            100000,
            999999,
            data
        );


        vm.stopBroadcast();
    }
}
