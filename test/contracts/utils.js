const { ethers } = require("ethers");

async function checkTreasure(
  _cryptoTreasure,
  _srcBoxId,
  _ethBalance,
  _erc20balance,
  _erc721balance,
  _NOTerc721balance,
  _erc1155balance
) {
  const ethBalance = await _cryptoTreasure.EthBalanceOf(_srcBoxId);
  expect(ethBalance.toString()).to.equal(_ethBalance.toString());

  for (erc20 of _erc20balance) {
    const erc20Balance = await _cryptoTreasure.erc20BalanceOf(
      _srcBoxId,
      erc20[0]
    );
    expect(erc20Balance.toString()).to.equal(erc20[1].toString());
  }

  for (erc721 of _erc721balance) {
    for (tokenId of erc721[1]) {
      const isErc721inTreasure = await _cryptoTreasure.erc721BalanceOf(
        _srcBoxId,
        erc721[0],
        tokenId
      );
      expect(isErc721inTreasure.toNumber()).to.be.equal(1);
    }
  }

  for (erc721 of _NOTerc721balance) {
    for (tokenId of erc721[1]) {
      const isErc721inTreasure = await _cryptoTreasure.erc721BalanceOf(
        _srcBoxId,
        erc721[0],
        tokenId
      );
      expect(isErc721inTreasure.toNumber()).to.be.equal(0);
    }
  }

  for (erc1155 of _erc1155balance) {
    for (index in erc1155[1]) {
      const tokenId = erc1155[1][index];
      const balance = await _cryptoTreasure.erc1155BalanceOf(
        _srcBoxId,
        erc1155[0],
        tokenId
      );
      expect(balance.toString()).to.be.equal(erc1155[2][index]);
    }
  }
}

const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
async function checkEthBalance(address, amount) {
  const balance = await provider.getBalance(address);
  expect(balance.toString()).to.equal(amount);
}
async function checkErc1155Balance(address, erc1155contract, id, amount) {
  const balance = await erc1155contract.balanceOf(address, id);
  expect(balance.toString()).to.equal(amount);
}
async function checkErc721Owernship(address, erc721contract, id) {
  const owner = await erc721contract.ownerOf(id);
  expect(owner).to.equal(address);
}
async function checkErc20Balance(address, erc20contract, amount) {
  const balance = await erc20contract.balanceOf(address);
  expect(balance.toString()).to.equal(amount);
}

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function nowInSecond() {
  return Math.floor(Date.now() / 1000);
}

module.exports = {
  checkEthBalance,
  checkErc20Balance,
  checkErc721Owernship,
  checkErc1155Balance,
  checkTreasure,
  sleep,
  nowInSecond,
};
