// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @title Dacxi Token Migration
/// @author DacxiChain Labs (Bruno Gasparin, Jean Prado, Ricardo Hildebrand)
/// @notice This contract migrated $DACXI to $DXI in 1:1 ration
/// @custom:security-contact tech@dacxi.com
interface IDXITokenMigration {
    /// @notice emitted when an accounts migrate $DACXI to $DXI
    /// @param account account to be added
    /// @param amount amount to be migrated
    event Migrated(address indexed account, uint256 amount);

    /// @notice thrown when an invalid address is supplied
    error InvalidAddress();
    /// @notice thrown when DXI token address already set
    error DXITokenAddressAlreadySet();
    /// @notice thrown when DXI token address is not set
    error DXITokenAddressNotSet();
    /// @notice thrown when the address calling `migrate` is not in the whitelist
    /// @dev only thrown when the whitelist is enabled
    error AddressNotInWhitelist();

    /// @notice Address of the DACXI token
    /// @return dacxi Address of the DACXI token
    function dacxi() external view returns (IERC20);

    /// @notice Address of the DXI token
    /// @return dxi Address of the DXI token
    function dxi() external view returns (IERC20);

    /// @notice Set the $DXI contract address
    /// @dev the contract address can be set only once
    /// @param dxi_ $DXI contract address
    function setDXIToken(address dxi_) external;

    /// @notice This function allows for migrating DACXI tokens to DXI tokens
    /// @param amount amount of DACXI to migrate
    /// @dev The migration is a one-way process
    /// @dev Initially allow only set of addresses can migrate the tokens. Later the migration will be bepermissionless (see {IDXITokenMigration-disableWhitelist})
    function migrate(uint256 amount) external;

    /// @notice Add an account to the whitelist
    /// @param account account to include in the whitelist
    /// @dev only the contract owner can add an address
    function addToWhitelist(address account) external;

    /// @notice Remove an account from the whitelist
    /// @param account Account to remove from the whitelist
    /// @dev Only the contract owner can remove an address
    function removeFromWhitelist(address account) external;

    /// @notice Check if an address is in the whitelist
    /// @param account Account to check against whitelist
    /// @dev Only the contract owner can check against the whitelist
    function isInWhitelist(address account) external view returns (bool);

    /// @notice Disable the whitelist. This action is permanent and cannot be reverted.
    /// @dev only the contract owner can disalbe the whitelist
    /// @dev Disabling the whitelist, make the migration to be permissionless
    /// @dev Disabling the whitelist also renounces the owership of the contract make it immutable foverer
    function disableWhitelist() external;
}