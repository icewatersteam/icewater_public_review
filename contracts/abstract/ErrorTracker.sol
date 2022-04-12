// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../lib/FixedPoint.sol";

/** @title Tracks the PI error for a PI controller
    @notice Implements a controller for computing and managing the proportional and integral errors of a PI controller.  Could be modified to implement a PID.
    @dev Contract should be extended by another contract that will specify how to compute the error and compensate for it.
*/

abstract contract ErrorTracker {
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    using SFixedPoint for int256;

    // The last calculated error value.
    int256 private _dLastError;

    // The accumulated error value.
    int256 private _dAccumError;

    // The time of the last update of the PID
    uint256 private _iLastTime;

    /**
    @notice Constructor
    */
    constructor() {
        _iLastTime = block.timestamp;
    }

    /**
    @notice Returns the most recently computed proportional error.
    @return int256 The last proportional error with 18 decimals.
    */
    function getLastError() public view returns (int256) {
        return _dLastError;
    }

    /**
    @notice Returns the most recently computed integral (accumulated) error.
    @return int256 The last accumulated error with 18 decimals.
    */
    function getAccumulatedError() public view returns (int256) {
        return _dAccumError;
    }

    /**
    @notice Calculates the current (proportional) error.
    @dev Should be extended by another contract.
    @return int256 The calculated error.
    */
    function calculateError() internal virtual view returns (int256);

    /**
    @notice Takes action to compensate for the measured error.
    @dev Should be extended by another contract.
    @param dError Current (proportional) error with 18 decimals.
    @param dAccumError Accumulated error (integral of current error) with 18 decimals.
    @param iTimeDelta Time in seconds since the error was last calculated and applied.
    */
    function applyError(
        int256 dError,
        int256 dAccumError,
        uint256 iTimeDelta
    ) internal virtual;

    /**
    @notice Updates the current (proportional) error and accumulated (integral) error and stores the values.
    */
    function updateError() internal {
        //Avoid running PID multiple times in a block
        if (_iLastTime == block.timestamp) {
            return;
        }

        int256 iTimeDelta = int256(block.timestamp - _iLastTime);
        //Update last time (update before updating dAccumError to prevent reentrancy attack)
        _iLastTime = block.timestamp;

        // Calculate the errors.
        int256 dError = calculateError();
        int256 dAccumError = _dAccumError + dError * iTimeDelta;

        // Update errors
        _dLastError = dError;
        _dAccumError = dAccumError;     

        // Call the virtual function that applies the control variable.        
        applyError(dError, dAccumError, uint256(iTimeDelta));
    }
}