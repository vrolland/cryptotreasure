const { addTypeParamToBytes, mintParamToBytes } = require("../utils");
const { expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { ethers } = require("ethers");

const BoxBase = artifacts.require("BoxBase");
const CryptoTreasure = artifacts.require("CryptoTreasure");
const ERC20PausableMock = artifacts.require("ERC20PausableMock");

async function checkType(
  cryptoTreasure,
  id,
  from,
  to,
  data,
  erc20address,
  amount,
  destroyDuration,
  lastIdNotReserved
) {
  const newType = await cryptoTreasure._types(id);
  expect(newType.from.toString()).to.equal(from);
  expect(newType.to.toString()).to.equal(to);
  expect(newType.data.toString()).to.equal(data);

  expect(
    (await cryptoTreasure._lockedDestructionDuration(id)).toString()
  ).to.equal(destroyDuration.toString());
  const erc20ToLock = await cryptoTreasure._erc20ToLock(id);

  expect((await cryptoTreasure._lastIdNotReserved(id)).toString()).to.equal(
    lastIdNotReserved.toString()
  );

  expect(erc20ToLock.addr.toString()).to.equal(erc20address);
  expect(erc20ToLock.amount.toString()).to.equal(amount.toString());
}

contract("CryptoTreasure administration", (accounts) => {
  let cryptoTreasure;
  let reqTokenMock;

  beforeEach(async () => {
    reqTokenMock = await ERC20PausableMock.new(
      "ReqMock",
      "REQM",
      accounts[0],
      "100000000000000"
    );
    const boxBase = await BoxBase.new();
    cryptoTreasure = await CryptoTreasure.new(boxBase.address);
  });

  describe("addType", async () => {
    it("cannot addType if not owner", async () => {
      const id = "1";
      const from = "10";
      const to = "99";

      const data = addTypeParamToBytes(reqTokenMock.address, "1000", 0);
      await expectRevert(
        cryptoTreasure.addType(id, from, to, data, { from: accounts[1] }),
        `AccessControl: account ${accounts[1].toLowerCase()} is missing role 0x0000000000000000000000000000000000000000000000000000000000000000`
      );
    });

    it("cannot addType if from >= to", async () => {
      const id = "1";
      let from = "100";
      const to = "99";
      const data = addTypeParamToBytes(reqTokenMock.address, "1000", 0);
      await expectRevert(
        cryptoTreasure.addType(id, from, to, data, { from: accounts[0] }),
        "e14"
      );

      from = "99";
      await expectRevert(
        cryptoTreasure.addType(id, from, to, data, { from: accounts[0] }),
        "e14"
      );
    });

    it("cannot addType if numberReserved > to - from", async () => {
      const id = "1";
      const from = "0";
      const to = "99";
      const data = addTypeParamToBytes(
        reqTokenMock.address,
        "1000",
        0,
        30,
        101
      );
      await expectRevert(
        cryptoTreasure.addType(id, from, to, data, { from: accounts[0] }),
        "e21"
      );
    });

    it("can add one type", async () => {
      const id = "1";
      const from = "10";
      const to = "99";

      const data = addTypeParamToBytes(reqTokenMock.address, "1000", 0, 0, 30);
      const receipt = await cryptoTreasure.addType(id, from, to, data, {
        from: accounts[0],
      });

      await expectEvent(receipt, "NewType", {
        id,
        from,
        to,
        data,
      });
      await checkType(
        cryptoTreasure,
        id,
        from,
        to,
        data,
        reqTokenMock.address,
        "1000",
        0,
        "69"
      );
    });

    it("can add one type reverving all the tokens", async () => {
      const id = "1";
      const from = "10";
      const to = "99";

      const data = addTypeParamToBytes(reqTokenMock.address, "1000", 0, 0, 90);
      const receipt = await cryptoTreasure.addType(id, from, to, data, {
        from: accounts[0],
      });

      await expectEvent(receipt, "NewType", {
        id,
        from,
        to,
        data,
      });
      await checkType(
        cryptoTreasure,
        id,
        from,
        to,
        data,
        reqTokenMock.address,
        "1000",
        0,
        "9"
      );
    });

    it("cannot addType already existing", async () => {
      const id = 1;
      const from = 10;
      const to = 99;
      const data = addTypeParamToBytes(reqTokenMock.address, "1000", 0);
      await cryptoTreasure.addType(id, from, to, data, { from: accounts[0] });
      await expectRevert(
        cryptoTreasure.addType(id, from, to, data, { from: accounts[0] }),
        "e13"
      );
    });
  });

  describe("addTypes", async () => {
    it("cannot addTypes if not owner", async () => {
      const id = ["1", "2"];
      const from = ["10", "100"];
      const to = ["99", "999"];
      const data = [
        addTypeParamToBytes(reqTokenMock.address, "1000", 0),
        addTypeParamToBytes(reqTokenMock.address, "0", 0),
      ];
      await expectRevert(
        cryptoTreasure.addTypes(id, from, to, data, { from: accounts[1] }),
        `AccessControl: account ${accounts[1].toLowerCase()} is missing role 0x0000000000000000000000000000000000000000000000000000000000000000`
      );
    });

    it("cannot addType if from >= to", async () => {
      const id = ["1", "2"];
      const from = ["100", "100"];
      const to = ["99", "999"];
      const data = [
        addTypeParamToBytes(reqTokenMock.address, "1000", 0),
        addTypeParamToBytes(reqTokenMock.address, "0", 0),
      ];
      await expectRevert(
        cryptoTreasure.addTypes(id, from, to, data, { from: accounts[0] }),
        "e14"
      );

      from[0] = "99";
      await expectRevert(
        cryptoTreasure.addTypes(id, from, to, data, { from: accounts[0] }),
        "e14"
      );
    });

    it("can add two types", async () => {
      const id = ["1", "2"];
      const from = ["10", "100"];
      const to = ["99", "999"];
      const data = [
        addTypeParamToBytes(reqTokenMock.address, "1000", 0),
        addTypeParamToBytes(reqTokenMock.address, "0", 0),
      ];
      const receipt = await cryptoTreasure.addTypes(id, from, to, data, {
        from: accounts[0],
      });

      expect(receipt.logs.length).to.equal(2, "should have 2 events");
      await expectEvent(receipt, "NewType", {
        id: id[0],
        from: from[0],
        to: to[0],
        data: data[0],
      });
      await expectEvent(receipt, "NewType", {
        id: id[1],
        from: from[1],
        to: to[1],
        data: data[1],
      });
      await checkType(
        cryptoTreasure,
        id[0],
        from[0],
        to[0],
        data[0],
        reqTokenMock.address,
        "1000",
        0,
        "99"
      );
      await checkType(
        cryptoTreasure,
        id[1],
        from[1],
        to[1],
        data[1],
        reqTokenMock.address,
        "0",
        0,
        "999"
      );
    });

    it("cannot addType already existing", async () => {
      const id = ["1", "2"];
      const from = ["10", "100"];
      const to = ["99", "999"];
      const data = [
        addTypeParamToBytes(reqTokenMock.address, "1000", 0),
        addTypeParamToBytes(reqTokenMock.address, "0", 0),
      ];
      await cryptoTreasure.addType(id[0], from[0], to[0], data[0], {
        from: accounts[0],
      });
      await expectRevert(
        cryptoTreasure.addTypes(id, from, to, data, { from: accounts[0] }),
        "e13"
      );
    });
  });

  describe("updateBaseURI", async () => {
    it("cannot updateBaseURI if not owner", async () => {
      const baseURI = "http://127.0.0.1/";
      await expectRevert(
        cryptoTreasure.updateBaseURI(baseURI, { from: accounts[1] }),
        `AccessControl: account ${accounts[1].toLowerCase()} is missing role 0x0000000000000000000000000000000000000000000000000000000000000000`
      );
    });
    it("can updateBaseURI", async () => {
      const baseURI = "http://127.0.0.1/";
      cryptoTreasure.updateBaseURI(baseURI, { from: accounts[0] });
      cryptoTreasure.updateBaseURI(baseURI, { from: accounts[0] });

      await cryptoTreasure.addType(1, 1, 10, addTypeParamToBytes(), {
        from: accounts[0],
      });
      await cryptoTreasure.safeMint(accounts[0], 1, mintParamToBytes(1, 0), {
        from: accounts[0],
      });

      const tokenURI = await cryptoTreasure.tokenURI(1);
      expect(tokenURI).to.equal("http://127.0.0.1/1");
    });
  });
});
