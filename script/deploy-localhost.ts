import { ethers } from "hardhat";
import { addTypeParamToBytes } from "./utils"

async function main() {
  const signer = await ethers.getSigner();
  const admin = signer.address;
  const user1 = "0xf17f52151EbEF6C7334FAD080c5704D77216b732";
  const user2 = "0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef";

  const bigAmount = ethers.utils.parseEther("1000000000000000");

  const ERC20PausableMock = await ethers.getContractFactory("ERC20PausableMock");
  const reqToken = await ERC20PausableMock.deploy("REQ","REQ", admin, bigAmount);
  await reqToken.deployed();
  console.log(`reqToken deployed to ${reqToken.address}`);


  const BoxBase = await ethers.getContractFactory("BoxBase");
  const boxBase = await BoxBase.deploy(/*unboxBaseTime, { value: boxBaseedAmount }*/);
  await boxBase.deployed();
  console.log(`BoxBase deployed to ${boxBase.address}`);


  const CryptoTreasure = await ethers.getContractFactory("CryptoTreasure");
  const cryptoTreasure = await CryptoTreasure.deploy(boxBase.address);
  await cryptoTreasure.deployed();
  console.log(`cryptoTreasure deployed to ${cryptoTreasure.address}`);


  const daiToken = await ERC20PausableMock.deploy("DAI","DAI", admin, bigAmount);
  await daiToken.deployed();
  console.log(`daiToken deployed to ${daiToken.address}`);

  
  const ERC721PausableMock = await ethers.getContractFactory("ERC721PausableMock");
  const meebits = await ERC721PausableMock.deploy("MEEBITS","MEEBITS");
  await meebits.deployed();
  console.log(`meebits deployed to ${meebits.address}`);
  const cryptoPunk = await ERC721PausableMock.deploy("CRYPTOPUNKS","CRYPTOPUNKS");
  await cryptoPunk.deployed();
  console.log(`cryptoPunk deployed to ${cryptoPunk.address}`);


  const ERC1155Mock = await ethers.getContractFactory("ERC1155Mock");
  const erc1155Mock1 = await ERC1155Mock.deploy();
  await erc1155Mock1.deployed();
  console.log(`erc1155Mock1 deployed to ${erc1155Mock1.address}`);
  const erc1155Mock2 = await ERC1155Mock.deploy();
  await erc1155Mock2.deployed();
  console.log(`erc1155Mock2 deployed to ${erc1155Mock2.address}`);


  const ERC20Key = await ethers.getContractFactory("ERC20Key");
  const erc20key = await ERC20Key.deploy("KEY", "KEY", cryptoTreasure.address);
  await erc20key.deployed();
  console.log(`erc20key deployed to ${erc20key.address}`);

  await reqToken.transfer(user1, "100000000000000000000000000000");
  await reqToken.transfer(user2, "100000000000000000000000000000");
  await daiToken.transfer(user1, "100000000000000000000000000000");
  await daiToken.transfer(user2, "100000000000000000000000000000");

  await cryptoPunk.mint(user1, "1");
  await cryptoPunk.mint(user1, "2");
  await cryptoPunk.mint(user1, "3");
  await cryptoPunk.mint(user1, "4");
  await cryptoPunk.mint(user2, "5");
  await cryptoPunk.mint(user2, "6");
  await cryptoPunk.mint(user2, "7");
  await cryptoPunk.mint(user2, "8");

  await meebits.mint(user1, "10");
  await meebits.mint(user1, "11");
  await meebits.mint(user1, "12");
  await meebits.mint(user1, "13");
  await meebits.mint(user2, "14");
  await meebits.mint(user2, "15");
  await meebits.mint(user2, "16");
  await meebits.mint(user2, "17");

  await erc1155Mock1.mintBatch(user1, ["111", "112"], ["1000", "2000"]);
  await erc1155Mock1.mintBatch(user2, ["113", "114"], ["3000", "4000"]);

  await erc1155Mock2.mintBatch(user1, ["221", "222"], ["1000", "2000"]);
  await erc1155Mock2.mintBatch(user2, ["223", "224"], ["3000", "4000"]);


  await cryptoTreasure.addType(
    "1",
    "10",
    "999",
    addTypeParamToBytes("0", "0", "300")
  );
  await cryptoTreasure.addType(
    "2",
    "1000",
    "9999",
    addTypeParamToBytes(reqToken.address, ethers.utils.parseEther("1").toString(), "300")
  );
  await cryptoTreasure.addType(
    "3",
    "10000",
    "99999",
    addTypeParamToBytes()
  );
  await cryptoTreasure.addType(
    "4",
    "100000",
    "999999",
    addTypeParamToBytes(erc20key.address, "1", (60 * 5).toString(), "0", "50")
  );

  console.log(
    "#################################################################################################"
  );
  console.log("ACCOUNTS:");
  console.log(
    `admin: 0x627306090abaB3A6e1400e9345bC60c78a8BEf57 (0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3)`
  );
  console.log(
    `user 1: 0xf17f52151EbEF6C7334FAD080c5704D77216b732 (0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f)`
  );
  console.log(
    `user 2: 0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef (0x0dbbe8e4ae425a6d2687f1a7e3ba17bc98c673636790f1b8ad91193c05875ef1)`
  );
  console.log(
    "#################################################################################################"
  );
  console.log();
  console.log(
    "#################################################################################################"
  );
  console.log("ERC20 (mock):");
  console.log(`REQ: ${reqToken.address}`);
  console.log(`                - user1 ${await reqToken.balanceOf(user1)}`);
  console.log(`                - user2 ${await reqToken.balanceOf(user2)}`);
  console.log(`DAI: ${daiToken.address}`);
  console.log(`                - user1 ${await daiToken.balanceOf(user1)}`);
  console.log(`                - user2 ${await daiToken.balanceOf(user2)}`);
  console.log(
    "#################################################################################################"
  );
  console.log();
  console.log(
    "#################################################################################################"
  );
  console.log("ERC721 (mock):");
  console.log(`MEEBITS: ${meebits.address}`);
  console.log(`                - user1: [10, 11, 12, 13]`);
  console.log(`                - user2: [14, 15, 16, 17]`);
  console.log(`CRYPTPUNKS: ${cryptoPunk.address}`);
  console.log(`                - user1: [1, 2, 3, 4]`);
  console.log(`                - user2: [5, 6, 7, 8]`);
  console.log(
    "#################################################################################################"
  );
  console.log();
  console.log(
    "#################################################################################################"
  );
  console.log("ERC1155 (mock):");
  console.log(`mock1: ${erc1155Mock1.address}`);
  console.log(`                - user1: {'111': '1000', '112': '2000'}`);
  console.log(`                - user2: {'113': '3000', '114': '4000'}`);
  console.log(`mock2: ${erc1155Mock2.address}`);
  console.log(`                - user1: {'221': '1000', '222': '2000'}`);
  console.log(`                - user2: {'223': '3000', '224': '4000'}`);
  console.log(
    "#################################################################################################"
  );
  console.log();
  console.log(
    "#################################################################################################"
  );
  console.log(`Erc20key: ${erc20key.address}`);
  console.log();
  console.log(
    "#################################################################################################"
  );
  console.log(`CryptoTreasure: ${cryptoTreasure.address}`);
  console.log(`                - free treasure: id 1 => [10, 999]`);
  console.log(`                - 1 REQ treasure: id 2 => [1000, 9999]`);
  console.log(
    `                - quick destroyable treasure: id 3 => [10000, 99999]`
  );
  console.log(`                - 1 Key treasure: id 2 => [100000, 999999]`);
  console.log(
    "#################################################################################################"
  );
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
