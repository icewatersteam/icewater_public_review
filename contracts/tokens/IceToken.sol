// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/FixedPoint.sol";
import "../config/Constants.sol";
import "../abstract/ERC20Reward.sol";

/// @title ICE Token Contract (Token for measuring stability).
/// Extends the {ERC20Reward} contract

contract IceToken is ERC20Reward {
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    using SFixedPoint for int256;

    // transfer tax
    uint256 _dTransferTax = D_ICE_TRANSFER_TAX;

    /// @notice Constructor
    /// @param admin_ Address that will be granted the DEFAULT_ADMIN_ROLE.
    constructor(address admin_) ERC20Reward("ICE", "ICE", admin_) {
        _mint(msg.sender, D_INITIAL_ICE_SUPPLY);
    }

    /// @notice Applies a transfer tax to ICE to prevent use of ICE as the stable token which could disrupt its measurement function.
    /// @param from The `from` account in a transfer/burn and 0 when minting.
    /// @param to The `to` account in a transfer/minting or 0 when burning.
    /// @param amount The token amount being transferred, minted or burned.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // Burn the tax on a transfer (currently from reciever balance)
        if (from != address(0) && to != address(0) && _dTransferTax > 0) {
            uint256 burnAmount = _dTransferTax.mul(amount);
            _burn(to, burnAmount);
        }
    }

}
