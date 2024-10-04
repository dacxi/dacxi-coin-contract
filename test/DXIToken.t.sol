// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {DXIToken} from "../src/DXIToken.sol";
import {IDXIToken} from "../src/interfaces/IDXIToken.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IAccessControlDefaultAdminRules} from
    "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract DXITokenTest is Test {
    DXIToken public coin;

    function setUp() public {
        coin = new DXIToken(address(this), address(this));
    }

    function test_Name() public view {
        assertEq(coin.name(), "Dacxi Coin");
    }

    function test_Symbol() public view {
        assertEq(coin.symbol(), "DXI");
    }

    function test_InitialSupply() public view {
        assertEq(coin.INITIAL_SUPPLY(), 10e9 * 1e18);
        assertEq(coin.totalSupply(), 10e9 * 1e18);
    }

    function test_Mint() public {
        coin.grantRole(coin.MINTER_ROLE(), address(this));

        skip(1);

        coin.mint(address(this), 1e18);
        assertEq(coin.totalSupply(), 10e9 * 1e18 + 1e18);
    }

    function test_MintFromGuest() public {
        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);
        coin.mint(address(this), 1e18);
    }

    function test_Burn() public {
        coin.burn(1e18);
        assertEq(coin.totalSupply(), 10e9 * 1e18 - 1e18);
    }

    function test_BurnFromAccountWithoutBalance() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        vm.startPrank(vitalik);

        vm.expectPartialRevert(IERC20Errors.ERC20InsufficientBalance.selector);
        coin.burn(1e18);

        vm.startPrank(vitalik);
        assertEq(0, coin.balanceOf(msg.sender));

        assertEq(coin.totalSupply(), coin.balanceOf(address(this)));
    }

    function test_CannotSetAnotherAdmin() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        bytes32 adminRole = coin.DEFAULT_ADMIN_ROLE();

        vm.expectPartialRevert(IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminRules.selector);

        coin.grantRole(adminRole, vitalik);
    }

    function test_MinterRoleCanBeGranted() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        bytes32 minterRole = coin.MINTER_ROLE();

        coin.grantRole(minterRole, vitalik);
        assertTrue(coin.hasRole(minterRole, vitalik));
    }

    function test_MinterRoleCannotBeGrantedAfterLock() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        bytes32 minterRole = coin.MINTER_ROLE();

        coin.grantRole(minterRole, address(this));
        coin.lockMinterRole();

        vm.expectPartialRevert(IDXIToken.ForbiddenMinterRoleChange.selector);

        coin.grantRole(minterRole, vitalik);
        assertTrue(coin.hasRole(minterRole, address(this)));
        assertFalse(coin.hasRole(minterRole, vitalik));
    }

    function test_MinterRoleCanBeRevoked() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        bytes32 minterRole = coin.MINTER_ROLE();

        coin.grantRole(minterRole, vitalik);
        assertTrue(coin.hasRole(minterRole, vitalik));

        coin.revokeRole(minterRole, vitalik);
        assertFalse(coin.hasRole(minterRole, vitalik));
    }

    function test_MinterRoleCannotBeRevokedAfterLock() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        bytes32 minterRole = coin.MINTER_ROLE();

        coin.grantRole(minterRole, vitalik);
        assertTrue(coin.hasRole(minterRole, vitalik));

        coin.lockMinterRole();

        vm.expectPartialRevert(IDXIToken.ForbiddenMinterRoleChange.selector);

        coin.revokeRole(minterRole, vitalik);
        assertTrue(coin.hasRole(minterRole, vitalik));
    }

    function test_Nonce() public view {
        uint256 nonce = coin.nonces(address(this));
        assertEq(0, nonce);
    }
}
