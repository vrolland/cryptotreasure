const {
  addTypeParamToBytes,
  mintParamToBytes,
  mintByTypeParamToBytes,
} = require("../utils");
const { expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { ethers } = require("ethers");

const BoxBase = artifacts.require("BoxBase");
const CryptoTreasure = artifacts.require("CryptoTreasure");
const ERC721PausableMock = artifacts.require("ERC721PausableMock");
const ERC20PausableMock = artifacts.require("ERC20PausableMock");
const ERC1155Mock = artifacts.require("ERC1155Mock");
const {
  checkTreasure,
  checkErc721Owernship,
  checkErc20Balance,
  checkErc1155Balance,
  sleep,
  checkEthBalance,
} = require("./utils");

contract("CryptoTreasure destroy", (accounts) => {
  let cryptoTreasure;
  let erc721PausableMock1;
  let erc721PausableMock2;
  let erc20PausableMock1;
  let erc20PausableMock2;
  let reqTokenMock;

  const typeFreeId = "1";
  const typeFreeFrom = "10";
  const typeFreeTo = "99";

  const typeReqLockId = "2";
  const typeReqLockFrom = "100";
  const typeReqLockTo = "199";
  const typeReqLockReqToLock = "100";

  const boxId = "11";
  const boxIdReqLock = "111";

  const adminAccount = accounts[0];
  const noReqAccount = accounts[1];
  const reqHolderAccount = accounts[2];
  const tokenId1erc1 = "11";
  const tokenId2erc1 = "12";
  const tokenId3erc1 = "13";

  const tokenId1erc2 = "21";
  const tokenId2erc2 = "22";
  const tokenId3erc2 = "23";

  const amountETH1 = "100000";
  const amount1 = "1000";
  const amount2 = "200";
  const amountStart = "1000000";

  describe("destroy", async () => {
    beforeEach(async () => {
      erc20PausableMock1 = await ERC20PausableMock.new(
        "MockERC20",
        "MOCK20",
        reqHolderAccount,
        amountStart
      );
      erc20PausableMock2 = await ERC20PausableMock.new(
        "MockERC20",
        "MOCK20",
        reqHolderAccount,
        amountStart
      );
      erc721PausableMock1 = await ERC721PausableMock.new("MockERC721", "MOCK");
      erc721PausableMock2 = await ERC721PausableMock.new("MockERC721", "MOCK");

      erc721PausableMock1.safeMint(reqHolderAccount, tokenId1erc1);
      erc721PausableMock1.safeMint(reqHolderAccount, tokenId2erc1);
      erc721PausableMock1.safeMint(reqHolderAccount, tokenId3erc1);

      erc721PausableMock2.safeMint(reqHolderAccount, tokenId1erc2);
      erc721PausableMock2.safeMint(reqHolderAccount, tokenId2erc2);
      erc721PausableMock2.safeMint(reqHolderAccount, tokenId3erc2);

      erc1155Mock1 = await ERC1155Mock.new();
      erc1155Mock2 = await ERC1155Mock.new();
      erc1155Mock3 = await ERC1155Mock.new();

      await erc1155Mock1.mintBatch(
        reqHolderAccount,
        ["111", "112"],
        ["1000", "2000"]
      );
      await erc1155Mock2.mintBatch(
        reqHolderAccount,
        ["223", "224"],
        ["3000", "4000"]
      );
      await erc1155Mock3.mintBatch(
        reqHolderAccount,
        ["333", "444"],
        ["3000", "4000"]
      );

      const boxBase = await BoxBase.new();
      cryptoTreasure = await CryptoTreasure.new(boxBase.address);

      await erc721PausableMock1.approve(cryptoTreasure.address, tokenId1erc1, {
        from: reqHolderAccount,
      });
      await erc721PausableMock1.approve(cryptoTreasure.address, tokenId2erc1, {
        from: reqHolderAccount,
      });
      await erc721PausableMock2.approve(cryptoTreasure.address, tokenId1erc2, {
        from: reqHolderAccount,
      });
      await erc20PausableMock1.approve(cryptoTreasure.address, amount1, {
        from: reqHolderAccount,
      });
      await erc20PausableMock2.approve(cryptoTreasure.address, amount2, {
        from: reqHolderAccount,
      });
      await erc1155Mock1.setApprovalForAll(cryptoTreasure.address, true, {
        from: reqHolderAccount,
      });
      await erc1155Mock2.setApprovalForAll(cryptoTreasure.address, true, {
        from: reqHolderAccount,
      });
    });

    describe("destroy collateralized treasure", async () => {
      beforeEach(async () => {
        reqTokenMock = await ERC20PausableMock.new(
          "ReqMock",
          "REQM",
          reqHolderAccount,
          amountStart
        );

        await cryptoTreasure.addType(
          typeReqLockId,
          typeReqLockFrom,
          typeReqLockTo,
          addTypeParamToBytes(reqTokenMock.address, typeReqLockReqToLock, 0),
          { from: adminAccount }
        );

        await reqTokenMock.approve(
          cryptoTreasure.address,
          typeReqLockReqToLock,
          { from: reqHolderAccount }
        );
        await cryptoTreasure.safeMint(
          reqHolderAccount,
          boxIdReqLock,
          mintParamToBytes(typeReqLockId, 0),
          { from: reqHolderAccount }
        );

        await cryptoTreasure.store(
          boxIdReqLock,
          [
            [erc20PausableMock1.address, amount1],
            [erc20PausableMock2.address, amount2],
          ],
          [
            [erc721PausableMock1.address, [tokenId1erc1, tokenId2erc1]],
            [erc721PausableMock2.address, [tokenId1erc2]],
          ],
          [
            [erc1155Mock1.address, ["111", "112"], ["1000", "2000"]],
            [erc1155Mock2.address, ["223"], ["300"]],
          ],
          { from: reqHolderAccount, value: amountETH1 }
        );
      });

      it("can destroy a treasure with eth, erc721 and erc20 and req locked", async () => {
        const erc20ToWithdraw = [
          [erc20PausableMock1.address, amount1],
          [erc20PausableMock2.address, amount2],
        ];
        const erc721ToWithdraw = [
          [erc721PausableMock1.address, [tokenId1erc1, tokenId2erc1]],
          [erc721PausableMock2.address, [tokenId1erc2]],
        ];
        const erc1155ToWithdraw = [
          [erc1155Mock1.address, ["111", "112"], ["1000", "2000"]],
          [erc1155Mock2.address, ["223"], ["300"]],
        ];
        const receipt = await cryptoTreasure.destroy(
          boxIdReqLock,
          amountETH1,
          erc20ToWithdraw,
          erc721ToWithdraw,
          erc1155ToWithdraw,
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
        await expectEvent.inTransaction(
          receipt.tx,
          erc721PausableMock1,
          "Transfer",
          {
            from: cryptoTreasure.address,
            to: reqHolderAccount,
            tokenId: tokenId2erc1,
          }
        );
        await expectEvent.inTransaction(
          receipt.tx,
          erc721PausableMock2,
          "Transfer",
          {
            from: cryptoTreasure.address,
            to: reqHolderAccount,
            tokenId: tokenId1erc2,
          }
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
        await expectEvent.inTransaction(
          receipt.tx,
          erc20PausableMock2,
          "Transfer",
          {
            from: cryptoTreasure.address,
            to: reqHolderAccount,
            value: amount2,
          }
        );
        await expectEvent.inTransaction(receipt.tx, reqTokenMock, "Transfer", {
          from: cryptoTreasure.address,
          to: reqHolderAccount,
          value: typeReqLockReqToLock,
        });
        await expectEvent.inTransaction(
          receipt.tx,
          erc1155Mock1,
          "TransferBatch",
          {
            operator: cryptoTreasure.address,
            from: cryptoTreasure.address,
            to: reqHolderAccount,
            ids: ["111", "112"],
            values: ["1000", "2000"],
          }
        );

        await expectEvent.inTransaction(
          receipt.tx,
          erc1155Mock2,
          "TransferBatch",
          {
            operator: cryptoTreasure.address,
            from: cryptoTreasure.address,
            to: reqHolderAccount,
            ids: ["223"],
            values: ["300"],
          }
        );

        await expectEvent(receipt, "Withdraw", {
          boxId: boxIdReqLock,
          ethAmount: amountETH1,
          erc20s: erc20ToWithdraw,
          erc721s: erc721ToWithdraw,
          erc1155s: erc1155ToWithdraw,
          to: reqHolderAccount,
        });

        await expectEvent.inTransaction(
          receipt.tx,
          cryptoTreasure,
          "Destroyed",
          {
            boxId: boxIdReqLock,
          }
        );

        await checkTreasure(
          cryptoTreasure,
          boxId,
          "0",
          [
            [erc20PausableMock1.address, 0],
            [erc20PausableMock2.address, 0],
            [erc20PausableMock2.address, 0],
          ],
          [],
          erc721ToWithdraw,
          [
            [erc1155Mock1.address, ["111", "112"], ["0", "0"]],
            [erc1155Mock2.address, ["223"], ["0"]],
          ]
        );

        await checkEthBalance(cryptoTreasure.address, "0");

        await checkErc721Owernship(
          reqHolderAccount,
          erc721PausableMock1,
          tokenId1erc1
        );
        await checkErc721Owernship(
          reqHolderAccount,
          erc721PausableMock1,
          tokenId2erc1
        );
        await checkErc721Owernship(
          reqHolderAccount,
          erc721PausableMock2,
          tokenId1erc2
        );

        await checkErc20Balance(
          reqHolderAccount,
          erc20PausableMock1,
          amountStart
        );
        await checkErc20Balance(
          reqHolderAccount,
          erc20PausableMock2,
          amountStart
        );
        await checkErc20Balance(reqHolderAccount, reqTokenMock, amountStart);

        await checkErc1155Balance(
          reqHolderAccount,
          erc1155Mock1,
          "111",
          "1000"
        );
        await checkErc1155Balance(
          reqHolderAccount,
          erc1155Mock1,
          "112",
          "2000"
        );
        await checkErc1155Balance(
          reqHolderAccount,
          erc1155Mock2,
          "223",
          "3000"
        );
      });
    });

    describe("destroy uncollateralized treasure", async () => {
      beforeEach(async () => {
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

        await cryptoTreasure.store(
          boxId,
          [
            [erc20PausableMock1.address, amount1],
            [erc20PausableMock2.address, amount2],
          ],
          [
            [erc721PausableMock1.address, [tokenId1erc1, tokenId2erc1]],
            [erc721PausableMock2.address, [tokenId1erc2]],
          ],
          [
            [erc1155Mock1.address, ["111", "112"], ["1000", "2000"]],
            [erc1155Mock2.address, ["223"], ["300"]],
          ],
          { from: reqHolderAccount, value: amountETH1 }
        );
      });

      it("can destroy a free treasure with erc721 and erc20", async () => {
        const erc20ToWithdraw = [
          [erc20PausableMock1.address, amount1],
          [erc20PausableMock2.address, amount2],
        ];
        const erc721ToWithdraw = [
          [erc721PausableMock1.address, [tokenId1erc1, tokenId2erc1]],
          [erc721PausableMock2.address, [tokenId1erc2]],
        ];

        const receipt = await cryptoTreasure.destroy(
          boxId,
          amountETH1,
          erc20ToWithdraw,
          erc721ToWithdraw,
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
        await expectEvent.inTransaction(
          receipt.tx,
          erc721PausableMock1,
          "Transfer",
          {
            from: cryptoTreasure.address,
            to: reqHolderAccount,
            tokenId: tokenId2erc1,
          }
        );
        await expectEvent.inTransaction(
          receipt.tx,
          erc721PausableMock2,
          "Transfer",
          {
            from: cryptoTreasure.address,
            to: reqHolderAccount,
            tokenId: tokenId1erc2,
          }
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
        await expectEvent.inTransaction(
          receipt.tx,
          erc20PausableMock2,
          "Transfer",
          {
            from: cryptoTreasure.address,
            to: reqHolderAccount,
            value: amount2,
          }
        );

        await expectEvent(receipt, "Withdraw", {
          boxId,
          ethAmount: amountETH1,
          erc20s: erc20ToWithdraw,
          erc721s: erc721ToWithdraw,
          erc1155s: [],
          to: reqHolderAccount,
        });

        await expectEvent.inTransaction(
          receipt.tx,
          cryptoTreasure,
          "Destroyed",
          {
            boxId,
          }
        );

        await checkTreasure(
          cryptoTreasure,
          boxId,
          "0",
          [
            [erc20PausableMock1.address, 0],
            [erc20PausableMock2.address, 0],
            [erc20PausableMock2.address, 0],
          ],
          [],
          erc721ToWithdraw,
          []
        );
        await checkErc721Owernship(
          reqHolderAccount,
          erc721PausableMock1,
          tokenId1erc1
        );
        await checkErc721Owernship(
          reqHolderAccount,
          erc721PausableMock1,
          tokenId2erc1
        );
        await checkErc721Owernship(
          reqHolderAccount,
          erc721PausableMock2,
          tokenId1erc2
        );

        await checkErc20Balance(
          reqHolderAccount,
          erc20PausableMock1,
          amountStart
        );
        await checkErc20Balance(
          reqHolderAccount,
          erc20PausableMock2,
          amountStart
        );
      });

      it("cannot store on destroyed treasure", async () => {
        await cryptoTreasure.destroy(
          boxId,
          "0",
          [],
          [],
          [],
          ethers.constants.AddressZero,
          { from: reqHolderAccount }
        );
        await expectRevert(
          cryptoTreasure.store(
            boxId,
            [[erc20PausableMock1.address, amount1]],
            [],
            [],
            { from: noReqAccount }
          ),
          "e3"
        );
      });

      it("can withdraw erc721 on destroyed treasure", async () => {
        await cryptoTreasure.destroy(
          boxId,
          "0",
          [],
          [],
          [],
          ethers.constants.AddressZero,
          { from: reqHolderAccount }
        );

        const receipt = await cryptoTreasure.withdraw(
          boxId,
          "0",
          [],
          [[erc721PausableMock1.address, [tokenId1erc1, tokenId2erc1]]],
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
        await expectEvent.inTransaction(
          receipt.tx,
          erc721PausableMock1,
          "Transfer",
          {
            from: cryptoTreasure.address,
            to: reqHolderAccount,
            tokenId: tokenId2erc1,
          }
        );

        await expectEvent(receipt, "Withdraw", {
          boxId,
          ethAmount: "0",
          erc20s: [],
          erc721s: [
            [erc721PausableMock1.address, [tokenId1erc1, tokenId2erc1]],
          ],
          erc1155s: [],
          to: reqHolderAccount,
        });
      });

      it("cannot destroy a destroyed treasure", async () => {
        await cryptoTreasure.destroy(
          boxId,
          "0",
          [],
          [],
          [],
          ethers.constants.AddressZero,
          { from: reqHolderAccount }
        );
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
          "e3"
        );
      });

      it("cannot destroy a treasure owned by someone else", async () => {
        await expectRevert(
          cryptoTreasure.destroy(
            boxId,
            "0",
            [],
            [],
            [],
            ethers.constants.AddressZero,
            { from: noReqAccount }
          ),
          "e4"
        );
      });
    });

    describe("destroy a time-locked treasure", async () => {
      const destroyTimeLockDuration = "3"; // 3 sec
      beforeEach(async () => {
        await cryptoTreasure.addType(
          typeFreeId,
          typeFreeFrom,
          typeFreeTo,
          addTypeParamToBytes(0, 0, destroyTimeLockDuration),
          { from: adminAccount }
        );
        await cryptoTreasure.safeMint(
          reqHolderAccount,
          boxId,
          mintParamToBytes(typeFreeId, 0),
          { from: reqHolderAccount }
        );
      });

      it("cannot destroy a time-locked treasure before before the deadline", async () => {
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
          "e17"
        );
      });
      it("can destroy a time-locked treasure some period after its creation", async () => {
        // Wait a bit...
        await sleep(3000);
        const receipt = await cryptoTreasure.destroy(
          boxId,
          "0",
          [],
          [],
          [],
          ethers.constants.AddressZero,
          { from: reqHolderAccount }
        );
        await expectEvent.inTransaction(
          receipt.tx,
          cryptoTreasure,
          "Destroyed",
          {
            boxId,
          }
        );
        expect(await cryptoTreasure.destroyedBoxes(boxId)).to.be.true;
      });
    });

    describe("destroy a time-locked treasure (mint by type)", async () => {
      const destroyTimeLockDuration = "3"; // 3 sec
      beforeEach(async () => {
        await cryptoTreasure.addType(
          typeFreeId,
          typeFreeFrom,
          typeFreeTo,
          addTypeParamToBytes(0, 0, destroyTimeLockDuration),
          { from: adminAccount }
        );
        await cryptoTreasure.safeMintByType(
          reqHolderAccount,
          typeFreeId,
          mintByTypeParamToBytes(),
          { from: reqHolderAccount }
        );
      });

      it("cannot destroy a time-locked treasure before before the deadline", async () => {
        await expectRevert(
          cryptoTreasure.destroy(
            typeFreeFrom,
            "0",
            [],
            [],
            [],
            ethers.constants.AddressZero,
            { from: reqHolderAccount }
          ),
          "e17"
        );
      });
      it("can destroy a time-locked treasure some period after its creation", async () => {
        // Wait a bit...
        await sleep(3000);
        const receipt = await cryptoTreasure.destroy(
          typeFreeFrom,
          "0",
          [],
          [],
          [],
          ethers.constants.AddressZero,
          { from: reqHolderAccount }
        );
        await expectEvent.inTransaction(
          receipt.tx,
          cryptoTreasure,
          "Destroyed",
          {
            boxId: typeFreeFrom,
          }
        );
        expect(await cryptoTreasure.destroyedBoxes(typeFreeFrom)).to.be.true;
      });
    });

    describe("destroy a time-locked treasure (mint by batch)", async () => {
      const destroyTimeLockDuration = "3"; // 3 sec
      beforeEach(async () => {
        await cryptoTreasure.addType(
          typeFreeId,
          typeFreeFrom,
          typeFreeTo,
          addTypeParamToBytes(0, 0, destroyTimeLockDuration),
          { from: adminAccount }
        );
        await cryptoTreasure.safeBatchMintByType(
          [reqHolderAccount],
          typeFreeId,
          mintByTypeParamToBytes(),
          { from: adminAccount }
        );
      });

      it("cannot destroy a time-locked treasure before before the deadline", async () => {
        await expectRevert(
          cryptoTreasure.destroy(
            typeFreeFrom,
            "0",
            [],
            [],
            [],
            ethers.constants.AddressZero,
            { from: reqHolderAccount }
          ),
          "e17"
        );
      });
      it("can destroy a time-locked treasure some period after its creation", async () => {
        // Wait a bit...
        await sleep(3000);
        const receipt = await cryptoTreasure.destroy(
          typeFreeFrom,
          "0",
          [],
          [],
          [],
          ethers.constants.AddressZero,
          { from: reqHolderAccount }
        );
        await expectEvent.inTransaction(
          receipt.tx,
          cryptoTreasure,
          "Destroyed",
          {
            boxId: typeFreeFrom,
          }
        );
        expect(await cryptoTreasure.destroyedBoxes(typeFreeFrom)).to.be.true;
      });
    });
  });
});
