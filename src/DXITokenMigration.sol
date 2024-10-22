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
    bool private isWhitelistEnabled = true;
    mapping(address => bool) private whitelist;

    /// @param dacxi_ $DACXI contract address
    constructor(address dacxi_) Ownable(msg.sender) {
        if (dacxi_ == address(0)) revert InvalidAddress();

        dacxi = IERC20(dacxi_);
    }

    /// @inheritdoc IDXITokenMigration
    function setDXIToken(address dxi_) external onlyOwner {
        if (dxi_ == address(0)) revert InvalidAddress();
        if (address(dxi) != address(0)) revert DXITokenAddressAlreadySet();

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
        whitelist[account] = true;
    }

    /// @inheritdoc IDXITokenMigration
    function removeFromWhitelist(address account) external onlyOwner {
        whitelist[account] = false;
    }

    /// @inheritdoc IDXITokenMigration
    function isInWhitelist(address account) external view onlyOwner returns (bool) {
        return _whitelistHasAddress(account);
    }

    /// @inheritdoc IDXITokenMigration
    function disableWhitelist() external onlyOwner {
        isWhitelistEnabled = false;

        renounceOwnership();
    }

    /// @dev Check if an address is in the whitelist
    /// @param account account
    function _whitelistHasAddress(address account) private view returns (bool) {
        if (!isWhitelistEnabled) return true;

        return whitelist[account];
    }
}
