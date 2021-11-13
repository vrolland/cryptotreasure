// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Bytes util library.
 * @notice Collection of utility functions to manipulate bytes
 */
library Bytes {
    /**
     * @dev Extract uint256 in a bytes from an index
     *
     * @param _bts bytes to extact the integer from
     * @param _from extraction starting from this index
     * @return uint256 integer extracted
     */
    function _bytesToUint256(bytes memory _bts, uint256 _from)
        internal
        pure
        returns (uint256)
    {
        require(_bts.length >= _from + 32, "e0");

        uint256 convertedUint256;
        uint256 startByte = _from + 32; //first 32 bytes denote the array length

        assembly {
            convertedUint256 := mload(add(_bts, startByte))
        }

        return convertedUint256;
    }

    /**
     * @dev Extract uint8 in a bytes from an index
     *
     * @param _bts bytes to extact the integer from
     * @param _from extraction starting from this index
     * @return uint8 integer extracted
     */
    function _bytesToUint8(bytes memory _bts, uint256 _from)
        internal
        pure
        returns (uint8)
    {
        require(_bts.length >= _from + 1, "e0");

        uint8 convertedUint8;
        uint256 startByte = _from + 1;

        assembly {
            convertedUint8 := mload(add(_bts, startByte))
        }
        
        return convertedUint8;
    }

    /**
     * @dev Extract address in a bytes from an index
     *
     * @param _bts bytes to extact the address from
     * @param _from extraction starting from this index
     * @return address extracted
     */
     function _bytesToAddress(bytes memory _bts, uint256 _from) internal pure returns (address) {
        require(_bts.length >= _from + 20, "e0");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bts, 0x20), _from)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

}
