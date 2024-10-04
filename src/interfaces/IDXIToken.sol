// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IAccessControlDefaultAdminRules} from
    "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";

/// @title Dacxi Coin token
/// @author DacxiChain Labs (Bruno Gasparin, Jean Prado, Ricardo Hildebrand)
/// @notice This is the Dacxi Coin ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 1-to-1 representation between $DACXI and $DXI and allows for additional emission based on hub and treasury requirements
/// @custom:security-contact tech@dacxi.com
interface IDXIToken is IERC20, IERC20Permit, IAccessControlDefaultAdminRules {
    /**
     * @dev At least one of the following rules was violated:
     *
     * - The `MINTER_ROLE` could not be changed after `lockMinterRole` call.
     */
    error ForbiddenRoleChange();

    /// @notice mint token entrypoint for the emission manager contract
    /// @param to account to receive newly minted tokens
    /// @param amount amount to mint
    /// @dev The function only validates the sender, the emission manager is responsible for correctness
    function mint(address to, uint256 amount) external;

    /// @notice locks the `grantRole`/`revokeRole` method calls
    /// @dev After calling this method, you may not grant/revoke roles to any other addresses
    function lockRolesManagement() external;

    /// @notice Returns the initial amount of tokens in existence.
    //slither-disable-next-line naming-convention
    function INITIAL_SUPPLY() external view returns (uint256);

    /// @return the role that allows minting of tokens
    //slither-disable-next-line naming-convention
    function MINTER_ROLE() external view returns (bytes32);

    /// @return the flag locking the `grantRole`/`revokeRole`
    function rolesLocked() external view returns (bool);
}
