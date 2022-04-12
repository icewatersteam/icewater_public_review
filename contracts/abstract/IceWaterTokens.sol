// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../tokens/IceToken.sol";
import "../tokens/H2OToken.sol";
import "../tokens/SteamToken.sol";

/// @title A Generic contract that holds an instance of each of the 3 Icewater tokens.
abstract contract IceWaterTokens {
    IceToken internal iceToken;
    H2OToken internal h2oToken;
    SteamToken internal stmToken;

    /// @notice Constructor
    constructor(IceToken iceToken_, H2OToken h2oToken_, SteamToken stmToken_) {
        iceToken = iceToken_;
        h2oToken = h2oToken_;
        stmToken = stmToken_;
    }
}