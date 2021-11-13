const { addTypeParamToBytes, mintParamToBytes } = require("../utils");
const { expectEvent, expectRevert, BN } = require("@openzeppelin/test-helpers");

const { ethers } = require("ethers");

const BoxBase = artifacts.require("BoxBase");
const CryptoTreasure = artifacts.require("CryptoTreasure");
const ERC721PausableMock = artifacts.require("ERC721PausableMock");
const ERC20PausableMock = artifacts.require("ERC20PausableMock");
const { sleep, nowInSecond } = require("./utils");

contract("CryptoTreasure lock box", (accounts) => {
  let cryptoTreasure;
  let erc721PausableMock1;
  let erc20PausableMock1;

  const typeFreeId = "1";
  const typeFreeFrom = "10";
  const typeFreeTo = "99";

  const boxId = "11";
  const boxId2 = "12";

  const adminAccount = accounts[0];
  const noReqAccount = accounts[1];
  const reqHolderAccount = accounts[2];
  const tokenId1erc1 = "11";
  const tokenId2erc1 = "12";

  const amountETH1 = "100000";
  const amount1 = "1000";
  const amount2 = "200";
  const amountStart = "1000000";

  describe("lock box", async () => {
    beforeEach(async () => {
      erc20PausableMock1 = await ERC20PausableMock.new(
        "MockERC20",
        "MOCK20",
        reqHolderAccount,
        amountStart
      );
      erc721PausableMock1 = await ERC721PausableMock.new("MockERC721", "MOCK");
      erc721PausableMock1.safeMint(reqHolderAccount, tokenId1erc1);
      erc721PausableMock1.safeMint(reqHolderAccount, tokenId2erc1);

      const boxBase = await BoxBase.new();
      cryptoTreasure = await CryptoTreasure.new(boxBase.address);
      await cryptoTreasure.addType(
        typeFreeId,
        typeFreeFrom,
        typeFreeTo,
        addTypeParamToBytes(),
        { from: adminAccount }
      );
      await cryptoTreasure.safeMint(
        reqHolderAccount,
        boxId,
        mintParamToBytes(typeFreeId, 0),
        { from: reqHolderAccount }
      );
      await cryptoTreasure.safeMint(
        reqHolderAccount,
        boxId2,
        mintParamToBytes(typeFreeId, 0),
        { from: reqHolderAccount }
      );

      await erc721PausableMock1.approve(cryptoTreasure.address, tokenId1erc1, {
        from: reqHolderAccount,
      });
      await erc20PausableMock1.approve(cryptoTreasure.address, amount1, {
        from: reqHolderAccount,
      });
      await cryptoTreasure.store(
        boxId,
        [[erc20PausableMock1.address, amount1]],
        [[erc721PausableMock1.address, [tokenId1erc1]]],
        [],
        { from: reqHolderAccount, value: amountETH1 }
      );
    });

    it("can lock a box", async () => {
      const unlockTimestamp = nowInSecond() + 3; // 3 second lock
      const receipt = await cryptoTreasure.lockBox(boxId, unlockTimestamp, {
        from: reqHolderAccount,
      });

      await expectEvent.inTransaction(receipt.tx, cryptoTreasure, "BoxLocked", {
        boxId,
        unlockTimestamp: unlockTimestamp.toString(),
      });

      expect(
        (await cryptoTreasure._unlockTimestamp(boxId)).toString()
      ).to.equal(unlockTimestamp.toString());
    });

    it("cannot store on locked box", async () => {
      const unlockTimestamp = nowInSecond() + 3; // 3 second lock
      await cryptoTreasure.lockBox(boxId, unlockTimestamp, {
        from: reqHolderAccount,
      });
      await erc20PausableMock1.approve(cryptoTreasure.address, amount2, {
        from: reqHolderAccount,
      });
      await expectRevert(
        cryptoTreasure.store(
          boxId,
          [[erc20PausableMock1.address, amount2]],
          [],
          [],
          { from: noReqAccount }
        ),
        "e8"
      );
    });

    it("cannot withdraw on locked box", async () => {
      const unlockTimestamp = nowInSecond() + 3; // 3 second lock
      await cryptoTreasure.lockBox(boxId, unlockTimestamp, {
        from: reqHolderAccount,
      });
      await expectRevert(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [],
          [[erc721PausableMock1.address, [tokenId1erc1]]],
          [],
          noReqAccount,
          { from: noReqAccount }
        ),
        "e8"
      );
    });

    it("cannot destroy a locked box", async () => {
      const unlockTimestamp = nowInSecond() + 3; // 3 second lock
      await cryptoTreasure.lockBox(boxId, unlockTimestamp, {
        from: reqHolderAccount,
      });
      await expectRevert(
        cryptoTreasure.destroy(
          boxId,
          "0",
          [],
          [],
          [],
          ethers.constants.AddressZero,
          { from: reqHolderAccount }
        ),
        "e8"
      );
    });

    it("cannot transferBetweenBoxes a locked box", async () => {
      const unlockTimestamp = nowInSecond() + 3; // 3 second lock
      await cryptoTreasure.lockBox(boxId, unlockTimestamp, {
        from: reqHolderAccount,
      });
      await expectRevert(
        cryptoTreasure.transferBetweenBoxes(boxId, boxId2, "0", [], [], [], {
          from: reqHolderAccount,
        }),
        "e8"
      );
    });

    it("cannot lock a locked box", async () => {
      const unlockTimestamp = nowInSecond() + 3; // 3 second lock
      await cryptoTreasure.lockBox(boxId, unlockTimestamp, {
        from: reqHolderAccount,
      });
      await expectRevert(
        cryptoTreasure.lockBox(boxId, unlockTimestamp + 100, {
          from: reqHolderAccount,
        }),
        "e8"
      );
    });

    it("can withdraw when the lock is over", async () => {
      let unlockTimestamp = nowInSecond() + 3; // 3 second lock
      await cryptoTreasure.lockBox(boxId, unlockTimestamp, {
        from: reqHolderAccount,
      });
      await sleep(3000);

      let receipt = await cryptoTreasure.withdraw(
        boxId,
        "0",
        [[erc20PausableMock1.address, amount1]],
        [],
        [],
        reqHolderAccount,
        { from: reqHolderAccount }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc20PausableMock1,
        "Transfer",
        {
          from: cryptoTreasure.address,
          to: reqHolderAccount,
          value: amount1,
        }
      );
      await expectEvent(receipt, "Withdraw", {
        boxId,
        ethAmount: "0",
        erc20s: [[erc20PausableMock1.address, amount1]],
        erc721s: [],
        erc1155s: [],
        to: reqHolderAccount,
      });

      receipt = await cryptoTreasure.withdraw(
        boxId,
        "0",
        [],
        [[erc721PausableMock1.address, [tokenId1erc1]]],
        [],
        reqHolderAccount,
        { from: reqHolderAccount }
      );

      await expectEvent.inTransaction(
        receipt.tx,
        erc721PausableMock1,
        "Transfer",
        {
          from: cryptoTreasure.address,
          to: reqHolderAccount,
          tokenId: tokenId1erc1,
        }
      );
      await expectEvent(receipt, "Withdraw", {
        boxId,
        ethAmount: "0",
        erc20s: [],
        erc721s: [[erc721PausableMock1.address, [tokenId1erc1]]],
        erc1155s: [],
        to: reqHolderAccount,
      });
    });

    it("can transfer a locked box", async () => {
      const unlockTimestamp = nowInSecond() + 3; // 3 second lock
      await cryptoTreasure.lockBox(boxId, unlockTimestamp, {
        from: reqHolderAccount,
      });
      const receipt = await cryptoTreasure.transferFrom(
        reqHolderAccount,
        noReqAccount,
        boxId,
        { from: reqHolderAccount }
      );

      await expectEvent.inTransaction(receipt.tx, cryptoTreasure, "Transfer", {
        from: reqHolderAccount,
        to: noReqAccount,
        tokenId: boxId,
      });
    });
  });
});
