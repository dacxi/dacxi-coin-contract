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
    // address constant vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
    uint256 constant INITIAL_SUPPLY = 10e9 * 1e18;

    modifier cleanAddress(address account) {
        vm.assume(account != address(0));
        vm.assume(account != address(this));
        vm.assume(account != address(coin));
        _;
    }

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
        assertEq(coin.INITIAL_SUPPLY(), INITIAL_SUPPLY);
        assertEq(coin.totalSupply(), INITIAL_SUPPLY);
    }

    function test_MintRevertWithoutPermission(address account, uint256 amount) public {
        vm.assume(amount < type(uint256).max / 2);

        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);
        coin.mint(address(this), amount);

        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);
        coin.mint(account, amount);
    }

    function test_Mint(address account, uint256 amount) public cleanAddress(account) {
        vm.assume(amount < type(uint256).max / 2);

        coin.grantRole(coin.MINTER_ROLE(), account);

        skip(1);

        vm.prank(account);
        coin.mint(account, amount);
        assertEq(coin.totalSupply(), INITIAL_SUPPLY + amount);
        assertEq(coin.balanceOf(account), amount);
    }

    function test_Burn(address account, uint256 amount) public cleanAddress(account) {
        vm.assume(amount < INITIAL_SUPPLY);

        coin.transfer(account, amount);

        vm.prank(account);
        coin.burn(amount);

        assertEq(coin.totalSupply(), INITIAL_SUPPLY - amount);
    }

    function test_BurnFromAccountWithoutBalance(address account) public cleanAddress(account) {
        vm.prank(account);
        vm.expectPartialRevert(IERC20Errors.ERC20InsufficientBalance.selector);
        coin.burn(1e18);

        assertEq(0, coin.balanceOf(msg.sender));

        assertEq(coin.totalSupply(), coin.balanceOf(address(this)));
    }

    function test_CannotSetAnotherAdmin(address account) public {
        bytes32 adminRole = coin.DEFAULT_ADMIN_ROLE();

        vm.expectPartialRevert(IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminRules.selector);
        coin.grantRole(adminRole, account);
    }

    function test_MinterRoleCanBeGranted(address account) public {
        bytes32 minterRole = coin.MINTER_ROLE();

        coin.grantRole(minterRole, account);
        assertTrue(coin.hasRole(minterRole, account));
    }

    function test_MinterRoleCannotBeGrantedAfterAdminRenouce(address account, uint48 time) public {
        vm.assume(time > coin.defaultAdminDelay());

        bytes32 adminRole = coin.DEFAULT_ADMIN_ROLE();
        bytes32 minterRole = coin.MINTER_ROLE();

        coin.beginDefaultAdminTransfer(address(0));
        skip(time);

        coin.renounceRole(adminRole, address(this));

        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);
        coin.grantRole(minterRole, account);

        assertFalse(coin.hasRole(minterRole, account));
    }

    function test_MinterRoleCanBeRevoked(address account) public {
        bytes32 minterRole = coin.MINTER_ROLE();

        coin.grantRole(minterRole, account);
        assertTrue(coin.hasRole(minterRole, account));

        coin.revokeRole(minterRole, account);
        assertFalse(coin.hasRole(minterRole, account));
    }

    function test_MinterRoleCannotBeRevokedAfterAdminRenouce(address account, uint48 time) public {
        vm.assume(time > coin.defaultAdminDelay());

        bytes32 adminRole = coin.DEFAULT_ADMIN_ROLE();
        bytes32 minterRole = coin.MINTER_ROLE();

        coin.grantRole(minterRole, account);

        coin.beginDefaultAdminTransfer(address(0));

        skip(time);

        coin.renounceRole(adminRole, address(this));

        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);
        coin.revokeRole(minterRole, account);

        assertTrue(coin.hasRole(minterRole, account));
    }

    function test_RenounceDefaultAdminRoleRequiresTwoSteps(uint48 firstAttemptTime, uint48 time) public {
        vm.assume(firstAttemptTime <= coin.defaultAdminDelay());
        vm.assume(time > coin.defaultAdminDelay());

        bytes32 adminRole = coin.DEFAULT_ADMIN_ROLE();

        coin.beginDefaultAdminTransfer(address(0));

        skip(firstAttemptTime);
        vm.expectPartialRevert(IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminDelay.selector);
        coin.renounceRole(adminRole, address(this));
        assertTrue(coin.hasRole(adminRole, address(this)));

        skip(time - firstAttemptTime);
        coin.renounceRole(adminRole, address(this));
        assertFalse(coin.hasRole(adminRole, address(this)));
    }

    function test_MinterRoleCanBeRenouncedAfterAdminRenouce(address account, uint48 time) public {
        vm.assume(time > coin.defaultAdminDelay());

        bytes32 adminRole = coin.DEFAULT_ADMIN_ROLE();
        bytes32 minterRole = coin.MINTER_ROLE();

        coin.grantRole(minterRole, account);

        coin.beginDefaultAdminTransfer(address(0));
        skip(time);
        coin.renounceRole(adminRole, address(this));

        vm.prank(account);
        coin.renounceRole(minterRole, account);
        assertFalse(coin.hasRole(minterRole, account));

        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);
        coin.grantRole(minterRole, account);
    }

    function test_Nonce() public view {
        uint256 nonce = coin.nonces(address(this));
        assertEq(0, nonce);
    }
}
