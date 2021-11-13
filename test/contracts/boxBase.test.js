const { addTypeParamToBytes, mintParamToBytes } = require("../utils");

const { expectRevert } = require("@openzeppelin/test-helpers");

const BoxBase = artifacts.require("BoxBase");

contract("BoxBase security", (accounts) => {
  const adminAccount = accounts[0];
  const noReqAccount = accounts[1];
  const reqHolderAccount = accounts[2];
  let boxBase;

  describe("only delegate call", async () => {
    beforeEach(async () => {
      boxBase = await BoxBase.new();
    });

    it("cannnot store", async () => {
      await expectRevert(
        boxBase.store("1", [], [], [], { from: noReqAccount }),
        "only delegateCall"
      );
    });

    it("cannnot withdraw", async () => {
      await expectRevert(
        boxBase.withdraw("1", "0", [], [], [], noReqAccount, {
          from: noReqAccount,
        }),
        "only delegateCall"
      );
    });

    it("cannnot destroy", async () => {
      await expectRevert(
        boxBase.destroy("1", "0", [], [], [], noReqAccount, {
          from: noReqAccount,
        }),
        "only delegateCall"
      );
    });

    it("cannnot transferBetweenBoxes", async () => {
      await expectRevert(
        boxBase.transferBetweenBoxes("1", "2", "0", [], [], [], {
          from: noReqAccount,
        }),
        "only delegateCall"
      );
    });
  });
});
