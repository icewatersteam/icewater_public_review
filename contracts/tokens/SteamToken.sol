// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/Constants.sol";
import "../abstract/ERC20Reward.sol";

/// @title STEAM Token Contract (Token for controlling stability).
/// Extends the {ERC20Reward} contract

contract SteamToken is ERC20Reward{
   
    /// @notice Constructor
    /// @param admin_ Address that will be granted the DEFAULT_ADMIN_ROLE.
    constructor(address admin_) ERC20Reward("STEAM", "STEAM", admin_) {
        _mint(msg.sender, D_INITIAL_STM_SUPPLY);
    }

}
