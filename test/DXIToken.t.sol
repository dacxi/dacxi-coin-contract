// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {DXIToken} from "../src/DXIToken.sol";
import {IDXIToken} from "../src/interfaces/IDXIToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

    function test_UpdateMintCap(address account, uint72 newCap) public cleanAddress(account) {
        vm.assume(newCap <= coin.MAX_MINT_CAP());

        coin.grantRole(coin.CAP_MANAGER_ROLE(), address(this));
        coin.grantRole(coin.MINTER_ROLE(), account);

        vm.expectEmit();
        emit IDXIToken.MintCapUpdated(0, newCap);
        coin.updateMintCap(newCap);
    }

    function test_UpdateMintCapRevertsWhenExceedsMaxMintCap(address account, uint72 newCap)
        public
        cleanAddress(account)
    {
        vm.assume(newCap > coin.MAX_MINT_CAP());

        coin.grantRole(coin.CAP_MANAGER_ROLE(), address(this));
        coin.grantRole(coin.MINTER_ROLE(), account);

        vm.expectPartialRevert(IDXIToken.MaxMintCapExceeded.selector);
        coin.updateMintCap(newCap);
    }

    function test_CanUpdateMintCapMultipleTimes(
        address account,
        uint72 newCap,
        uint72 newCap2,
        uint72 newCap3,
        uint8 timePassed
    ) public cleanAddress(account) {
        vm.assume(newCap <= coin.MAX_MINT_CAP());
        vm.assume(newCap2 <= coin.MAX_MINT_CAP());
        vm.assume(newCap3 <= coin.MAX_MINT_CAP());

        coin.grantRole(coin.CAP_MANAGER_ROLE(), address(this));
        coin.grantRole(coin.MINTER_ROLE(), account);

        vm.expectEmit();
        emit IDXIToken.MintCapUpdated(0, newCap);
        coin.updateMintCap(newCap);

        skip(timePassed);

        vm.expectEmit();
        emit IDXIToken.MintCapUpdated(newCap, newCap2);
        coin.updateMintCap(newCap2);

        skip(timePassed);

        vm.expectEmit();
        emit IDXIToken.MintCapUpdated(newCap2, newCap3);
        coin.updateMintCap(newCap3);
    }

    function test_MintRevertWithoutPermission(address account, uint256 amount) public {
        vm.assume(amount < type(uint256).max / 2);

        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);
        coin.mint(address(this), amount);

        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);
        coin.mint(account, amount);
    }

    function test_MintRevertIfNoCapIsSet(address account, uint256 amount, uint8 timePassed)
        public
        cleanAddress(account)
    {
        vm.assume(amount < type(uint256).max / 2);
        vm.assume(amount > 0);
        vm.assume(timePassed > 0);

        coin.grantRole(coin.MINTER_ROLE(), account);

        skip(timePassed);

        vm.prank(account);
        vm.expectPartialRevert(IDXIToken.MaxMintExceeded.selector);
        coin.mint(account, amount);
    }

    function test_MintRevertIfAmountExceedsCap(address account, uint72 mintCap, uint256 amount, uint8 timePassed)
        public
        cleanAddress(account)
    {
        vm.assume(mintCap < coin.MAX_MINT_CAP());
        vm.assume(amount > (uint256(mintCap) * timePassed) && amount < type(uint256).max / 2);

        coin.grantRole(coin.CAP_MANAGER_ROLE(), address(this));
        coin.grantRole(coin.MINTER_ROLE(), account);

        vm.expectEmit();
        emit IDXIToken.MintCapUpdated(0, mintCap);
        coin.updateMintCap(mintCap);

        skip(timePassed);

        vm.prank(account);
        vm.expectPartialRevert(IDXIToken.MaxMintExceeded.selector);
        coin.mint(account, amount);
    }

    function test_Mint(address account, uint256 amount, uint72 mintCap, uint8 timePassed)
        public
        cleanAddress(account)
    {
        vm.assume(mintCap > 0 && mintCap <= coin.MAX_MINT_CAP());
        vm.assume(amount > 0 && amount <= (uint256(mintCap) * timePassed));

        coin.grantRole(coin.CAP_MANAGER_ROLE(), address(this));
        coin.grantRole(coin.MINTER_ROLE(), account);

        vm.expectEmit();
        emit IDXIToken.MintCapUpdated(0, mintCap);
        coin.updateMintCap(mintCap);

        skip(timePassed);

        vm.prank(account);
        vm.expectEmit();
        emit IERC20.Transfer(address(0), account, amount);
        coin.mint(account, amount);

        assertEq(coin.totalSupply(), INITIAL_SUPPLY + amount);
        assertEq(coin.balanceOf(account), amount);
    }

    function test_CanMintOncePerSecond(address account, uint256 amount, uint72 mintCap) public cleanAddress(account) {
        vm.assume(mintCap > 0 && mintCap <= coin.MAX_MINT_CAP());
        vm.assume(amount > 0 && amount <= mintCap);

        coin.grantRole(coin.CAP_MANAGER_ROLE(), address(this));
        coin.grantRole(coin.MINTER_ROLE(), account);

        console.log(block.timestamp);

        vm.expectEmit();
        emit IDXIToken.MintCapUpdated(0, mintCap);
        coin.updateMintCap(mintCap);

        vm.startPrank(account);

        skip(1);
        coin.mint(account, amount / 3);
        vm.expectPartialRevert(IDXIToken.MaxMintExceeded.selector);
        coin.mint(account, 1);

        skip(1);
        coin.mint(account, amount / 2);
        vm.expectPartialRevert(IDXIToken.MaxMintExceeded.selector);
        coin.mint(account, 1);

        skip(1);
        coin.mint(account, amount);
        vm.expectPartialRevert(IDXIToken.MaxMintExceeded.selector);
        coin.mint(account, 1);

        vm.stopPrank();

        assertEq(coin.totalSupply(), INITIAL_SUPPLY + (amount / 3) + (amount / 2) + amount);
        assertEq(coin.balanceOf(account), (amount / 3) + (amount / 2) + amount);
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
