// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

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
    bytes32 public constant CAP_MANAGER_ROLE = keccak256("CAP_MANAGER_ROLE");

    /// @inheritdoc IDXIToken
    uint256 public constant INITIAL_SUPPLY = 10e9 * 1e18;

    /// @inheritdoc IDXIToken
    /// @dev 45 DXI tokens per second. Will limit emission up to ~14,20% in the first year.
    uint72 public constant MAX_MINT_CAP = 45 * 1e18;

    /// @inheritdoc IDXIToken
    uint72 public mintPerSecondCap = 0;

    /// @inheritdoc IDXIToken
    uint256 public lastMint;

    constructor(address initialMintDestination, address initialDefaultAdmin)
        ERC20(_NAME, _SYMBOL)
        ERC20Permit(_NAME)
        AccessControlDefaultAdminRules(5 days, initialDefaultAdmin)
    {
        _mint(initialMintDestination, INITIAL_SUPPLY);

        // we can safely set lastMint here since the emission manager is initialised after the token and won't hit the cap.
        lastMint = block.timestamp;
    }

    /// @inheritdoc IDXIToken
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        uint256 timeElapsedSinceLastMint = block.timestamp - lastMint;
        uint256 maxMint = timeElapsedSinceLastMint * mintPerSecondCap;
        //slither-disable-next-line timestamp
        if (amount > maxMint) revert MaxMintExceeded(maxMint, amount);

        lastMint = block.timestamp;
        _mint(to, amount);
    }

    /// @inheritdoc IDXIToken
    function updateMintCap(uint72 newCap) external onlyRole(CAP_MANAGER_ROLE) {
        if (newCap > MAX_MINT_CAP) revert MaxMintCapExceeded(MAX_MINT_CAP, newCap);

        emit MintCapUpdated(mintPerSecondCap, newCap);

        mintPerSecondCap = newCap;
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
