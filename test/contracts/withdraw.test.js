const { addTypeParamToBytes, mintParamToBytes } = require("../utils");
const { expectEvent, expectRevert, BN } = require("@openzeppelin/test-helpers");

const BoxBase = artifacts.require("BoxBase");
const CryptoTreasure = artifacts.require("CryptoTreasure");
const ERC20PausableMock = artifacts.require("ERC20PausableMock");
const ERC721PausableMock = artifacts.require("ERC721PausableMock");
const ERC1155Mock = artifacts.require("ERC1155Mock");

const {
  checkTreasure,
  checkErc20Balance,
  checkErc721Owernship,
  checkErc1155Balance,
  checkEthBalance,
} = require("./utils");

contract("CryptoTreasure withdraw", (accounts) => {
  let cryptoTreasure;
  let erc20PausableMock1;
  let erc20PausableMock2;
  let erc721PausableMock1;
  let erc721PausableMock2;
  let erc721PausableMock3;

  const typeFreeId = "1";
  const typeFreeFrom = "10";
  const typeFreeTo = "99";

  const boxId = "11";

  const adminAccount = accounts[0];
  const noReqAccount = accounts[1];
  const reqHolderAccount = accounts[2];
  const amount1 = "1000";
  const amountETH1 = "100000";

  const tokenId1erc1 = "11";
  const tokenId2erc1 = "12";
  const tokenId3erc1 = "13";

  const tokenId1erc2 = "21";
  const tokenId2erc2 = "22";
  const tokenId3erc2 = "23";

  const tokenId111Erc1155 = "111";
  const amount1Erc1155 = "1000";

  describe("withdraw", async () => {
    beforeEach(async () => {
      erc721PausableMock1 = await ERC721PausableMock.new("MockERC721", "MOCK");
      erc721PausableMock2 = await ERC721PausableMock.new("MockERC721", "MOCK");
      erc721PausableMock3 = await ERC721PausableMock.new("MockERC721", "MOCK");

      erc721PausableMock1.safeMint(noReqAccount, tokenId1erc1);
      erc721PausableMock1.safeMint(noReqAccount, tokenId2erc1);
      erc721PausableMock1.safeMint(noReqAccount, tokenId3erc1);

      erc721PausableMock2.safeMint(noReqAccount, tokenId1erc2);
      erc721PausableMock2.safeMint(noReqAccount, tokenId2erc2);
      erc721PausableMock2.safeMint(noReqAccount, tokenId3erc2);

      erc20PausableMock1 = await ERC20PausableMock.new(
        "MockERC20",
        "MOCK20",
        noReqAccount,
        "1000000"
      );
      erc20PausableMock2 = await ERC20PausableMock.new(
        "MockERC20",
        "MOCK20",
        noReqAccount,
        "1000000"
      );
      erc20PausableMock3 = await ERC20PausableMock.new(
        "MockERC20",
        "MOCK20",
        noReqAccount,
        "1000000"
      );

      erc1155Mock1 = await ERC1155Mock.new();
      erc1155Mock2 = await ERC1155Mock.new();
      erc1155Mock3 = await ERC1155Mock.new();
      await erc1155Mock1.mintBatch(
        noReqAccount,
        ["111", "112"],
        ["1000", "2000"]
      );
      await erc1155Mock2.mintBatch(
        noReqAccount,
        ["223", "224"],
        ["3000", "4000"]
      );
      await erc1155Mock3.mintBatch(
        noReqAccount,
        ["333", "444"],
        ["3000", "4000"]
      );

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
        noReqAccount,
        boxId,
        mintParamToBytes(typeFreeId, 0),
        { from: noReqAccount }
      );

      await erc20PausableMock1.approve(cryptoTreasure.address, amount1, {
        from: noReqAccount,
      });
      await erc721PausableMock1.approve(cryptoTreasure.address, tokenId2erc1, {
        from: noReqAccount,
      });
      await erc721PausableMock1.approve(cryptoTreasure.address, tokenId1erc1, {
        from: noReqAccount,
      });
      await erc1155Mock1.setApprovalForAll(cryptoTreasure.address, true, {
        from: noReqAccount,
      });

      await cryptoTreasure.store(
        boxId,
        [[erc20PausableMock1.address, amount1]],
        [
          [erc721PausableMock1.address, [tokenId1erc1]],
          [erc721PausableMock1.address, [tokenId2erc1]],
        ],
        [[erc1155Mock1.address, [tokenId111Erc1155], [amount1Erc1155]]],
        { from: noReqAccount, value: amountETH1 }
      );
    });

    it("can withdraw a part", async () => {
      const amountETH1Partial = "70000";
      const amountETH1Remaining = "30000";
      const amount1Partial = "700";
      const amount1Remaining = "300";

      const receipt = await cryptoTreasure.withdraw(
        boxId,
        amountETH1Partial,
        [[erc20PausableMock1.address, amount1Partial]],
        [[erc721PausableMock1.address, [tokenId1erc1]]],
        [[erc1155Mock1.address, [tokenId111Erc1155], [amount1Partial]]],
        noReqAccount,
        { from: noReqAccount }
      );

      await expectEvent.inTransaction(
        receipt.tx,
        erc20PausableMock1,
        "Transfer",
        {
          from: cryptoTreasure.address,
          to: noReqAccount,
          value: amount1Partial,
        }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc721PausableMock1,
        "Transfer",
        {
          from: cryptoTreasure.address,
          to: noReqAccount,
          tokenId: tokenId1erc1,
        }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc1155Mock1,
        "TransferBatch",
        {
          operator: cryptoTreasure.address,
          from: cryptoTreasure.address,
          to: noReqAccount,
          ids: [tokenId111Erc1155],
          values: [amount1Partial],
        }
      );

      await expectEvent(receipt, "Withdraw", {
        boxId,
        ethAmount: amountETH1Partial,
        erc20s: [[erc20PausableMock1.address, amount1Partial]],
        erc721s: [[erc721PausableMock1.address, [tokenId1erc1]]],
        erc1155s: [
          [erc1155Mock1.address, [tokenId111Erc1155], [amount1Partial]],
        ],
        to: noReqAccount,
      });

      await checkTreasure(
        cryptoTreasure,
        boxId,
        amountETH1Remaining,
        [[erc20PausableMock1.address, amount1Remaining]],
        [[erc721PausableMock1.address, [tokenId2erc1]]],
        [[erc721PausableMock1.address, [tokenId1erc1]]],
        [[erc1155Mock1.address, [tokenId111Erc1155], [amount1Remaining]]]
      );
      await checkEthBalance(cryptoTreasure.address, amountETH1Remaining);
      await checkErc20Balance(
        cryptoTreasure.address,
        erc20PausableMock1,
        amount1Remaining
      );
      await checkErc721Owernship(
        noReqAccount,
        erc721PausableMock1,
        tokenId1erc1
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock1,
        tokenId2erc1
      );
      await checkErc1155Balance(
        cryptoTreasure.address,
        erc1155Mock1,
        tokenId111Erc1155,
        amount1Remaining
      );
      await checkErc1155Balance(
        noReqAccount,
        erc1155Mock1,
        tokenId111Erc1155,
        amount1Partial
      );
    });

    it("can withdraw everything", async () => {
      const receipt = await cryptoTreasure.withdraw(
        boxId,
        amountETH1,
        [[erc20PausableMock1.address, amount1]],
        [[erc721PausableMock1.address, [tokenId1erc1, tokenId2erc1]]],
        [[erc1155Mock1.address, [tokenId111Erc1155], [amount1Erc1155]]],
        noReqAccount,
        { from: noReqAccount }
      );

      await expectEvent.inTransaction(
        receipt.tx,
        erc20PausableMock1,
        "Transfer",
        {
          from: cryptoTreasure.address,
          to: noReqAccount,
          value: amount1,
        }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc721PausableMock1,
        "Transfer",
        {
          from: cryptoTreasure.address,
          to: noReqAccount,
          tokenId: tokenId1erc1,
        }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc721PausableMock1,
        "Transfer",
        {
          from: cryptoTreasure.address,
          to: noReqAccount,
          tokenId: tokenId2erc1,
        }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc1155Mock1,
        "TransferBatch",
        {
          operator: cryptoTreasure.address,
          from: cryptoTreasure.address,
          to: noReqAccount,
          ids: [tokenId111Erc1155],
          values: [amount1Erc1155],
        }
      );

      await expectEvent(receipt, "Withdraw", {
        boxId,
        ethAmount: amountETH1,
        erc20s: [[erc20PausableMock1.address, amount1]],
        erc721s: [[erc721PausableMock1.address, [tokenId1erc1, tokenId2erc1]]],
        erc1155s: [
          [erc1155Mock1.address, [tokenId111Erc1155], [amount1Erc1155]],
        ],
        to: noReqAccount,
      });

      await checkTreasure(
        cryptoTreasure,
        boxId,
        "0",
        [[erc20PausableMock1.address, "0"]],
        [],
        [[erc721PausableMock1.address, [tokenId1erc1, tokenId2erc1]]],
        [[erc1155Mock1.address, [tokenId111Erc1155], ["0"]]]
      );
      await checkEthBalance(cryptoTreasure.address, "0");
      await checkErc20Balance(cryptoTreasure.address, erc20PausableMock1, "0");
      await checkErc721Owernship(
        noReqAccount,
        erc721PausableMock1,
        tokenId1erc1
      );
      await checkErc721Owernship(
        noReqAccount,
        erc721PausableMock1,
        tokenId2erc1
      );
      await checkErc1155Balance(
        cryptoTreasure.address,
        erc1155Mock1,
        tokenId111Erc1155,
        "0"
      );
      await checkErc1155Balance(
        noReqAccount,
        erc1155Mock1,
        tokenId111Erc1155,
        amount1Erc1155
      );
    });

    it("can withdraw eth and erc20 multiple time", async () => {
      const amountETH1Partial = "70000";
      const amountETH1Remaining = "30000";
      const amount1Partial = "700";
      const amount1Remaining = "300";
      await cryptoTreasure.withdraw(
        boxId,
        amountETH1Partial,
        [[erc20PausableMock1.address, amount1Partial]],
        [],
        [],
        noReqAccount,
        { from: noReqAccount }
      );

      const receipt = await cryptoTreasure.withdraw(
        boxId,
        amountETH1Remaining,
        [[erc20PausableMock1.address, amount1Remaining]],
        [],
        [],
        noReqAccount,
        { from: noReqAccount }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc20PausableMock1,
        "Transfer",
        {
          from: cryptoTreasure.address,
          to: noReqAccount,
          value: amount1Remaining,
        }
      );
      await expectEvent(receipt, "Withdraw", {
        boxId,
        ethAmount: amountETH1Remaining,
        erc20s: [[erc20PausableMock1.address, amount1Remaining]],
        erc721s: [],
        erc1155s: [],
        to: noReqAccount,
      });
      await checkTreasure(
        cryptoTreasure,
        boxId,
        "0",
        [[erc20PausableMock1.address, "0"]],
        [],
        [],
        []
      );
      await checkEthBalance(cryptoTreasure.address, "0");
      await checkErc20Balance(cryptoTreasure.address, erc20PausableMock1, "0");
    });

    it("cannot withdraw eth already withdrawn", async () => {
      await cryptoTreasure.withdraw(
        boxId,
        amountETH1,
        [],
        [],
        [],
        noReqAccount,
        { from: noReqAccount }
      );
      await expectRevert.unspecified(
        cryptoTreasure.withdraw(boxId, amountETH1, [], [], [], noReqAccount, {
          from: noReqAccount,
        })
      );
    });

    it("cannot withdraw eth from a box owned by someone else", async () => {
      await expectRevert(
        cryptoTreasure.withdraw(boxId, amountETH1, [], [], [], noReqAccount, {
          from: reqHolderAccount,
        }),
        "e4"
      );
    });

    it("cannot withdraw eth more than stored", async () => {
      await expectRevert.unspecified(
        cryptoTreasure.withdraw(boxId, "100001", [], [], [], noReqAccount, {
          from: noReqAccount,
        })
      );
    });

    it("cannot withdraw erc20 not in the treasure", async () => {
      await expectRevert.unspecified(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [[erc20PausableMock2.address, amount1]],
          [],
          [],
          noReqAccount,
          { from: noReqAccount }
        )
      );
    });

    it("cannot withdraw erc20 already withdrawn", async () => {
      await cryptoTreasure.withdraw(
        boxId,
        "0",
        [[erc20PausableMock1.address, amount1]],
        [],
        [],
        noReqAccount,
        { from: noReqAccount }
      );
      await expectRevert.unspecified(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [[erc20PausableMock1.address, amount1]],
          [],
          [],
          noReqAccount,
          { from: noReqAccount }
        )
      );
    });

    it("cannot withdraw erc20 from a box owned by someone else", async () => {
      await expectRevert(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [[erc20PausableMock1.address, amount1]],
          [],
          [],
          noReqAccount,
          { from: reqHolderAccount }
        ),
        "e4"
      );
    });

    it("cannot withdraw erc20 more than stored", async () => {
      await expectRevert.unspecified(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [[erc20PausableMock1.address, "1001"]],
          [],
          [],
          noReqAccount,
          { from: noReqAccount }
        )
      );
    });

    it("cannot withdraw erc721 not in the treasure", async () => {
      await expectRevert(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [],
          [[erc721PausableMock1.address, [tokenId3erc1]]],
          [],
          noReqAccount,
          { from: noReqAccount }
        ),
        "e23"
      );
      await expectRevert(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [],
          [[erc721PausableMock3.address, [tokenId1erc1]]],
          [],
          noReqAccount,
          { from: noReqAccount }
        ),
        "e23"
      );
      await expectRevert(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [],
          [[erc721PausableMock1.address, [tokenId2erc1, tokenId3erc1]]],
          [],
          noReqAccount,
          { from: noReqAccount }
        ),
        "e23"
      );
    });

    it("cannot withdraw erc721 already withdrawn", async () => {
      await cryptoTreasure.withdraw(
        boxId,
        "0",
        [],
        [[erc721PausableMock1.address, [tokenId1erc1]]],
        [],
        noReqAccount,
        { from: noReqAccount }
      );
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
        "e23"
      );
    });

    it("cannot withdraw erc721 from a box owned by someone else", async () => {
      await expectRevert(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [],
          [[erc721PausableMock1.address, [tokenId1erc1]]],
          [],
          noReqAccount,
          { from: reqHolderAccount }
        ),
        "e4"
      );
    });

    it("cannot withdraw erc1155 not in the treasure", async () => {
      await expectRevert(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [],
          [],
          [[erc721PausableMock1.address, ["112"], ["100"]]],
          noReqAccount,
          { from: noReqAccount }
        ),
        "e23"
      );
      await expectRevert(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [],
          [],
          [[erc721PausableMock3.address, ["333"], ["100"]]],
          noReqAccount,
          { from: noReqAccount }
        ),
        "e23"
      );
      await expectRevert(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [],
          [],
          [[erc721PausableMock1.address, ["111", "112"], ["100", "100"]]],
          noReqAccount,
          { from: noReqAccount }
        ),
        "e23"
      );
    });

    it("cannot withdraw erc1155 already withdrawn", async () => {
      await cryptoTreasure.withdraw(
        boxId,
        "0",
        [],
        [],
        [[erc1155Mock1.address, [tokenId111Erc1155], ["600"]]],
        noReqAccount,
        { from: noReqAccount }
      );
      await expectRevert(
        cryptoTreasure.withdraw(
          boxId,
          "0",
          [],
          [],
          [[erc1155Mock1.address, [tokenId111Erc1155], ["600"]]],
          noReqAccount,
          { from: noReqAccount }
        ),
        "e23"
      );
    });
  });
});
