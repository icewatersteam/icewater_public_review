// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/** @title Fixed math library to deal with excess decimals.
    @notice Library includes signed and unsigned math to add or remove decimals as need to get the appropriate result.
*/
// TODO: We should make the 18 (or 1e18) a constant. The decimals set in the token contract should be based on this constant

/// Unsigned Fixed Point.
library UFixedPoint {
    /**
    @notice Multiplication of two 18 decimal numbers with 18 excess decimals removed from product.
    @param dA First factor to be multiplied.
    @param dB Second factor to be multiplied.
    @return uint256 Product.
    */
    function mul(uint256 dA, uint256 dB) internal pure returns (uint256) {
        return dA * dB / 1e18;
    }

    /**
    @notice Division of two 18 decimal numbers with 18 decimals add to quotient.
    @param dA Dividend.
    @param dB Divisor.
    @return uint256 Quotient.
    */
    function div(uint256 dA, uint256 dB) internal pure returns (uint256) {
        return 1e18 * dA / dB;
    }

    /**
    @notice Converts a number with 0 decimals to one with 18 decimals.
    @param iA Number to be converted.
    @return uint256 Result.
    */
    function toDecimal(uint256 iA) internal pure returns (uint256) {
        return iA * 1e18;
    }

    /**
    @notice Converts a number with 18 decimals to one with 0 decimals.
    @param dA Number to be converted.
    @return uint256 Result.
    */
    function toInteger(uint256 dA) internal pure returns (uint256) {
        return dA / 1e18;
    }

    /**
    @notice Returns the larger of two numbers.
    @param dA First number to be compared.
    @param dB Second number to be compared.
    @return uint256 Result.
    */
    function max(uint256 dA, uint256 dB) internal pure returns (uint256) {
       if (dA > dB) {
        return dA;
       }
       else {
        return dB;
       }
    }

    /**
    @notice Returns the smaller of two numbers.
    @param dA First number to be compared.
    @param dB Second number to be compared.
    @return uint256 Result.
    */
    function min(uint256 dA, uint256 dB) internal pure returns (uint256) {
       if (dA > dB) {
        return dB;
       }
       else {
        return dA;
       }
    }
}

/// Signed Fixed Point.
library SFixedPoint {
    /**
    @notice Multiplication of two 18 decimal numbers with 18 excess decimals removed from product.
    @param dA First factor to be multiplied.
    @param dB Second factor to be multiplied.
    @return int256 Product.
    */
    function mul(int256 dA, int256 dB) internal pure returns (int256) {
        return dA * dB / 1e18;
    }

    /**
    @notice Division of two 18 decimal numbers with 18 decimals add to quotient.
    @param dA Dividend.
    @param dB Divisor.
    @return int256 Quotient.
    */
    function div(int256 dA, int256 dB) internal pure returns (int256) {
        return 1e18 * dA / dB;
    }

    /**
    @notice Converts a number with 0 decimals to one with 18 decimals.
    @param iA Number to be converted.
    @return int256 Result.
    */
    function toDecimal(int256 iA) internal pure returns (int256) {
        return iA * 1e18;
    }

    /**
    @notice Converts a number with 18 decimals to one with 0 decimals.
    @param dA Number to be converted.
    @return int256 Result.
    */
    function toInteger(int256 dA) internal pure returns (int256) {
        return dA / 1e18;
    }

    /**
    @notice Returns the larger of two numbers.
    @param dA First number to be compared.
    @param dB Second number to be compared.
    @return int256 Result.
    */
    function max(int256 dA, int256 dB) internal pure returns (int256) {
       if (dA > dB) {
        return dA;
       }
       else {
        return dB;
       }
    }

    /**
    @notice Returns the smaller of two numbers.
    @param dA First number to be compared.
    @param dB Second number to be compared.
    @return int256 Result.
    */
    function min(int256 dA, int256 dB) internal pure returns (int256) {
       if (dA > dB) {
        return dB;
       }
       else {
        return dA;
       }
    }
}
