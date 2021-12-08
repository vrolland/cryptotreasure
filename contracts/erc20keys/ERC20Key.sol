// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ERC20 key to unlock specific treasure
 * @notice mintable only by admins, no approval needed for a contract (cryptotreasure)
 */
contract ERC20Key is ERC20, AccessControl {
    address public cryptotreasure;

    /**
     * @dev Constructor
     * @param cryptotreasure_ cryptotreasure address
     */
    constructor(
        string memory name,
        string memory symbol,
        address cryptotreasure_
    ) ERC20(name, symbol) {
        cryptotreasure = cryptotreasure_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address account, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mint(account, amount);
    }

    function mintMultiple(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 j = 0; j < accounts.length; j++) {
            _mint(accounts[j], amounts[j]);
        }
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (_msgSender() == cryptotreasure) {
            _transfer(sender, recipient, amount);
        } else {
            super.transferFrom(sender, recipient, amount);
        }

        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        if (_msgSender() == cryptotreasure) {
            return type(uint256).max;
        } else {
            return super.allowance(owner, spender);
        }
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}
