// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20, ERC20Permit, IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {
    AccessControlDefaultAdminRules,
    IAccessControl
} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {IDXIToken} from "./interfaces/IDXIToken.sol";

/// @title Dacxi Coin token
/// @author DacxiChain Labs (Bruno Gasparin, Jean Prado, Ricardo Hildebrand)
/// @notice This is the Dacxi Coin ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 1-to-1 representation between $DACXI and $DXI and allows for additional emission based on hub and treasury requirements
/// @custom:security-contact tech@dacxi.com
contract DXIToken is ERC20Permit, ERC20Burnable, AccessControlDefaultAdminRules, IDXIToken {
    string private constant _NAME = "Dacxi Coin";
    string private constant _SYMBOL = "DXI";

    /// @inheritdoc IDXIToken
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @inheritdoc IDXIToken
    uint256 public constant INITIAL_SUPPLY = 10e9 * 1e18;

    constructor(address initialMintDestination, address initialDefaultAdmin)
        ERC20(_NAME, _SYMBOL)
        ERC20Permit(_NAME)
        AccessControlDefaultAdminRules(5 days, initialDefaultAdmin)
    {
        _mint(initialMintDestination, INITIAL_SUPPLY);
    }

    /// @inheritdoc IDXIToken
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    ///
    /// Override AccessControlDefaultAdminRules role management
    ///

    /**
     * @dev See {ERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override(ERC20Permit, IERC20Permit) returns (uint256) {
        return super.nonces(owner);
    }
}
