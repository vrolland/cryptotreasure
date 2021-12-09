const {
  addTypeParamToBytes,
  mintByTypeParamToBytes,
  mintParamToBytes,
} = require("../utils");

const { expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { BigNumber } = require("ethers");

const BoxBase = artifacts.require("BoxBase");
const CryptoTreasure = artifacts.require("CryptoTreasure");
const ERC20Key = artifacts.require("ERC20Key");

contract("CryptoTreasure erc20Key minting", (accounts) => {
  let cryptoTreasure;
  let erc20Key;

  const typeId = "2";
  const typeFrom = "10";
  const typeTo = "199";
  const typeAmountToLock = "1";

  const adminAccount = accounts[0];
  const keyHolderAccount = accounts[1];
  const noKeyAccount = accounts[2];

  describe("erc20 key", async () => {
    beforeEach(async () => {
      const boxBase = await BoxBase.new();
      cryptoTreasure = await CryptoTreasure.new(boxBase.address);
      erc20Key = await ERC20Key.new("TestKey", "TKEY", cryptoTreasure.address);

      await erc20Key.mint(keyHolderAccount, 100);
      await erc20Key.mint(adminAccount, 10);
      await cryptoTreasure.addType(
        typeId,
        typeFrom,
        typeTo,
        addTypeParamToBytes(erc20Key.address, typeAmountToLock, 0),
        { from: adminAccount }
      );
    });

    describe("mint by id", async () => {
      it("can mint", async () => {
        const treasureId = "11";
        const receipt = await cryptoTreasure.safeMint(
          keyHolderAccount,
          treasureId,
          mintParamToBytes(typeId),
          { from: keyHolderAccount }
        );

        await expectEvent(receipt, "Transfer", {
          from: "0x0000000000000000000000000000000000000000",
          to: keyHolderAccount,
          tokenId: treasureId,
        });
      });

      it("can mint after a key transfer", async () => {
        await erc20Key.transfer(noKeyAccount, 1);
        const treasureId = "11";
        const receipt = await cryptoTreasure.safeMint(
          noKeyAccount,
          treasureId,
          mintParamToBytes(typeId),
          { from: noKeyAccount }
        );

        await expectEvent(receipt, "Transfer", {
          from: "0x0000000000000000000000000000000000000000",
          to: noKeyAccount,
          tokenId: treasureId,
        });
      });

      it("cannot mint without key", async () => {
        const treasureId = "11";
        await expectRevert(
          cryptoTreasure.safeMint(
            noKeyAccount,
            treasureId,
            mintParamToBytes(typeId),
            { from: noKeyAccount }
          ),
          "ERC20: transfer amount exceeds balance"
        );
      });
    });

    describe("mint by batch", async () => {
      it("can mint with batch", async () => {
        const totalToLock = BigNumber.from(typeAmountToLock)
          .mul(accounts.length)
          .toString();

        const receipt = await cryptoTreasure.safeBatchMintByType(
          accounts,
          typeId,
          mintByTypeParamToBytes(0),
          { from: adminAccount }
        );

        await expectEvent.inTransaction(receipt.tx, erc20Key, "Transfer", {
          from: adminAccount,
          to: cryptoTreasure.address,
          value: totalToLock,
        });
      });

      it("cannot mint with batch without key", async () => {
        await erc20Key.transfer(accounts[8], 5);
        await expectRevert(
          cryptoTreasure.safeBatchMintByType(
            accounts,
            typeId,
            mintByTypeParamToBytes(0),
            { from: adminAccount }
          ),
          "ERC20: transfer amount exceeds balance"
        );
      });
    });

    describe("mint by type", async () => {
      it("can mint by type", async () => {
        let receipt = await cryptoTreasure.safeMintByType(
          keyHolderAccount,
          typeId,
          mintByTypeParamToBytes(0),
          { from: keyHolderAccount }
        );
        await expectEvent(receipt, "Transfer", {
          from: "0x0000000000000000000000000000000000000000",
          to: keyHolderAccount,
          tokenId: "10",
        });
      });

      it("cannot mint with batch without key", async () => {
        await expectRevert(
          cryptoTreasure.safeMintByType(
            noKeyAccount,
            typeId,
            mintByTypeParamToBytes(0),
            { from: noKeyAccount }
          ),
          "ERC20: transfer amount exceeds balance"
        );
      });
    });

    describe("allowance", async () => {
      it("can get full allowance for cryptoTreasure", async () => {
        const maxUINT = BigNumber.from(2).pow(256).sub(1);
        const allowance = await erc20Key.allowance(
          keyHolderAccount,
          cryptoTreasure.address
        );
        expect(allowance.toString()).to.be.equal(maxUINT.toString());
      });
      it("can get normal allowance for others", async () => {
        let allowance = await erc20Key.allowance(
          keyHolderAccount,
          noKeyAccount
        );
        expect(allowance.toString()).to.be.equal("0");

        await erc20Key.approve(noKeyAccount, "2", { from: keyHolderAccount });
        allowance = await erc20Key.allowance(keyHolderAccount, noKeyAccount);
        expect(allowance.toString()).to.be.equal("2");
      });
    });
  });
});
