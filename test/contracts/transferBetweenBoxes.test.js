const { addTypeParamToBytes, mintParamToBytes } = require("../utils");
const { expectEvent, expectRevert, BN } = require("@openzeppelin/test-helpers");

const { checkTreasure } = require("./utils");
const { ethers } = require("ethers");

const BoxBase = artifacts.require("BoxBase");
const CryptoTreasure = artifacts.require("CryptoTreasure");
const ERC721PausableMock = artifacts.require("ERC721PausableMock");
const ERC20PausableMock = artifacts.require("ERC20PausableMock");
const ERC1155Mock = artifacts.require("ERC1155Mock");

contract("CryptoTreasure transferBetweenBoxes", (accounts) => {
  let cryptoTreasure;
  let erc721PausableMock1;
  let erc721PausableMock2;
  let erc20PausableMock1;
  let erc20PausableMock2;

  const typeFreeId = "1";
  const typeFreeFrom = "10";
  const typeFreeTo = "99";

  const srcBoxId = "11";
  const destBoxId = "12";

  const adminAccount = accounts[0];
  const noReqAccount = accounts[1];
  const reqHolderAccount = accounts[2];
  const tokenId1erc1 = "11";
  const tokenId2erc1 = "12";
  const tokenId3erc1 = "13";

  const tokenId1erc2 = "21";
  const tokenId2erc2 = "22";
  const tokenId3erc2 = "23";

  const amount1 = "1000";
  const amount2 = "200";
  const amountETH1 = "100000";
  const amountStart = "1000000";

  describe("transferBetweenBoxes", async () => {
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
      await cryptoTreasure.addType(
        typeFreeId,
        typeFreeFrom,
        typeFreeTo,
        addTypeParamToBytes(),
        { from: adminAccount }
      );
      await cryptoTreasure.safeMint(
        reqHolderAccount,
        srcBoxId,
        mintParamToBytes(typeFreeId, 0),
        { from: reqHolderAccount }
      );
      await cryptoTreasure.safeMint(
        noReqAccount,
        destBoxId,
        mintParamToBytes(typeFreeId, 0),
        { from: noReqAccount }
      );

      await erc721PausableMock1.setApprovalForAll(
        cryptoTreasure.address,
        true,
        { from: reqHolderAccount }
      );
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
      await cryptoTreasure.store(
        srcBoxId,
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

    it("can transferBetweenBoxes eth, erc721, erc20 and erc1155", async () => {
      const erc20s = [
        [erc20PausableMock1.address, amount1],
        [erc20PausableMock2.address, amount2],
      ];

      const erc721s = [
        [erc721PausableMock1.address, [tokenId1erc1, tokenId2erc1]],
        [erc721PausableMock2.address, [tokenId1erc2]],
      ];

      const erc1155s = [
        [erc1155Mock1.address, ["111", "112"], ["1000", "2000"]],
        [erc1155Mock2.address, ["223"], ["300"]],
      ];

      const receipt = await cryptoTreasure.transferBetweenBoxes(
        srcBoxId,
        destBoxId,
        amountETH1,
        erc20s,
        erc721s,
        erc1155s,
        { from: reqHolderAccount }
      );

      // ----------------------------------------------------------------------------------

      await expectEvent(receipt, "TransferBetweenBoxes", {
        srcBoxId,
        destBoxId,
        ethAmount: amountETH1,
        erc20s,
        erc721s,
        erc1155s,
      });

      await checkTreasure(
        cryptoTreasure,
        srcBoxId,
        "0",
        [
          [erc20PausableMock1.address, 0],
          [erc20PausableMock2.address, 0],
        ],
        [],
        erc721s,
        [
          [erc1155Mock1.address, ["111", "112"], ["0", "0"]],
          [erc1155Mock2.address, ["223"], ["0"]],
        ]
      );
      await checkTreasure(
        cryptoTreasure,
        destBoxId,
        amountETH1,
        erc20s,
        erc721s,
        [],
        erc1155s
      );
    });

    it("can transferBetweenBoxes a part of erc721, erc20 and erc1155 (twice)", async () => {
      const amountETH1Half = "50000";
      let erc20s = [[erc20PausableMock1.address, "500"]];
      let erc721s = [[erc721PausableMock1.address, [tokenId1erc1]]];
      const erc1155s = [[erc1155Mock1.address, ["111"], ["500"]]];
      let receipt = await cryptoTreasure.transferBetweenBoxes(
        srcBoxId,
        destBoxId,
        amountETH1Half,
        erc20s,
        erc721s,
        erc1155s,
        { from: reqHolderAccount }
      );
      // ----------------------------------------------------------------------------------
      await expectEvent(receipt, "TransferBetweenBoxes", {
        srcBoxId,
        destBoxId,
        ethAmount: amountETH1Half,
        erc20s,
        erc721s,
        erc1155s,
      });
      await checkTreasure(
        cryptoTreasure,
        srcBoxId,
        amountETH1Half,
        [
          [erc20PausableMock1.address, "500"],
          [erc20PausableMock2.address, amount2],
        ],
        [
          [erc721PausableMock1.address, [tokenId2erc1]],
          [erc721PausableMock2.address, [tokenId1erc2]],
        ],
        erc721s,
        erc1155s
      );
      await checkTreasure(
        cryptoTreasure,
        destBoxId,
        amountETH1Half,
        erc20s,
        erc721s,
        [],
        erc1155s
      );

      erc20s = [[erc20PausableMock1.address, "500"]];
      erc721s = [[erc721PausableMock1.address, [tokenId2erc1]]];
      receipt = await cryptoTreasure.transferBetweenBoxes(
        srcBoxId,
        destBoxId,
        amountETH1Half,
        erc20s,
        erc721s,
        erc1155s,
        { from: reqHolderAccount }
      );
      // ----------------------------------------------------------------------------------
      await expectEvent(receipt, "TransferBetweenBoxes", {
        srcBoxId,
        destBoxId,
        ethAmount: amountETH1Half,
        erc20s,
        erc721s,
        erc1155s,
      });

      await checkTreasure(
        cryptoTreasure,
        srcBoxId,
        "0",
        [
          [erc20PausableMock1.address, 0],
          [erc20PausableMock2.address, amount2],
        ],
        [[erc721PausableMock2.address, [tokenId1erc2]]],
        erc721s,
        [[erc1155Mock1.address, ["111"], ["0"]]]
      );
      await checkTreasure(
        cryptoTreasure,
        destBoxId,
        amountETH1,
        [
          [erc20PausableMock1.address, amount1],
          [erc20PausableMock2.address, 0],
        ],
        [[erc721PausableMock1.address, [tokenId2erc1, tokenId2erc1]]],
        [],
        [[erc1155Mock1.address, ["111"], ["1000"]]]
      );
    });

    it("cannot transferBetweenBoxes to a not minted box", async () => {
      const erc20s = [[erc20PausableMock1.address, amount1]];
      const erc721s = [[erc721PausableMock1.address, [tokenId1erc1]]];
      await expectRevert(
        cryptoTreasure.transferBetweenBoxes(
          srcBoxId,
          "13",
          "0",
          erc20s,
          erc721s,
          [],
          { from: reqHolderAccount }
        ),
        "e15"
      );
    });

    it("cannot transferBetweenBoxes an amount of eth not in the box", async () => {
      await expectRevert(
        cryptoTreasure.transferBetweenBoxes(
          srcBoxId,
          destBoxId,
          "100001",
          [],
          [],
          [],
          { from: reqHolderAccount }
        ),
        "e23"
      );
    });

    it("cannot transferBetweenBoxes an amount of erc20 not in the box", async () => {
      const erc20s = [[erc20PausableMock1.address, "1001"]];
      const erc721s = [];
      await expectRevert(
        cryptoTreasure.transferBetweenBoxes(
          srcBoxId,
          destBoxId,
          "0",
          erc20s,
          erc721s,
          [],
          { from: reqHolderAccount }
        ),
        "e23"
      );
    });

    it("cannot transferBetweenBoxes an amount of erc721 not in the box", async () => {
      const erc20s = [];
      const erc721s = [[erc721PausableMock1.address, [tokenId3erc1]]];
      await expectRevert(
        cryptoTreasure.transferBetweenBoxes(
          srcBoxId,
          destBoxId,
          "0",
          erc20s,
          erc721s,
          [],
          { from: reqHolderAccount }
        ),
        "e23"
      );
    });

    it("cannot transferBetweenBoxes an amount of erc1155 not in the box", async () => {
      const erc1155s = [[erc1155Mock1.address, ["111"], ["1001"]]];
      await expectRevert(
        cryptoTreasure.transferBetweenBoxes(
          srcBoxId,
          destBoxId,
          "0",
          [],
          [],
          erc1155s,
          { from: reqHolderAccount }
        ),
        "e23"
      );
    });
  });
});
