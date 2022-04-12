// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// todo fail with require or return true/false? See "return true" in ERC20.sol 

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/// @title Base Token Contract.
/// @notice Base token should be extended by specific token contracts and each token should be owned by the controller
abstract contract ERC20MintableBurnable is ERC20, AccessControlEnumerable {

    /// @dev AccessControl role that gives access to mint() and burn().
    bytes32 public constant MINTER_BURNER_ROLE = keccak256("MINTER_BURNER_ROLE");

    /// @notice Constructor
    /// @param name_ Name of the Token
    /// @param symbol_ Symbol for the Token
    /// @param admin_ Address that will be granted the DEFAULT_ADMIN_ROLE.
    constructor(
        string memory name_,
        string memory symbol_,
        address admin_
    ) ERC20(name_, symbol_) {
        // Initialize the deployer account as the admin of this contract.
        _setupRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /// @dev See {ERC20-decimals}.
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /// @notice Mints `value` to the balance of `account`.
    /// @param account The address to add mint to.
    /// @param value The amount to mint.
    function mint(address account, uint256 value)
        public onlyRole(MINTER_BURNER_ROLE)
    {
        _mint(account, value);
    }

    /// @notice Burns `value` from the balance of `account`.
    /// @param account The address to add burn.
    /// @param value The amount to burn.
    function burn(address account, uint256 value)
        public onlyRole(MINTER_BURNER_ROLE)
    {
        _burn(account, value);
    }

}
