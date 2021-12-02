const { addTypeParamToBytes, mintParamToBytes } = require("../utils");

const { expectEvent, expectRevert, BN } = require("@openzeppelin/test-helpers");
const BoxBase = artifacts.require("BoxBase");
const CryptoTreasure = artifacts.require("CryptoTreasure");
const ERC20NoThrowMock = artifacts.require("ERC20NoThrowMock");

const { checkTreasure, checkErc20Balance } = require("./utils");

contract("CryptoTreasure attack", (accounts) => {
  let cryptoTreasure;
  let erc20NoThrow;

  const typeFreeId = "1";
  const typeFreeFrom = "10";
  const typeFreeTo = "99";
  const victimBoxId = "11";
  const attackerBoxId = "12";

  const adminAccount = accounts[0];
  const victimAccount = accounts[1];
  const attackerAccount = accounts[2];

  const amount = "1000";

  describe("attack", async () => {
    beforeEach(async () => {
      erc20NoThrow = await ERC20NoThrowMock.new(
        "MockERC20",
        "MOCK20",
        victimAccount,
        amount
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
        victimAccount,
        victimBoxId,
        mintParamToBytes(typeFreeId, 0),
        { from: victimAccount }
      );
      await erc20NoThrow.approve(cryptoTreasure.address, amount, {
        from: victimAccount,
      });
      await cryptoTreasure.store(
        victimBoxId,
        [[erc20NoThrow.address, amount]],
        [],
        [],
        { from: victimAccount }
      );
    });

    it("attacker can drain no throw erc20 tokens", async () => {
      await checkErc20Balance(attackerAccount, erc20NoThrow, "0");

      await cryptoTreasure.safeMint(
        attackerAccount,
        attackerBoxId,
        mintParamToBytes(typeFreeId, 0),
        { from: attackerAccount }
      );

      // store normally not possible
      await expectRevert(
        cryptoTreasure.store(
          attackerBoxId,
          [[erc20NoThrow.address, amount]],
          [],
          [],
          { from: attackerAccount }
        ),
        "e23"
      );

      await checkErc20Balance(attackerAccount, erc20NoThrow, "0");
      await checkErc20Balance(cryptoTreasure.address, erc20NoThrow, amount);
    });
  });
});
