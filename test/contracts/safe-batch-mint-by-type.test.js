const {
  addTypeParamToBytes,
  mintByTypeParamToBytes,
  mintParamToBytes,
} = require("../utils");

const { expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { BigNumber } = require("ethers");

const BoxBase = artifacts.require("BoxBase");
const CryptoTreasure = artifacts.require("CryptoTreasure");
const ERC20PausableMock = artifacts.require("ERC20PausableMock");

contract("CryptoTreasure safeBatchMintByType", (accounts) => {
  let cryptoTreasure;
  let reqTokenMock;

  const typeFreeId = "1";
  const typeFreeFrom = "10";
  const typeFreeTo = "100";

  const typeReqLockId = "2";
  const typeReqLockFrom = "100";
  const typeReqLockTo = "199";
  const typeReqLockReqToLock = "100";

  const adminAccount = accounts[0];
  const noReqAccount = accounts[1];
  const reqHolderAccount = accounts[2];

  describe("safeBatchMintByType without req token to lock", async () => {
    beforeEach(async () => {
      const boxBase = await BoxBase.new();
      cryptoTreasure = await CryptoTreasure.new(boxBase.address);
      await cryptoTreasure.addType(
        typeFreeId,
        typeFreeFrom,
        typeFreeTo,
        addTypeParamToBytes(0, 0, 0, 0, 50),
        { from: adminAccount }
      );
    });

    it("can batch mint by type", async () => {
      let receipt = await cryptoTreasure.safeBatchMintByType(
        accounts,
        typeFreeId,
        mintByTypeParamToBytes(0),
        { from: adminAccount }
      );
      let tokenId = BigNumber.from(10);
      for (acc of accounts) {
        await expectEvent(receipt, "Transfer", {
          from: "0x0000000000000000000000000000000000000000",
          to: acc,
          tokenId: tokenId.toString(),
        });
        expect(
          await cryptoTreasure._storeRestrictedToOwnerAndApproval(
            tokenId.toString()
          )
        ).to.be.false;

        const type = await cryptoTreasure._tokenTypes(tokenId);
        expect(type.toString()).to.be.equal(typeFreeId);

        tokenId = tokenId.add(1);
      }
    });

    it("can mint by type event if a token has been minted", async () => {
      await cryptoTreasure.safeMint(
        noReqAccount,
        "15",
        mintParamToBytes(typeFreeId, 1),
        { from: noReqAccount }
      );

      let receipt = await cryptoTreasure.safeBatchMintByType(
        accounts,
        typeFreeId,
        mintByTypeParamToBytes(0),
        { from: adminAccount }
      );
      let tokenId = BigNumber.from(10);
      for (acc of accounts) {
        await expectEvent(receipt, "Transfer", {
          from: "0x0000000000000000000000000000000000000000",
          to: acc,
          tokenId: tokenId.toString(),
        });
        expect(
          await cryptoTreasure._storeRestrictedToOwnerAndApproval(
            tokenId.toString()
          )
        ).to.be.false;
        if (tokenId.toString() == "14") {
          tokenId = tokenId.add(1);
        }
        tokenId = tokenId.add(1);
      }
    });

    it("cannot batch mint if not admin", async () => {
      await expectRevert(
        cryptoTreasure.safeBatchMintByType(
          accounts,
          typeFreeId,
          mintByTypeParamToBytes(0),
          { from: noReqAccount }
        ),
        `AccessControl: account ${noReqAccount.toLowerCase()} is missing role 0x0000000000000000000000000000000000000000000000000000000000000000`
      );
    });

    it("cannot mint more than available", async () => {
      await cryptoTreasure.addType(
        "3",
        "10000",
        "10008",
        addTypeParamToBytes(),
        { from: adminAccount }
      );

      await expectRevert(
        cryptoTreasure.safeBatchMintByType(
          accounts,
          "3",
          mintByTypeParamToBytes(0),
          { from: adminAccount }
        ),
        "e18"
      );
    });

    it("cannot mint treasure with a not existing type", async () => {
      await expectRevert(
        cryptoTreasure.safeBatchMintByType(
          accounts,
          "120",
          mintByTypeParamToBytes(0),
          { from: adminAccount }
        ),
        "e10"
      );
    });
  });

  describe("safeBatchMintByType with req token to lock", async () => {
    beforeEach(async () => {
      const boxBase = await BoxBase.new();
      reqTokenMock = await ERC20PausableMock.new(
        "ReqMock",
        "REQM",
        adminAccount,
        "1000"
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

    it("can mint with batch", async () => {
      const totalToLock = BigNumber.from(typeReqLockReqToLock)
        .mul(accounts.length)
        .toString();

      await reqTokenMock.approve(cryptoTreasure.address, totalToLock, {
        from: adminAccount,
      });
      const receipt = await cryptoTreasure.safeBatchMintByType(
        accounts,
        typeReqLockId,
        mintByTypeParamToBytes(0),
        { from: adminAccount }
      );

      await expectEvent.inTransaction(receipt.tx, reqTokenMock, "Transfer", {
        from: adminAccount,
        to: cryptoTreasure.address,
        value: totalToLock,
      });
    });

    it("cannot mint treasure without enough req token approval", async () => {
      await reqTokenMock.approve(cryptoTreasure.address, "999", {
        from: adminAccount,
      });
      await expectRevert(
        cryptoTreasure.safeBatchMintByType(
          accounts,
          typeReqLockId,
          mintByTypeParamToBytes(0),
          { from: adminAccount }
        ),
        "ERC20: transfer amount exceeds allowance"
      );
    });

    it("cannot mint treasure without enough req token", async () => {
      const totalToLock = BigNumber.from(typeReqLockReqToLock)
        .mul(accounts.length)
        .toString();

      await reqTokenMock.approve(cryptoTreasure.address, totalToLock, {
        from: adminAccount,
      });
      await reqTokenMock.transfer(noReqAccount, "1", { from: adminAccount });

      await expectRevert(
        cryptoTreasure.safeBatchMintByType(
          accounts,
          typeReqLockId,
          mintByTypeParamToBytes(0),
          { from: adminAccount }
        ),
        "ERC20: transfer amount exceeds balance"
      );
    });
  });
});
