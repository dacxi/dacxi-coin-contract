// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {DXIToken} from "../src/DXIToken.sol";
import {DACXI} from "../test/fixtures/DACXI.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DXITokenMigration} from "../src/DXITokenMigration.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDXITokenMigration} from "../src/interfaces/IDXITokenMigration.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract DXITokenMigrationTest is Test {
    DACXI public dacxi;
    DXIToken public dxi;
    DXITokenMigration public migrator;
    address constant DACXI_TREASURY = 0x64513945265C096d0d6f83C0cb0A2Bdf852278cA;

    function setUp() public {
        vm.prank(DACXI_TREASURY);
        dacxi = new DACXI();

        migrator = new DXITokenMigration(address(dacxi));

        // all the initial ssupply will be sent to the migrator contract.
        dxi = new DXIToken(address(migrator), address(this));
    }

    modifier readyToMigrate() {
        migrator.setDXIToken(address(dxi));
        _;
    }

    modifier inWhitelist() {
        migrator.addToWhitelist(address(this));
        _;
    }

    modifier cleanAddress(address account) {
        vm.assume(account != address(0));
        vm.assume(account != address(this));
        vm.assume(account != address(dacxi));
        vm.assume(account != address(migrator));
        vm.assume(account != address(dxi));
        vm.assume(account != DACXI_TREASURY);
        _;
    }

    function test_ForbidCreatingContractWithoutValidDacxiAddress() public {
        DXITokenMigration migrator_;

        vm.expectRevert(IDXITokenMigration.InvalidAddress.selector);
        migrator_ = new DXITokenMigration(address(0));
    }

    function test_SetDXIToken(address dxi_) public {
        vm.assume(dxi_ != address(0));

        vm.expectEmit();
        emit IDXITokenMigration.DXITokenAdded(dxi_);

        migrator.setDXIToken(dxi_);

        assertEq(address(migrator.dxi()), address(dxi_));
    }

    function test_RevertIfSetDXITokenMoreThanOnce(address anotherToken) public {
        vm.assume(anotherToken != address(0));

        migrator.setDXIToken(address(dxi));

        vm.expectRevert(IDXITokenMigration.DXITokenAddressAlreadySet.selector);
        migrator.setDXIToken(address(dxi));

        vm.expectRevert(IDXITokenMigration.DXITokenAddressAlreadySet.selector);
        migrator.setDXIToken(address(anotherToken));
    }

    function test_OnlyOwnerCanSetDXIToken(address notOwner, address dxi_) public {
        vm.assume(notOwner != address(this));
        vm.assume(dxi_ != address(0));

        vm.prank(notOwner);
        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        migrator.setDXIToken(dxi_);
    }

    function test_ForbidSetDXITokenTo0Address() public {
        vm.expectRevert(IDXITokenMigration.InvalidAddress.selector);
        migrator.setDXIToken(address(0));
    }

    // --- migrate tests ---

    function test_Migrate(uint256 amount) public readyToMigrate inWhitelist {
        vm.assume(amount < dacxi.totalSupply());

        vm.prank(DACXI_TREASURY);
        dacxi.transfer(address(this), amount);

        dacxi.approve(address(migrator), amount);

        vm.expectEmit();
        emit IDXITokenMigration.Migrated(address(this), amount);

        migrator.migrate(amount);

        assertEq(dxi.balanceOf(address(this)), amount);
        assertEq(dacxi.balanceOf(address(this)), 0);
    }

    function test_MigrateDacxiTotalSupply() public readyToMigrate inWhitelist {
        uint256 totalSupply = dacxi.totalSupply();

        vm.prank(DACXI_TREASURY);
        dacxi.transfer(address(this), totalSupply);

        dacxi.approve(address(migrator), totalSupply);

        vm.expectEmit();
        emit IDXITokenMigration.Migrated(address(this), totalSupply);

        migrator.migrate(totalSupply);

        assertEq(dacxi.balanceOf(address(this)), 0);
        assertEq(dxi.balanceOf(address(this)), totalSupply);
    }

    function test_MigrateMultipleTimes(uint256 totalAmount, uint8 interactions) public readyToMigrate inWhitelist {
        vm.assume(interactions > 1);
        vm.assume(totalAmount < dacxi.totalSupply());

        vm.prank(DACXI_TREASURY);
        dacxi.transfer(address(this), totalAmount);

        uint256 migratedAmount = 0;
        uint256 amount = totalAmount / interactions;

        dacxi.approve(address(migrator), amount * interactions);
        for (uint8 i = 0; i < interactions; i++) {
            vm.expectEmit();
            emit IDXITokenMigration.Migrated(address(this), amount);

            migrator.migrate(amount);

            // advance in time
            vm.warp(interactions);

            migratedAmount += amount;
        }
        //
        assertEq(dacxi.balanceOf(address(this)), totalAmount - migratedAmount);
        assertEq(dxi.balanceOf(address(this)), migratedAmount);
    }

    function test_RevertMigrateIfNotInWhitelist(uint256 amount) public readyToMigrate {
        vm.assume(amount < dacxi.totalSupply());

        vm.prank(DACXI_TREASURY);
        dacxi.transfer(address(this), amount);

        dacxi.approve(address(migrator), amount);

        vm.expectRevert(IDXITokenMigration.AddressNotInWhitelist.selector);
        migrator.migrate(amount);

        assertEq(dacxi.balanceOf(address(this)), amount);
        assertEq(dxi.balanceOf(address(this)), 0);
    }

    function test_RevertMigrateWhenAmountMoreThanBalance(uint256 balance, uint256 amount)
        public
        readyToMigrate
        inWhitelist
    {
        vm.assume(amount < dacxi.totalSupply());
        vm.assume(balance < amount);

        vm.prank(DACXI_TREASURY);
        dacxi.transfer(address(this), balance);

        dacxi.approve(address(migrator), amount);

        vm.expectPartialRevert(IERC20Errors.ERC20InsufficientBalance.selector);
        migrator.migrate(amount);

        assertEq(dacxi.balanceOf(address(this)), balance);
        assertEq(dxi.balanceOf(address(this)), 0);
    }

    function test_RevertMigrateIfDXITokenIsNotSet(uint256 amount) public {
        uint256 initialDacxiBalance = dacxi.balanceOf(address(this));
        uint256 initialDxiBalance = dxi.balanceOf(address(this));

        vm.expectRevert(IDXITokenMigration.DXITokenAddressNotSet.selector);
        migrator.migrate(amount);

        assertEq(dacxi.balanceOf(address(this)), initialDacxiBalance);
        assertEq(dxi.balanceOf(address(this)), initialDxiBalance);
    }

    function test_AnyoneCanMigrateWhenWhitelistIsDisabled(address account, address account2, uint256 amount)
        public
        readyToMigrate
        cleanAddress(account)
        cleanAddress(account2)
    {
        vm.assume(amount < dacxi.totalSupply() / 2);
        vm.assume(account != address(0) && account2 != address(0));
        vm.assume(account != account2);

        migrator.initiateWhitelistDisable();
        skip(5 days);
        migrator.finalizeWhitelistDisable();

        vm.startPrank(DACXI_TREASURY);
        dacxi.transfer(account, amount);
        dacxi.transfer(account2, amount);
        vm.stopPrank();

        vm.startPrank(account);
        dacxi.approve(address(migrator), amount);
        vm.expectEmit();
        emit IDXITokenMigration.Migrated(account, amount);
        migrator.migrate(amount);
        vm.stopPrank();

        vm.startPrank(account2);
        dacxi.approve(address(migrator), amount);
        vm.expectEmit();
        emit IDXITokenMigration.Migrated(account2, amount);
        migrator.migrate(amount);
        vm.stopPrank();

        assertEq(dacxi.balanceOf(account), 0);
        assertEq(dxi.balanceOf(account), amount);
        assertEq(dacxi.balanceOf(account2), 0);
        assertEq(dxi.balanceOf(account2), amount);
    }

    function test_MigrateDacxiTotalSupplyWhenWhitelistIsDisabled(
        address account,
        address account2,
        address account3,
        uint256 amount
    ) public readyToMigrate cleanAddress(account) cleanAddress(account2) cleanAddress(account3) {
        vm.assume(amount < dacxi.totalSupply() / 2);
        vm.assume(account != account2 && account2 != account3 && account != account3);

        vm.startPrank(DACXI_TREASURY);
        dacxi.transfer(account, amount);
        dacxi.transfer(account2, amount);
        dacxi.transfer(account3, dacxi.totalSupply() - (amount * 2));
        vm.stopPrank();

        migrator.initiateWhitelistDisable();
        skip(5 days);
        migrator.finalizeWhitelistDisable();

        // --- start migration ---
        vm.startPrank(account);
        dacxi.approve(address(migrator), amount);
        vm.expectEmit();
        emit IDXITokenMigration.Migrated(account, amount);
        migrator.migrate(amount);
        vm.stopPrank();

        vm.startPrank(account2);
        dacxi.approve(address(migrator), amount);
        vm.expectEmit();
        emit IDXITokenMigration.Migrated(account2, amount);
        migrator.migrate(amount);
        vm.stopPrank();

        vm.startPrank(account3);
        dacxi.approve(address(migrator), dacxi.totalSupply() - (amount * 2));
        vm.expectEmit();
        emit IDXITokenMigration.Migrated(account3, dacxi.totalSupply() - (amount * 2));
        migrator.migrate(dacxi.totalSupply() - (amount * 2));
        vm.stopPrank();

        assertEq(dacxi.balanceOf(account), 0);
        assertEq(dxi.balanceOf(account), amount);
        assertEq(dacxi.balanceOf(account2), 0);
        assertEq(dxi.balanceOf(account2), amount);
        assertEq(dacxi.balanceOf(account3), 0);
        assertEq(dxi.balanceOf(account3), dacxi.totalSupply() - (amount * 2));

        assertEq(dacxi.balanceOf(account) + dacxi.balanceOf(account2) + dacxi.balanceOf(account3), 0);
        assertEq(dxi.balanceOf(account) + dxi.balanceOf(account2) + dxi.balanceOf(account3), dacxi.totalSupply());
    }

    // --- Whitelist functions ---

    function test_WhitelistStartsEmpty(address account, address account2, address account3) public view {
        assertFalse(migrator.isInWhitelist(account));
        assertFalse(migrator.isInWhitelist(account2));
        assertFalse(migrator.isInWhitelist(account3));
    }

    function test_IsInWhitelist(address account, address account2) public {
        vm.assume(account != account2);

        vm.expectEmit();
        emit IDXITokenMigration.AddressWhitelistStatusChanged(account, true);

        migrator.addToWhitelist(account);

        assertTrue(migrator.isInWhitelist(account));
        assertFalse(migrator.isInWhitelist(account2));
    }

    function test_CheckMyWhitelistStatus() public {
        assertFalse(migrator.checkMyWhitelistStatus());

        vm.expectEmit();
        emit IDXITokenMigration.AddressWhitelistStatusChanged(address(this), true);

        migrator.addToWhitelist(address(this));

        assertTrue(migrator.checkMyWhitelistStatus());
    }

    function test_CanAddAccountToWhitelistMultipleTimes(address account, address account2) public {
        vm.assume(account != account2);

        vm.expectEmit();
        emit IDXITokenMigration.AddressWhitelistStatusChanged(account, true);

        migrator.addToWhitelist(account);

        assertTrue(migrator.isInWhitelist(account));
        assertFalse(migrator.isInWhitelist(account2));

        migrator.addToWhitelist(account);

        assertTrue(migrator.isInWhitelist(account));
        assertFalse(migrator.isInWhitelist(account2));
    }

    function test_CanAddMultipleAccountToWhitelist(address account, address account2, address account3) public {
        vm.assume(account != account2 && account2 != account3 && account != account3);

        vm.expectEmit();
        emit IDXITokenMigration.AddressWhitelistStatusChanged(account, true);

        migrator.addToWhitelist(account);

        vm.expectEmit();
        emit IDXITokenMigration.AddressWhitelistStatusChanged(account2, true);

        migrator.addToWhitelist(account2);

        assertTrue(migrator.isInWhitelist(account));
        assertTrue(migrator.isInWhitelist(account2));
        assertFalse(migrator.isInWhitelist(account3));
    }

    function test_OnlyOwnerCanAddToWhitelist(address notOwner, address account) public {
        vm.assume(notOwner != address(this));
        vm.assume(address(this) != account);

        vm.prank(notOwner);
        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        migrator.addToWhitelist(account);

        assertFalse(migrator.isInWhitelist(account));
    }

    function test_RemoveFromWhitelist(address account, address account2) public {
        vm.assume(account != account2);
        migrator.addToWhitelist(account);

        assertTrue(migrator.isInWhitelist(account));
        assertFalse(migrator.isInWhitelist(account2));

        vm.expectEmit();
        emit IDXITokenMigration.AddressWhitelistStatusChanged(account, false);

        migrator.removeFromWhitelist(account);

        assertFalse(migrator.isInWhitelist(account));
        assertFalse(migrator.isInWhitelist(account2));
    }

    function test_NothingHappensWhenRemovingFromWhitelistANonWhitelistedddress(address account) public {
        assertFalse(migrator.isInWhitelist(account));

        vm.expectEmit();
        emit IDXITokenMigration.AddressWhitelistStatusChanged(account, false);

        migrator.removeFromWhitelist(account);

        assertFalse(migrator.isInWhitelist(account));
    }

    function test_OnlyOwnerCanRemoveFromWhitelist(address notOwner, address account) public {
        vm.assume(notOwner != address(this));

        migrator.addToWhitelist(account);

        vm.prank(notOwner);

        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        migrator.removeFromWhitelist(account);
    }

    function test_InitiateDisableWhitelistEmitsEvent() public {
        vm.expectEmit();
        emit IDXITokenMigration.WhitelistDisableInitiated(block.timestamp + 5 days);

        migrator.initiateWhitelistDisable();
        assertGt(migrator.whitelistDisableTimestamp(), 0);
        assertTrue(migrator.isWhitelistEnabled());
    }

    function test_DisablingWhitelistCanBeFinalizedOnlyAfterDeadline(uint256 delay) public {
        vm.assume(delay < 5 days);

        migrator.initiateWhitelistDisable();
        assertGt(migrator.whitelistDisableTimestamp(), 0);
        assertTrue(migrator.isWhitelistEnabled());

        skip(delay);

        vm.expectPartialRevert(IDXITokenMigration.WhitelistDisableEnforcedDelay.selector);
        migrator.finalizeWhitelistDisable();
        assertTrue(migrator.isWhitelistEnabled());
    }

    function test_DisablingWhitelistCanBeFinalizedOnlyAfterStarted(uint256 delay) public {
        vm.assume(delay >= 5 days);
        vm.assume(delay < 365 days);

        assertEq(migrator.whitelistDisableTimestamp(), 0);
        assertTrue(migrator.isWhitelistEnabled());

        skip(delay);

        vm.expectRevert(IDXITokenMigration.WhitelistDisabledNotInitiated.selector);
        migrator.finalizeWhitelistDisable();
        assertTrue(migrator.isWhitelistEnabled());
    }

    function test_DisablingWhitelistCanBeCanceledBeforeDeadline(uint256 delay) public {
        vm.assume(delay < 5 days);

        migrator.initiateWhitelistDisable();
        assertGt(migrator.whitelistDisableTimestamp(), 0);
        assertTrue(migrator.isWhitelistEnabled());

        skip(delay);

        vm.expectEmit();
        emit IDXITokenMigration.WhitelistDisableCancelled();

        migrator.cancelWhitelistDisable();
        assertEq(migrator.whitelistDisableTimestamp(), 0);
        assertTrue(migrator.isWhitelistEnabled());
    }

    function test_DisablingWhitelistCanBeCanceledAfterDeadline(uint256 delay) public {
        vm.assume(delay >= 5 days);
        vm.assume(delay <= 365 days);

        migrator.initiateWhitelistDisable();
        assertGt(migrator.whitelistDisableTimestamp(), 0);
        assertTrue(migrator.isWhitelistEnabled());

        skip(delay);

        vm.expectEmit();
        emit IDXITokenMigration.WhitelistDisableCancelled();

        migrator.cancelWhitelistDisable();
        assertEq(migrator.whitelistDisableTimestamp(), 0);
        assertTrue(migrator.isWhitelistEnabled());
    }

    function test_DisablingWhitelistCanBeCancelledOnlyAfterStarted(uint256 delay) public {
        vm.assume(delay > 5 days);
        vm.assume(delay < 365 days);

        assertEq(migrator.whitelistDisableTimestamp(), 0);
        assertTrue(migrator.isWhitelistEnabled());

        skip(delay);

        vm.expectRevert(IDXITokenMigration.WhitelistDisabledNotInitiated.selector);
        migrator.cancelWhitelistDisable();
        assertTrue(migrator.isWhitelistEnabled());
    }

    // --- Renounce ownership tests ---

    function test_RenoucesOwnershipOnlyAfterDisablingWhitelist() public {
        assertTrue(migrator.isWhitelistEnabled());

        vm.expectRevert(IDXITokenMigration.WhitelistNotDisabled.selector);
        migrator.renounceOwnership();
    }

    function test_RenouncesTheOwnership(address account) public {
        migrator.initiateWhitelistDisable();
        skip(5 days);
        migrator.finalizeWhitelistDisable();
        skip(1);

        migrator.renounceOwnership();

        assertNotEq(migrator.owner(), address(this));

        // -- check all methods that ony the owner can call
        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        migrator.addToWhitelist(account);

        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        migrator.removeFromWhitelist(account);

        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        migrator.setDXIToken(address(dxi));

        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        migrator.initiateWhitelistDisable();

        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        migrator.cancelWhitelistDisable();

        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        migrator.finalizeWhitelistDisable();
    }
}
