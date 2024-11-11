// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDXITokenMigration} from "./interfaces/IDXITokenMigration.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title DXI Token Migration
/// @author DacxiChain Labs (Bruno Gasparin, Jean Prado, Ricardo Hildebrand)
/// @notice This is the migration contract for DACXI <-> DXIToken ERC20 token on Ethereum L1
/// @dev The contract allows for a 1-to-1 conversion from $DACXI into $DXI
/// @custom:security-contact tech@dacxi.com
contract DXITokenMigration is Ownable, IDXITokenMigration {
    using SafeERC20 for IERC20;

    /// @inheritdoc IDXITokenMigration
    IERC20 public immutable dacxi;

    /// @inheritdoc IDXITokenMigration
    IERC20 public dxi;

    // --- Whitelist ---
    bool public isWhitelistEnabled = true;
    mapping(address => bool) private whitelist;
    uint32 private constant WHITELIST_DISABLE_DELAY = 5 days;
    uint256 public whitelistDisableTimestamp = 0;

    /// @param dacxi_ $DACXI contract address
    constructor(address dacxi_) Ownable(msg.sender) {
        if (dacxi_ == address(0)) revert InvalidAddress();

        dacxi = IERC20(dacxi_);
    }

    /// @inheritdoc IDXITokenMigration
    function setDXIToken(address dxi_) external onlyOwner {
        if (dxi_ == address(0)) revert InvalidAddress();
        if (address(dxi) != address(0)) revert DXITokenAddressAlreadySet();

        emit DXITokenAdded(dxi_);

        dxi = IERC20(dxi_);
    }

    /// @inheritdoc IDXITokenMigration
    function migrate(uint256 amount) external {
        if (address(dxi) == address(0)) revert DXITokenAddressNotSet();
        if (!_whitelistHasAddress(msg.sender)) revert AddressNotInWhitelist();

        emit Migrated(msg.sender, amount);

        dacxi.safeTransferFrom(msg.sender, address(this), amount);
        dxi.safeTransfer(msg.sender, amount);
    }

    /// @inheritdoc IDXITokenMigration
    function addToWhitelist(address account) external onlyOwner {
        emit AddressWhitelistStatusChanged(account, true);

        whitelist[account] = true;
    }

    /// @inheritdoc IDXITokenMigration
    function removeFromWhitelist(address account) external onlyOwner {
        emit AddressWhitelistStatusChanged(account, false);

        whitelist[account] = false;
    }

    /// @inheritdoc IDXITokenMigration
    function isInWhitelist(address account) external view returns (bool) {
        return _whitelistHasAddress(account);
    }

    /// @inheritdoc IDXITokenMigration
    function checkMyWhitelistStatus() external view returns (bool) {
        return _whitelistHasAddress(_msgSender());
    }

    /// @inheritdoc IDXITokenMigration
    function initiateWhitelistDisable() external onlyOwner {
        whitelistDisableTimestamp = block.timestamp + WHITELIST_DISABLE_DELAY;

        emit WhitelistDisableInitiated(whitelistDisableTimestamp);
    }

    /// @inheritdoc IDXITokenMigration
    function finalizeWhitelistDisable() external onlyOwner {
        if (whitelistDisableTimestamp == 0) revert WhitelistDisabledNotInitiated();
        if (block.timestamp < whitelistDisableTimestamp) {
            revert WhitelistDisableEnforcedDelay(whitelistDisableTimestamp);
        }

        emit WhitelistDisabled();

        isWhitelistEnabled = false;
    }

    /// @inheritdoc IDXITokenMigration
    function cancelWhitelistDisable() external onlyOwner {
        if (whitelistDisableTimestamp == 0) revert WhitelistDisabledNotInitiated();

        emit WhitelistDisableCancelled();

        whitelistDisableTimestamp = 0;
    }

    /// @inheritdoc IDXITokenMigration
    function renounceOwnership() public override(Ownable, IDXITokenMigration) onlyOwner {
        if (isWhitelistEnabled) revert WhitelistNotDisabled();

        super.renounceOwnership();
    }

    /// @dev Check if an address is in the whitelist
    /// @param account account
    function _whitelistHasAddress(address account) private view returns (bool) {
        if (!isWhitelistEnabled) return true;

        return whitelist[account];
    }
}
