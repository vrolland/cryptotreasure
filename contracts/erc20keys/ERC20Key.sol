// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ERC20 key to unlock specific treasure
 * @notice mintable only by admins, no approval needed for a contract (cryptotreasure)
 */
contract ERC20Key is ERC20, AccessControl {
    uint256 MAX_UINT;

    address public cryptotreasure;

    /**
     * @dev Constructor
     * @param cryptotreasure_ cryptotreasure address
     */
    constructor(address cryptotreasure_) ERC20("CryptoKey", "CKY") {
        cryptotreasure = cryptotreasure_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        unchecked {
            MAX_UINT = 2**256 - 1;
        }
    }

    function mint(address account, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mint(account, amount);
        _approve(account, cryptotreasure, MAX_UINT);
    }

    function mintMultiple(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 j = 0; j < accounts.length; j++) {
            _mint(accounts[j], amounts[j]);
            _approve(accounts[j], cryptotreasure, MAX_UINT);
        }
    }
}
