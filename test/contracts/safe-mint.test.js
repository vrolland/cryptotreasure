const { addTypeParamToBytes, mintParamToBytes } = require("../utils");
const { sleep } = require("./utils");

const { expectEvent, expectRevert, BN } = require("@openzeppelin/test-helpers");

const BoxBase = artifacts.require("BoxBase");
const CryptoTreasure = artifacts.require("CryptoTreasure");
const ERC20PausableMock = artifacts.require("ERC20PausableMock");

contract("CryptoTreasure safeMint", (accounts) => {
  let cryptoTreasure;
  let reqTokenMock;

  const typeFreeId = "1";
  const typeFreeFrom = "10";
  const typeFreeTo = "99";

  const typeReqLockId = "2";
  const typeReqLockFrom = "100";
  const typeReqLockTo = "199";
  const typeReqLockReqToLock = "100";

  const adminAccount = accounts[0];
  const noReqAccount = accounts[1];
  const reqHolderAccount = accounts[2];

  describe("safeMint without req token to lock", async () => {
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

    it("can mint", async () => {
      const treasureId = "11";
      const receipt = await cryptoTreasure.safeMint(
        noReqAccount,
        treasureId,
        mintParamToBytes(typeFreeId, 0),
        { from: noReqAccount }
      );

      await expectEvent(receipt, "Transfer", {
        from: "0x0000000000000000000000000000000000000000",
        to: noReqAccount,
        tokenId: treasureId,
      });
    });

    it("cannot mint a reserved token", async () => {
      await cryptoTreasure.addType(
        "3",
        "1000",
        "1100",
        addTypeParamToBytes(0, 0, 0, 0, (numberReserved = 101)),
        { from: adminAccount }
      );
      const treasureId = "1000";
      await expectRevert(
        cryptoTreasure.safeMint(
          noReqAccount,
          treasureId,
          mintParamToBytes("3", 0),
          { from: noReqAccount }
        ),
        "e22"
      );
    });

    it("can mint for someone else", async () => {
      const treasureId = "11";
      const receipt = await cryptoTreasure.safeMint(
        noReqAccount,
        treasureId,
        mintParamToBytes(typeFreeId, 0),
        { from: accounts[2] }
      );

      await expectEvent(receipt, "Transfer", {
        from: "0x0000000000000000000000000000000000000000",
        to: noReqAccount,
        tokenId: treasureId,
      });
    });

    it("cannot mint treasure already minted", async () => {
      const treasureId = "11";
      await cryptoTreasure.safeMint(
        noReqAccount,
        treasureId,
        mintParamToBytes(typeFreeId, 0),
        { from: noReqAccount }
      );

      await expectRevert(
        cryptoTreasure.safeMint(
          noReqAccount,
          treasureId,
          mintParamToBytes(typeFreeId, 0),
          { from: noReqAccount }
        ),
        "ERC721: token already minted"
      );
    });

    it("cannot mint treasure with a not existing type", async () => {
      const treasureId = "11";
      await expectRevert(
        cryptoTreasure.safeMint(
          noReqAccount,
          treasureId,
          mintParamToBytes(typeReqLockId, 0),
          { from: noReqAccount }
        ),
        "e10"
      );
    });

    it("cannot mint treasure with type not matching id", async () => {
      const treasureIdToLow = "9";
      const treasureIdToHigh = "100";
      await expectRevert(
        cryptoTreasure.safeMint(
          noReqAccount,
          treasureIdToLow,
          mintParamToBytes(typeFreeId, 0),
          { from: noReqAccount }
        ),
        "e11"
      );
      await expectRevert(
        cryptoTreasure.safeMint(
          noReqAccount,
          treasureIdToHigh,
          mintParamToBytes(typeFreeId, 0),
          { from: noReqAccount }
        ),
        "e12"
      );
    });

    it("cannot mint treasure without type id", async () => {
      const treasureId = "11";
      await expectRevert(
        cryptoTreasure.safeMint(noReqAccount, treasureId, "0x", {
          from: noReqAccount,
        }),
        "e0"
      );
    });
  });

  describe("safeMint with req token to lock", async () => {
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
      const treasureId = "111";

      await reqTokenMock.approve(cryptoTreasure.address, typeReqLockReqToLock, {
        from: reqHolderAccount,
      });
      const receipt = await cryptoTreasure.safeMint(
        reqHolderAccount,
        treasureId,
        mintParamToBytes(typeReqLockId, 0),
        { from: reqHolderAccount }
      );

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

    it("can mint for someone else", async () => {
      const treasureId = "111";

      await reqTokenMock.approve(cryptoTreasure.address, typeReqLockReqToLock, {
        from: reqHolderAccount,
      });
      const receipt = await cryptoTreasure.safeMint(
        noReqAccount,
        treasureId,
        mintParamToBytes(typeReqLockId, 0),
        { from: reqHolderAccount }
      );

      await expectEvent.inTransaction(receipt.tx, cryptoTreasure, "Transfer", {
        from: "0x0000000000000000000000000000000000000000",
        to: noReqAccount,
        tokenId: treasureId,
      });
      await expectEvent.inTransaction(receipt.tx, reqTokenMock, "Transfer", {
        from: reqHolderAccount,
        to: cryptoTreasure.address,
        value: typeReqLockReqToLock,
      });
    });

    it("cannot mint treasure without enough req token approval", async () => {
      const treasureId = "111";
      await reqTokenMock.approve(cryptoTreasure.address, "99", {
        from: reqHolderAccount,
      });
      await expectRevert(
        cryptoTreasure.safeMint(
          reqHolderAccount,
          treasureId,
          mintParamToBytes(typeReqLockId, 0),
          { from: reqHolderAccount }
        ),
        "ERC20: transfer amount exceeds allowance"
      );
    });

    it("cannot mint treasure without enough req token", async () => {
      const treasureId = "111";
      await reqTokenMock.approve(cryptoTreasure.address, typeReqLockReqToLock, {
        from: reqHolderAccount,
      });
      await reqTokenMock.transfer(noReqAccount, "1", {
        from: reqHolderAccount,
      });

      await expectRevert(
        cryptoTreasure.safeMint(
          reqHolderAccount,
          treasureId,
          mintParamToBytes(typeReqLockId, 0),
          { from: reqHolderAccount }
        ),
        "ERC20: transfer amount exceeds balance"
      );
    });
  });

  describe("mint with time lock start mint", async () => {
    const treasureId = "11";
    const mintTimeLockDuration = "3"; // 3 sec
    beforeEach(async () => {
      const boxBase = await BoxBase.new();
      cryptoTreasure = await CryptoTreasure.new(boxBase.address);

      await cryptoTreasure.addType(
        typeFreeId,
        typeFreeFrom,
        typeFreeTo,
        addTypeParamToBytes(0, 0, 0, mintTimeLockDuration),
        { from: adminAccount }
      );
    });

    it("cannot mint too early", async () => {
      await expectRevert(
        cryptoTreasure.safeMint(
          reqHolderAccount,
          treasureId,
          mintParamToBytes(typeFreeId, 0),
          { from: reqHolderAccount }
        ),
        "e19"
      );
    });
    it("can mint after the mint", async () => {
      // Wait a bit...
      await sleep(3000);
      const receipt = await cryptoTreasure.safeMint(
        reqHolderAccount,
        treasureId,
        mintParamToBytes(typeFreeId, 0),
        { from: reqHolderAccount }
      );

      await expectEvent.inTransaction(receipt.tx, cryptoTreasure, "Transfer", {
        from: "0x0000000000000000000000000000000000000000",
        to: reqHolderAccount,
        tokenId: treasureId,
      });
    });
  });
});
