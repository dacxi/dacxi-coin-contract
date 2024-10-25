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
    /// @notice emitted when the mint cap is updated
    /// @param oldCap the old mint cap
    /// @param newCap the new mint cap
    event MintCapUpdated(uint72 oldCap, uint72 newCap);

    /// @notice thrown when the mint per second cap exceeds the max allowed value
    /// @param maxMintCap the allowed mint per second cap
    /// @param mintCapRequested the mint cap requested 
    error MaxMintCapExceeded(uint72 maxMintCap, uint72 mintCapRequested);

    /// @notice thrown when the mint cap is exceeded
    /// @param maxMint the maximum amount of tokens that can be minted
    /// @param mintRequested the amount of tokens that were requested to be minted
    error MaxMintExceeded(uint256 maxMint, uint256 mintRequested);

    /// @notice mint token entrypoint for the emission manager contract
    /// @param to account to receive newly minted tokens
    /// @param amount amount to mint
    /// @dev The function only validates the sender, the emission manager is responsible for correctness
    function mint(address to, uint256 amount) external;

    /// @notice update the limit of tokens that can be minted per second
    /// @param newCap the amount of tokens in 18 decimals as an absolute value
    function updateMintCap(uint72 newCap) external;

    /// @return currentMintPerSecondCap the current amount of tokens that can be minted per second
    /// @dev initially set to 0
    function mintPerSecondCap() external view returns (uint72 currentMintPerSecondCap);

    /// @return lastMintTimestamp the timestamp of the last mint
    function lastMint() external view returns (uint256 lastMintTimestamp);

    /// @notice Returns the initial amount of tokens in existence.
    //slither-disable-next-line naming-convention
    function INITIAL_SUPPLY() external view returns (uint256);

    /// @notice Returns the max mint per second allowed to be set
    /// @dev It represents a inflation of a most equal to 15% at the first year
    //slither-disable-next-line naming-convention
    function MAX_MINT_CAP() external view returns (uint72);

    /// @return the role that allows minting of tokens
    //slither-disable-next-line naming-convention
    function MINTER_ROLE() external view returns (bytes32);

    /// @return the role that allows updating the mint cap
    //slither-disable-next-line naming-convention
    function CAP_MANAGER_ROLE() external view returns (bytes32);
}
