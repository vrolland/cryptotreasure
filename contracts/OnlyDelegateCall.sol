// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Allows only delegate call
 */
contract OnlyDelegateCall {
    /// address of this very contract
    address private thisVeryContract;

    /**
     * @dev Constructor
     */
    constructor() {
        thisVeryContract = address(this);
    }
    
    /**
     * @dev Modifier throwing if the function is not called through a delegate call
     */
    modifier onlyDelegateCall() {
        require(address(this) != thisVeryContract, 'only delegateCall');
        _;
    }
}