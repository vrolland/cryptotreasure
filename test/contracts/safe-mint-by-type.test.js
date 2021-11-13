const {
  addTypeParamToBytes,
  mintByTypeParamToBytes,
  mintParamToBytes,
} = require("../utils");

const { expectEvent, expectRevert, BN } = require("@openzeppelin/test-helpers");

const BoxBase = artifacts.require("BoxBase");
const CryptoTreasure = artifacts.require("CryptoTreasure");
const ERC20PausableMock = artifacts.require("ERC20PausableMock");

contract("CryptoTreasure safeMintByType", (accounts) => {
  let cryptoTreasure;
  let reqTokenMock;

  const typeFreeId = "1";
  const typeFreeFrom = "10";
  const typeFreeTo = "12";

  const typeReqLockId = "2";
  const typeReqLockFrom = "100";
  const typeReqLockTo = "199";
  const typeReqLockReqToLock = "100";

  const adminAccount = accounts[0];
  const noReqAccount = accounts[1];
  const reqHolderAccount = accounts[2];

  describe("safeMintByType without req token to lock", async () => {
    beforeEach(async () => {
      const boxBase = await BoxBase.new();
      cryptoTreasure = await CryptoTreasure.new(boxBase.address);
      await cryptoTreasure.addType(
        typeFreeId,
        typeFreeFrom,
        typeFreeTo,
        addTypeParamToBytes(),
        { from: adminAccount }
      );
    });

    it("can mint by type", async () => {
      let receipt = await cryptoTreasure.safeMintByType(
        noReqAccount,
        typeFreeId,
        mintByTypeParamToBytes(0),
        { from: noReqAccount }
      );
      await expectEvent(receipt, "Transfer", {
        from: "0x0000000000000000000000000000000000000000",
        to: noReqAccount,
        tokenId: "10",
      });
      const type = await cryptoTreasure._tokenTypes("10");
      expect(type.toString()).to.be.equal(typeFreeId);
      expect(await cryptoTreasure._storeRestrictedToOwnerAndApproval("10")).to
        .be.false;

      receipt = await cryptoTreasure.safeMintByType(
        noReqAccount,
        typeFreeId,
        mintByTypeParamToBytes(1),
        { from: noReqAccount }
      );
      await expectEvent(receipt, "Transfer", {
        from: "0x0000000000000000000000000000000000000000",
        to: noReqAccount,
        tokenId: "11",
      });
      expect(await cryptoTreasure._storeRestrictedToOwnerAndApproval("11")).to
        .be.true;

      receipt = await cryptoTreasure.safeMintByType(
        noReqAccount,
        typeFreeId,
        mintByTypeParamToBytes(1),
        { from: noReqAccount }
      );
      await expectEvent(receipt, "Transfer", {
        from: "0x0000000000000000000000000000000000000000",
        to: noReqAccount,
        tokenId: "12",
      });
      expect(await cryptoTreasure._storeRestrictedToOwnerAndApproval("12")).to
        .be.true;
    });

    it("can mint by type event if a token has been minted", async () => {
      await cryptoTreasure.safeMint(
        noReqAccount,
        "10",
        mintParamToBytes(typeFreeId, 1),
        { from: noReqAccount }
      );

      const receipt = await cryptoTreasure.safeMintByType(
        noReqAccount,
        typeFreeId,
        mintByTypeParamToBytes(1),
        { from: noReqAccount }
      );
      await expectEvent(receipt, "Transfer", {
        from: "0x0000000000000000000000000000000000000000",
        to: noReqAccount,
        tokenId: "11",
      });
    });

    it("cannot mint more then available", async () => {
      await cryptoTreasure.safeMint(
        noReqAccount,
        "10",
        mintParamToBytes(typeFreeId, 1),
        { from: noReqAccount }
      );
      await cryptoTreasure.safeMint(
        noReqAccount,
        "11",
        mintParamToBytes(typeFreeId, 1),
        { from: noReqAccount }
      );
      await cryptoTreasure.safeMint(
        noReqAccount,
        "12",
        mintParamToBytes(typeFreeId, 1),
        { from: noReqAccount }
      );

      await expectRevert(
        cryptoTreasure.safeMintByType(
          noReqAccount,
          typeFreeId,
          mintByTypeParamToBytes(0),
          { from: noReqAccount }
        ),
        "e18"
      );
    });

    it("can mint for someone else", async () => {
      const receipt = await cryptoTreasure.safeMintByType(
        noReqAccount,
        typeFreeId,
        mintByTypeParamToBytes(0),
        { from: reqHolderAccount }
      );

      await expectEvent(receipt, "Transfer", {
        from: "0x0000000000000000000000000000000000000000",
        to: noReqAccount,
        tokenId: "10",
      });
    });

    it("cannot mint treasure with a not existing type", async () => {
      await expectRevert(
        cryptoTreasure.safeMintByType(
          noReqAccount,
          "120",
          mintByTypeParamToBytes(0),
          { from: noReqAccount }
        ),
        "e10"
      );
    });

    it("cannot mint a reserved token", async () => {
      await cryptoTreasure.addType(
        "3",
        "1000",
        "1100",
        addTypeParamToBytes(0, 0, 0, 0, (numberReserved = 101)),
        { from: adminAccount }
      );
      await expectRevert(
        cryptoTreasure.safeMintByType(noReqAccount, "3", mintParamToBytes(0), {
          from: noReqAccount,
        }),
        "e22"
      );
    });
  });

  describe("safeMintByType with req token to lock", async () => {
    beforeEach(async () => {
      const boxBase = await BoxBase.new();
      reqTokenMock = await ERC20PausableMock.new(
        "ReqMock",
        "REQM",
        reqHolderAccount,
        "100"
      );
      cryptoTreasure = await CryptoTreasure.new(boxBase.address);
      await cryptoTreasure.addType(
        typeReqLockId,
        typeReqLockFrom,
        typeReqLockTo,
        addTypeParamToBytes(reqTokenMock.address, typeReqLockReqToLock, 0),
        { from: adminAccount }
      );
    });

    it("can mint", async () => {
      const treasureId = "100";

      await reqTokenMock.approve(cryptoTreasure.address, typeReqLockReqToLock, {
        from: reqHolderAccount,
      });
      const receipt = await cryptoTreasure.safeMintByType(
        reqHolderAccount,
        typeReqLockId,
        mintByTypeParamToBytes(0),
        { from: reqHolderAccount }
      );

      const type = await cryptoTreasure._tokenTypes(treasureId);
      expect(type.toString()).to.be.equal(typeReqLockId);

      await expectEvent.inTransaction(receipt.tx, cryptoTreasure, "Transfer", {
        from: "0x0000000000000000000000000000000000000000",
        to: reqHolderAccount,
        tokenId: treasureId,
      });
      await expectEvent.inTransaction(receipt.tx, reqTokenMock, "Transfer", {
        from: reqHolderAccount,
        to: cryptoTreasure.address,
        value: typeReqLockReqToLock,
      });
    });

    it("cannot mint treasure without enough req token approval", async () => {
      const treasureId = "100";
      await reqTokenMock.approve(cryptoTreasure.address, "99", {
        from: reqHolderAccount,
      });
      await expectRevert(
        cryptoTreasure.safeMintByType(
          reqHolderAccount,
          typeReqLockId,
          mintByTypeParamToBytes(0),
          { from: reqHolderAccount }
        ),
        "ERC20: transfer amount exceeds allowance"
      );
    });

    it("cannot mint treasure without enough req token", async () => {
      const treasureId = "100";
      await reqTokenMock.approve(cryptoTreasure.address, typeReqLockReqToLock, {
        from: reqHolderAccount,
      });
      await reqTokenMock.transfer(noReqAccount, "1", {
        from: reqHolderAccount,
      });

      await expectRevert(
        cryptoTreasure.safeMintByType(
          reqHolderAccount,
          typeReqLockId,
          mintByTypeParamToBytes(0),
          { from: reqHolderAccount }
        ),
        "ERC20: transfer amount exceeds balance"
      );
    });
  });
});
