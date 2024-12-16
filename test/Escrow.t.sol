// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";
import {Moxie} from "../src/mock/Moxie.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EscrowTest is Test {
    Escrow public escrow;
    Moxie public moxie;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    // Alice FID => 111
    // Bob FID => 222

    event Deposit(uint256 indexed depositId, uint256 indexed fid, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);
    event Pause();
    event Unpause();

    function setUp() public {
        moxie = new Moxie();
        escrow = new Escrow(owner, address(moxie));

        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Send 10,000 MOXIE to alice & bob
        moxie.transfer(alice, 10_000 * 10**18);
        moxie.transfer(bob, 10_000 * 10**18);
    }

    function test_Deposit() public {
        uint256 aliceBalance = moxie.balanceOf(alice);
        assertEq(aliceBalance, 10_000 * 10**18);
        assertEq(moxie.balanceOf(address(escrow)), 0);

        vm.prank(alice);
        moxie.approve(address(escrow), 10_000 * 10**18);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Deposit(1, 111, 10_000 * 10**18);
        escrow.deposit(111, 10_000 * 10**18);

        assertEq(moxie.balanceOf(alice), 0);
        assertEq(moxie.balanceOf(address(escrow)), 10_000 * 10**18);
    }

    function test_Withdraw() public {
        vm.startPrank(alice);
        moxie.approve(address(escrow), 10_000 * 10**18);
        escrow.deposit(111, 10_000 * 10**18);
        vm.stopPrank();

        vm.startPrank(bob);
        moxie.approve(address(escrow), 5_000 * 10**18);
        escrow.deposit(222, 5_000 * 10**18);
        vm.stopPrank();

        assertEq(moxie.balanceOf(address(escrow)), 15_000 * 10**18);
        assertEq(moxie.balanceOf(owner), 0 * 10**18);

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(owner, 2500 * 10**18);
        escrow.withdraw(owner, 2500 * 10**18);
        vm.stopPrank();

        assertEq(moxie.balanceOf(address(escrow)), 12_500 * 10**18);
        assertEq(moxie.balanceOf(owner), 2500 * 10**18);

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(owner, 12_500 * 10**18);
        escrow.withdrawAll(owner);
        vm.stopPrank();

        assertEq(moxie.balanceOf(address(escrow)), 0 * 10**18);
        assertEq(moxie.balanceOf(owner), 15_000 * 10**18);
    }

    function test_Pause() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit Pause();
        escrow.pause();
        vm.stopPrank();

        // alice tries to deposit, reverts because the contract is paused
        vm.startPrank(alice);
        moxie.approve(address(escrow), 10_000 * 10**18);
        vm.expectRevert(Escrow.Paused.selector);
        escrow.deposit(111, 10_000 * 10**18);
        vm.stopPrank();

        // bob tries to unpause, reverts because he is not the owner
        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob));
        escrow.unpause();
        vm.stopPrank();

        // owner tries to pause, reverts because the contract is already paused
        vm.startPrank(owner);
        vm.expectRevert(Escrow.AlreadyPaused.selector);
        escrow.pause();
        vm.stopPrank();

        // owner unpauses
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit Unpause();
        escrow.unpause();
        vm.stopPrank();

        // alice deposits
        vm.startPrank(alice);
        moxie.approve(address(escrow), 10_000 * 10**18);
        escrow.deposit(111, 10_000 * 10**18);
        vm.stopPrank();
    }
}
