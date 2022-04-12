// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/Constants.sol";
import "../abstract/ERC20MintableBurnable.sol";

/// @title H2O Token Contract (Stable Token).
/// @notice Extends the {Token} contract.

contract H2OToken is ERC20MintableBurnable {

    /// @notice Constructor
    /// @param admin_ Address that will be granted the DEFAULT_ADMIN_ROLE.
    constructor(address admin_) ERC20MintableBurnable("H2O", "H2O", admin_) {
        _mint(msg.sender, D_INITIAL_H2O_SUPPLY);
    }

}
