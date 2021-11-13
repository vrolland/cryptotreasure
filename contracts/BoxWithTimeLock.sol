// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BoxProxy.sol";

/**
 * @title Box with a time lock
 * @notice A locked box cannot be withdrawn, stored and destroyed
 */
abstract contract BoxWithTimeLock is BoxProxy {
    /// Mapping from boxId to unlock timestamp
    mapping(uint256 => uint256) public _unlockTimestamp;

    event BoxLocked(uint256 indexed boxId, uint256 unlockTimestamp);

    /**
     * @dev Constructor
     * @param _baseBoxAddress boxBase address
     */
    constructor(address _baseBoxAddress) BoxProxy(_baseBoxAddress) {
    }

    /**
     * @dev lock a box until a timestamp
     *
     * @param boxId id of the box
     * @param timestamp unlock timestamp
     */
    function _lockBox(
        uint256 boxId,
        uint256 timestamp
    ) internal virtual {
        _unlockTimestamp[boxId] = timestamp;
        emit BoxLocked(boxId, timestamp);
    }

    /**
     * @dev executed before a withdraw
     * @notice forbid withdraw if box is locked
     *
     * @param boxId id of the box
     */
    function _beforeWithdraw(
        uint256 boxId
    ) internal override virtual {
        onlyNotLockedBox(boxId);
    }

    /**
     * @dev executed before a store
     * @notice forbid store if box is locked
     * @notice forbid store if crypto treasure has been destroyed (from BoxExternal)
     *
     * @param boxId id of the box
     */
    function _beforeStore(
        uint256 boxId
    ) internal override virtual {
        super._beforeStore(boxId);
        onlyNotLockedBox(boxId);
    }

    /**
     * @dev executed before a destroy
     * @notice forbid destroy if box is locked
     * @notice forbid destroy if crypto treasure has been destroyed (from BoxExternal)
     *
     * @param boxId id of the box
     */
    function _beforeDestroy(
        uint256 boxId
    ) internal override virtual {
        super._beforeDestroy(boxId);
        onlyNotLockedBox(boxId);
    }    

    /**
     * @dev Throw if box is locked
     *
     * @param boxId id of the box
     */
    function onlyNotLockedBox(uint256 boxId) internal view {
        require(_unlockTimestamp[boxId] <= block.timestamp, "e8");
    }
}
