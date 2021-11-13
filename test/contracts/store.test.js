const { addTypeParamToBytes, mintParamToBytes } = require("../utils");

const { expectEvent, expectRevert, BN } = require("@openzeppelin/test-helpers");

const BoxBase = artifacts.require("BoxBase");
const CryptoTreasure = artifacts.require("CryptoTreasure");
const ERC20PausableMock = artifacts.require("ERC20PausableMock");
const ERC721PausableMock = artifacts.require("ERC721PausableMock");
const ERC1155Mock = artifacts.require("ERC1155Mock");
const {
  checkTreasure,
  checkErc721Owernship,
  checkErc20Balance,
  checkErc1155Balance,
  checkEthBalance,
} = require("./utils");
const { ethers } = require("ethers");

contract("CryptoTreasure store", (accounts) => {
  let cryptoTreasure;
  let erc721PausableMock1;
  let erc721PausableMock2;
  let erc20PausableMock1;
  let erc20PausableMock2;
  let erc20PausableMock3;
  let erc1155Mock1;
  let erc1155Mock2;
  let erc1155Mock3;

  const typeFreeId = "1";
  const typeFreeFrom = "10";
  const typeFreeTo = "99";

  const boxId = "11";
  const boxId2 = "12";
  const boxId3 = "13";

  const adminAccount = accounts[0];
  const noReqAccount = accounts[1];
  const reqHolderAccount = accounts[2];
  let boxBase;

  describe("store", async () => {
    beforeEach(async () => {
      erc721PausableMock1 = await ERC721PausableMock.new(
        "MockERC721",
        "MOCK721"
      );
      erc721PausableMock2 = await ERC721PausableMock.new(
        "MockERC721",
        "MOCK721"
      );
      erc721PausableMock1.safeMint(noReqAccount, "11");
      erc721PausableMock1.safeMint(noReqAccount, "12");
      erc721PausableMock2.safeMint(noReqAccount, "21");
      erc721PausableMock2.safeMint(noReqAccount, "22");

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

      boxBase = await BoxBase.new();
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
    });

    it("can store eth", async () => {
      const amount = "1000";

      const receipt = await cryptoTreasure.store(boxId, [], [], [], {
        from: noReqAccount,
        value: amount,
      });

      await expectEvent(receipt, "Store", {
        boxId,
        ethAmount: amount,
        erc20s: [],
        erc721s: [],
        erc1155s: [],
      });

      await checkTreasure(cryptoTreasure, boxId, amount, [], [], [], []);
      await checkEthBalance(cryptoTreasure.address, amount);
    });

    it("can store erc20", async () => {
      const amount = "1000";

      await erc20PausableMock1.approve(cryptoTreasure.address, amount, {
        from: noReqAccount,
      });

      const receipt = await cryptoTreasure.store(
        boxId,
        [[erc20PausableMock1.address, amount]],
        [],
        [],
        { from: noReqAccount }
      );

      await expectEvent.inTransaction(
        receipt.tx,
        erc20PausableMock1,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          value: amount,
        }
      );

      await expectEvent(receipt, "Store", {
        boxId,
        ethAmount: "0",
        erc20s: [[erc20PausableMock1.address, amount]],
        erc721s: [],
        erc1155s: [],
      });

      await checkTreasure(
        cryptoTreasure,
        boxId,
        "0",
        [[erc20PausableMock1.address, amount]],
        [],
        [],
        []
      );
      await checkErc20Balance(
        cryptoTreasure.address,
        erc20PausableMock1,
        amount
      );
      await checkEthBalance(cryptoTreasure.address, "0");
    });

    it("can store erc721", async () => {
      const tokenId = "11";

      await erc721PausableMock1.approve(cryptoTreasure.address, tokenId, {
        from: noReqAccount,
      });

      const receipt = await cryptoTreasure.store(
        boxId,
        [],
        [[erc721PausableMock1.address, [tokenId]]],
        [],
        { from: noReqAccount }
      );

      await expectEvent.inTransaction(
        receipt.tx,
        erc721PausableMock1,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          tokenId,
        }
      );

      await expectEvent(receipt, "Store", {
        boxId,
        ethAmount: "0",
        erc20s: [],
        erc721s: [[erc721PausableMock1.address, [tokenId]]],
        erc1155s: [],
      });

      await checkTreasure(
        cryptoTreasure,
        boxId,
        "0",
        [],
        [[erc721PausableMock1.address, [tokenId]]],
        [],
        []
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock1,
        tokenId
      );
    });

    it("can store erc1155", async () => {
      const tokenId = "111";
      const amount = "1000";

      await erc1155Mock1.setApprovalForAll(cryptoTreasure.address, true, {
        from: noReqAccount,
      });

      const receipt = await cryptoTreasure.store(
        boxId,
        [],
        [],
        [[erc1155Mock1.address, [tokenId], [amount]]],
        { from: noReqAccount }
      );

      await expectEvent(receipt, "Store", {
        boxId,
        ethAmount: "0",
        erc20s: [],
        erc721s: [],
        erc1155s: [[erc1155Mock1.address, [tokenId], [amount]]],
      });
      await expectEvent.inTransaction(
        receipt.tx,
        erc1155Mock1,
        "TransferBatch",
        {
          operator: cryptoTreasure.address,
          from: noReqAccount,
          to: cryptoTreasure.address,
          ids: [tokenId],
          values: [amount],
        }
      );
      await checkTreasure(
        cryptoTreasure,
        boxId,
        "0",
        [],
        [],
        [],
        [[erc1155Mock1.address, [tokenId], [amount]]]
      );
      await checkErc1155Balance(
        cryptoTreasure.address,
        erc1155Mock1,
        tokenId,
        amount
      );
    });

    it("can store eth, erc20, erc721 and erc1155", async () => {
      const amountEth = "10000";
      const tokenIderc721 = "11";
      const amountErc20 = "1000";
      const tokenIdErc1155 = "111";
      const amountErc1155 = "1000";

      await erc721PausableMock1.approve(cryptoTreasure.address, tokenIderc721, {
        from: noReqAccount,
      });
      await erc20PausableMock1.approve(cryptoTreasure.address, amountErc20, {
        from: noReqAccount,
      });
      await erc1155Mock1.setApprovalForAll(cryptoTreasure.address, true, {
        from: noReqAccount,
      });

      const receipt = await cryptoTreasure.store(
        boxId,
        [[erc20PausableMock1.address, amountErc20]],
        [[erc721PausableMock1.address, [tokenIderc721]]],
        [[erc1155Mock1.address, [tokenIdErc1155], [amountErc1155]]],
        { from: noReqAccount, value: amountEth }
      );

      await expectEvent.inTransaction(
        receipt.tx,
        erc20PausableMock1,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          value: amountErc20,
        }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc721PausableMock1,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          tokenId: tokenIderc721,
        }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc1155Mock1,
        "TransferBatch",
        {
          operator: cryptoTreasure.address,
          from: noReqAccount,
          to: cryptoTreasure.address,
          ids: [tokenIdErc1155],
          values: [amountErc1155],
        }
      );

      await expectEvent(receipt, "Store", {
        boxId,
        ethAmount: amountEth,
        erc20s: [[erc20PausableMock1.address, amountErc20]],
        erc721s: [[erc721PausableMock1.address, [tokenIderc721]]],
        erc1155s: [[erc1155Mock1.address, [tokenIdErc1155], [amountErc1155]]],
      });

      await checkTreasure(
        cryptoTreasure,
        boxId,
        amountEth,
        [[erc20PausableMock1.address, amountErc20]],
        [[erc721PausableMock1.address, [tokenIderc721]]],
        [],
        [[erc1155Mock1.address, [tokenIdErc1155], [amountErc1155]]]
      );
      await checkErc1155Balance(
        cryptoTreasure.address,
        erc1155Mock1,
        tokenIdErc1155,
        amountErc1155
      );
      await checkErc20Balance(
        cryptoTreasure.address,
        erc20PausableMock1,
        amountErc20
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock1,
        tokenIderc721
      );
      await checkEthBalance(cryptoTreasure.address, amountEth);
    });

    it("can store eth, erc20 & erc721 & erc1155 multiple time", async () => {
      const amountEth1 = "10000";
      const amountEth2 = "20000";
      const totalEth = "30000";
      const amount1 = "1000";
      const amount2 = "100";
      const total = "1100";
      const tokenId1 = "11";
      const tokenId2 = "12";

      const tokenId3 = "111";
      const amount3 = "900";
      const amount4 = "100";

      await erc1155Mock1.setApprovalForAll(cryptoTreasure.address, true, {
        from: noReqAccount,
      });
      await erc1155Mock2.setApprovalForAll(cryptoTreasure.address, true, {
        from: noReqAccount,
      });
      await erc721PausableMock1.setApprovalForAll(
        cryptoTreasure.address,
        true,
        { from: noReqAccount }
      );
      await erc20PausableMock1.approve(cryptoTreasure.address, total, {
        from: noReqAccount,
      });
      await cryptoTreasure.store(
        boxId,
        [[erc20PausableMock1.address, amount1]],
        [[erc721PausableMock1.address, [tokenId1]]],
        [[erc1155Mock1.address, [tokenId3], [amount3]]],
        { from: noReqAccount, value: amountEth1 }
      );

      const receipt = await cryptoTreasure.store(
        boxId,
        [[erc20PausableMock1.address, amount2]],
        [[erc721PausableMock1.address, [tokenId2]]],
        [[erc1155Mock1.address, [tokenId3], [amount4]]],
        { from: noReqAccount, value: amountEth2 }
      );

      await expectEvent.inTransaction(
        receipt.tx,
        erc20PausableMock1,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          value: amount2,
        }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc721PausableMock1,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          tokenId: tokenId2,
        }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc1155Mock1,
        "TransferBatch",
        {
          operator: cryptoTreasure.address,
          from: noReqAccount,
          to: cryptoTreasure.address,
          ids: [tokenId3],
          values: [amount4],
        }
      );

      await expectEvent(receipt, "Store", {
        boxId,
        ethAmount: amountEth2,
        erc20s: [[erc20PausableMock1.address, amount2]],
        erc721s: [[erc721PausableMock1.address, [tokenId2]]],
        erc1155s: [[erc1155Mock1.address, [tokenId3], [amount4]]],
      });

      await checkTreasure(
        cryptoTreasure,
        boxId,
        totalEth,
        [[erc20PausableMock1.address, total]],
        [[erc721PausableMock1.address, [tokenId1, tokenId2]]],
        [],
        [[erc1155Mock1.address, [tokenId3], ["1000"]]]
      );
      await checkEthBalance(cryptoTreasure.address, totalEth);
      await checkErc20Balance(
        cryptoTreasure.address,
        erc20PausableMock1,
        total
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock1,
        tokenId1
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock1,
        tokenId2
      );
      await checkErc1155Balance(
        cryptoTreasure.address,
        erc1155Mock1,
        tokenId3,
        "1000"
      );
    });

    it("can store the multiple erc20 multiple time", async () => {
      const amount1erc1 = "1000";
      const amount2erc1 = "100";
      const totalerc1 = "1100";

      const amount1erc2 = "2000";
      const amount2erc2 = "200";
      const totalerc2 = "2200";

      const token1Id1 = "11";
      const token1Id2 = "12";

      const token2Id1 = "21";
      const token2Id2 = "22";

      await erc721PausableMock1.setApprovalForAll(
        cryptoTreasure.address,
        true,
        { from: noReqAccount }
      );
      await erc721PausableMock2.setApprovalForAll(
        cryptoTreasure.address,
        true,
        { from: noReqAccount }
      );
      await erc20PausableMock1.approve(cryptoTreasure.address, totalerc1, {
        from: noReqAccount,
      });
      await erc20PausableMock2.approve(cryptoTreasure.address, totalerc2, {
        from: noReqAccount,
      });

      await cryptoTreasure.store(
        boxId,
        [[erc20PausableMock1.address, amount1erc1]],
        [[erc721PausableMock1.address, [token1Id1]]],
        [],
        { from: noReqAccount }
      );

      // store a second
      const receipt = await cryptoTreasure.store(
        boxId,
        [[erc20PausableMock2.address, amount1erc2]],
        [[erc721PausableMock2.address, [token2Id1]]],
        [],
        { from: noReqAccount }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc20PausableMock2,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          value: amount1erc2,
        }
      );
      await expectEvent.inTransaction(
        receipt.tx,
        erc721PausableMock2,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          tokenId: token2Id1,
        }
      );
      await checkTreasure(
        cryptoTreasure,
        boxId,
        "0",
        [
          [erc20PausableMock1.address, amount1erc1],
          [erc20PausableMock2.address, amount1erc2],
        ],
        [
          [erc721PausableMock1.address, [token1Id1]],
          [erc721PausableMock2.address, [token2Id1]],
        ],
        [],
        []
      );
      await checkErc20Balance(
        cryptoTreasure.address,
        erc20PausableMock1,
        amount1erc1
      );
      await checkErc20Balance(
        cryptoTreasure.address,
        erc20PausableMock2,
        amount1erc2
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock1,
        token1Id1
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock2,
        token2Id1
      );

      // store again the first
      const receipt2 = await cryptoTreasure.store(
        boxId,
        [[erc20PausableMock1.address, amount2erc1]],
        [[erc721PausableMock1.address, [token1Id2]]],
        [],
        { from: noReqAccount }
      );
      await expectEvent.inTransaction(
        receipt2.tx,
        erc20PausableMock1,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          value: amount2erc1,
        }
      );
      await expectEvent.inTransaction(
        receipt2.tx,
        erc721PausableMock1,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          tokenId: token1Id2,
        }
      );
      await checkTreasure(
        cryptoTreasure,
        boxId,
        "0",
        [
          [erc20PausableMock1.address, totalerc1],
          [erc20PausableMock2.address, amount1erc2],
        ],
        [],
        [],
        []
      );
      await checkErc20Balance(
        cryptoTreasure.address,
        erc20PausableMock1,
        totalerc1
      );
      await checkErc20Balance(
        cryptoTreasure.address,
        erc20PausableMock2,
        amount1erc2
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock1,
        token1Id1
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock2,
        token2Id1
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock1,
        token1Id2
      );

      // store again the second
      const receipt3 = await cryptoTreasure.store(
        boxId,
        [[erc20PausableMock2.address, amount2erc2]],
        [[erc721PausableMock2.address, [token2Id2]]],
        [],
        { from: noReqAccount }
      );
      await expectEvent.inTransaction(
        receipt3.tx,
        erc20PausableMock2,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          value: amount2erc2,
        }
      );
      await expectEvent.inTransaction(
        receipt3.tx,
        erc721PausableMock2,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          tokenId: token2Id2,
        }
      );
      await checkTreasure(
        cryptoTreasure,
        boxId,
        "0",
        [
          [erc20PausableMock1.address, totalerc1],
          [erc20PausableMock2.address, totalerc2],
        ],
        [
          [erc721PausableMock1.address, [token1Id1, token1Id2]],
          [erc721PausableMock2.address, [token2Id1, token2Id2]],
        ],
        [],
        []
      );
      await checkErc20Balance(
        cryptoTreasure.address,
        erc20PausableMock1,
        totalerc1
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock1,
        token1Id1
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock1,
        token1Id2
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock2,
        token2Id1
      );
      await checkErc721Owernship(
        cryptoTreasure.address,
        erc721PausableMock2,
        token2Id2
      );
    });

    it("cannot store without enough approval", async () => {
      const amount = "1000";
      await erc20PausableMock1.approve(cryptoTreasure.address, "999", {
        from: noReqAccount,
      });
      await expectRevert(
        cryptoTreasure.store(
          boxId,
          [[erc20PausableMock1.address, amount]],
          [],
          [],
          { from: noReqAccount }
        ),
        "e23"
      );
      await expectRevert(
        cryptoTreasure.store(
          boxId,
          [],
          [[erc721PausableMock1.address, ["11"]]],
          [],
          { from: noReqAccount }
        ),
        "e23"
      );
      await expectRevert(
        cryptoTreasure.store(
          boxId,
          [],
          [],
          [[erc1155Mock1.address, ["111"], [amount]]],
          { from: noReqAccount }
        ),
        "e23"
      );
    });

    it("cannot store without the balance", async () => {
      const amount = "1000001";
      await erc20PausableMock1.approve(cryptoTreasure.address, amount, {
        from: noReqAccount,
      });
      await expectRevert(
        cryptoTreasure.store(
          boxId,
          [[erc20PausableMock1.address, amount]],
          [],
          [],
          { from: noReqAccount }
        ),
        "e23"
      );

      const tokenId = "11";
      await erc721PausableMock1.approve(cryptoTreasure.address, tokenId, {
        from: noReqAccount,
      });
      await erc721PausableMock1.transferFrom(
        noReqAccount,
        reqHolderAccount,
        tokenId,
        { from: noReqAccount }
      );
      await expectRevert(
        cryptoTreasure.store(
          boxId,
          [],
          [[erc721PausableMock1.address, [tokenId]]],
          [],
          { from: noReqAccount }
        ),
        "e23"
      );

      const tokenId2 = "111";
      await erc1155Mock1.setApprovalForAll(cryptoTreasure.address, true, {
        from: noReqAccount,
      });
      await expectRevert(
        cryptoTreasure.store(
          boxId,
          [],
          [],
          [[erc1155Mock1.address, [tokenId2], [amount]]],
          { from: noReqAccount }
        ),
        "e23"
      );
    });

    it("handles restriction from not the owner with store", async () => {
      const amount = "1000";
      await cryptoTreasure.setStoreRestrictionToOwnerAndApproval(boxId, true, {
        from: noReqAccount,
      });
      await expectRevert(
        cryptoTreasure.store(
          boxId,
          [[erc20PausableMock1.address, amount]],
          [],
          [],
          { from: reqHolderAccount }
        ),
        "e7"
      );

      await cryptoTreasure.safeMint(
        noReqAccount,
        boxId2,
        mintParamToBytes(typeFreeId, 1),
        { from: noReqAccount }
      );
      await expectRevert(
        cryptoTreasure.store(
          boxId2,
          [[erc20PausableMock1.address, amount]],
          [],
          [],
          { from: reqHolderAccount }
        ),
        "e7"
      );

      await erc20PausableMock1.approve(cryptoTreasure.address, amount, {
        from: noReqAccount,
      });

      await cryptoTreasure.setStoreRestrictionToOwnerAndApproval(boxId, false, {
        from: noReqAccount,
      });
      const receipt = await cryptoTreasure.store(
        boxId2,
        [[erc20PausableMock1.address, amount]],
        [],
        [],
        { from: noReqAccount }
      );

      await expectEvent.inTransaction(
        receipt.tx,
        erc20PausableMock1,
        "Transfer",
        {
          from: noReqAccount,
          to: cryptoTreasure.address,
          value: amount,
        }
      );
      await checkTreasure(
        cryptoTreasure,
        boxId2,
        "0",
        [[erc20PausableMock1.address, amount]],
        [],
        [],
        []
      );
      await checkErc20Balance(
        cryptoTreasure.address,
        erc20PausableMock1,
        amount
      );
    });

    it("cannot store a treasure in a treasure", async () => {
      await cryptoTreasure.safeMint(
        noReqAccount,
        boxId2,
        mintParamToBytes(typeFreeId, 1),
        { from: noReqAccount }
      );
      await cryptoTreasure.approve(cryptoTreasure.address, boxId2, {
        from: noReqAccount,
      });
      await expectRevert(
        cryptoTreasure.store(
          boxId,
          [],
          [[cryptoTreasure.address, [boxId2]]],
          [],
          { from: noReqAccount }
        ),
        "e23"
      );
    });
  });
});
