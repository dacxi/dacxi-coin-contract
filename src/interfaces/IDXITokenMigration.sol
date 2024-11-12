// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @title Dacxi Token Migration
/// @author DacxiChain Labs (Bruno Gasparin, Jean Prado, Ricardo Hildebrand)
/// @notice This contract migrated $DACXI to $DXI in 1:1 ration
/// @custom:security-contact tech@dacxi.com
interface IDXITokenMigration {
    /// @notice emitted when the $DXI is set
    /// @param dxi_ token to be added
    event DXITokenAdded(address indexed dxi_);

    /// @notice emitted when an accounts migrate $DACXI to $DXI
    /// @param account account to be added
    /// @param amount amount to be migrated
    event Migrated(address indexed account, uint256 amount);

    /// @notice emitted when an account is added/removed to/from whitelist
    /// @param account account to be added/removed
    /// @param isWhitelisted is account whitelisted
    event AddressWhitelistStatusChanged(address indexed account, bool isWhitelisted);

    /// @notice emitted when whitelist is disabled
    event WhitelistDisabled();

    /// @notice emitted when disable whitelist process started
    event WhitelistDisableInitiated(uint256 timestamp);

    /// @notice emitted when disable whitelist process canceled
    event WhitelistDisableCancelled();

    /// @notice thrown when an invalid address is supplied
    error InvalidAddress();

    /// @notice thrown when DXI token address already set
    error DXITokenAddressAlreadySet();

    /// @notice thrown when DXI token address is not set
    error DXITokenAddressNotSet();

    /// @notice thrown when the address calling `migrate` is not in the whitelist
    /// @dev only thrown when the whitelist is enabled
    error AddressNotInWhitelist();

    /// @notice thrown when whitelist disable was not initiated
    error WhitelistDisabledNotInitiated();

    /// @notice thrown when admin tries to finalize the whitelist disable before the delay
    error WhitelistDisableEnforcedDelay(uint256 delay);

    /// @notice thrown when whitelist is not disabled
    error WhitelistNotDisabled();

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
    function isInWhitelist(address account) external view returns (bool);

    /// @notice Check if the sender address is in the whitelist
    function checkMyWhitelistStatus() external view returns (bool);

    /// @notice Return if the whitelist is enabled or not
    function isWhitelistEnabled() external view returns (bool);

    /// @notice Starts the process to disable the whitelist
    function initiateWhitelistDisable() external;

    /// @notice Finalize the whitelist disable process. This action is permanent and cannot be reverted.
    /// @dev only the contract owner can disalbe the whitelist
    /// @dev Disabling the whitelist, make the migration to be permissionless
    function finalizeWhitelistDisable() external;

    /// @notice Cancel an ongoing process to disable the whitelist
    function cancelWhitelistDisable() external;

    /// @notice Return when the admin can finalize the whitelist disable process
    function whitelistDisableTimestamp() external view returns (uint256);
}
