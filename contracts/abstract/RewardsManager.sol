// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/FixedPoint.sol";
import "../config/Constants.sol";
import "./IceWaterTokens.sol";

/** @title Rewards manager for rewards tokens.
    @notice Manages the claiming of rewards from rewards tokens.
    @dev Contract should be extended by another contract that will specify how to compute the error and compensate for it.
*/

abstract contract RewardsManager is IceWaterTokens {
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    using SFixedPoint for int256;

    // Amount of H2O per reward per token per second.
    uint256 public meltRate = D_INITIAL_MELT_RATE;
    uint256 public condensationRate = D_INITIAL_CONDENSATION_RATE;

    /**
    @notice Constructor
    @param iceToken_ ERC20 Token for Ice (Token for measuring stability)
    @param h2oToken_ ERC20 Token for H2O (Stable Token)
    @param stmToken_ ERC20 Token for STM (Token for controlling stability)
    */
    constructor(IceToken iceToken_, H2OToken h2oToken_, SteamToken stmToken_) 
        IceWaterTokens(iceToken_, h2oToken_, stmToken_)
    {}

    /**
    @notice Returns the rewards rate for ICE at an annual rate (e.g., annual interest rate).
    @return uint256 ICE annual rewards rate with 18 decimals.
    */
    function annualMeltRate() public view returns (uint256) {
        return meltRate * (365 days);
    }

    /**
    @notice Returns the rewards rate for STM at an annual rate (e.g., annual interest rate).
    @return uint256 STM annual rewards rate with 18 decimals.
    */
    function annualCondensationRate() public view returns (uint256) {
        return condensationRate * (365 days);
    }
    
    /**
    @notice Returns the amount of ICE rewards available for the sender.
    @return uint256 Amount of ICE rewards with 18 decimals.
    */
    function claimableH2OFromICE() public view returns (uint256) {
        return iceToken.claimableReward(msg.sender).mul(meltRate);
    }

    /**
    @notice Returns the amount of STM rewards available for the sender.
    @return uint256 Amount of STM rewards with 18 decimals.
    */
    function claimableH2OFromSTM() public view returns (uint256) {
        return stmToken.claimableReward(msg.sender).mul(
            condensationRate);
    }

    /**
    @notice Sends ICE and/or STM rewards to msg.sender in H2O.
    @param fromICE Boolean indicating whether ICE rewards should be claimed.
    @param fromSTM Boolean indicating whether STM rewards should be claimed.
    @return uint256 Amount of rewards claimed with 18 decimals.
    */
    function claimRewards(bool fromICE, bool fromSTM)
        public
        returns (uint256)
    {
        require(fromICE || fromSTM, "Claim has to be from ICE and/or STM.");

        uint256 dAmount;
        if (fromICE) {
            dAmount += iceToken.claimReward(msg.sender).mul(meltRate);
        } 
        
        if (fromSTM) {
            dAmount += stmToken.claimReward(msg.sender).mul(
                condensationRate);
        }

        // Mint H2O amount.
        h2oToken.mint(msg.sender, dAmount);

        // Callback to be implemented in derived classes
        onRewardsClaimed();

        return dAmount;
    }

    /**
    @notice Calls housekeeping functions when a user claims ICE/STM rewards.
    @dev Should be extended by another contract.
    */
    function onRewardsClaimed() internal virtual;
}
