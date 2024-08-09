// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console, Test} from "forge-std/Test.sol";
import {OptimizationBank} from "../src/gas-optimization/OptimizationBank2.sol";

contract BankGasTest is Test {

    event Deposit(address user, uint256 amount);

    address private constant GUARD = address(1);
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address caro = makeAddr("caro");

    OptimizationBank public bank;

    function setUp() public {
        bank = new OptimizationBank();
        
    }

    function testOptimizationDeposit() public {
        // deposit
        deal(alice, 1 ether);
        vm.prank(alice);
        bank.deposit{value: 1 ether}(address(0), GUARD);

        deal(bob, 2 ether);
        vm.prank(bob);
        bank.deposit{value: 2 ether}(address(0), GUARD);

        deal(caro, 3 ether);
        vm.prank(caro);
        bank.deposit{value: 1.5 ether}(address(0), bob);

        (address[] memory users, uint256[] memory amounts) = bank.getTopKUsers(3);
        assertEq(users[0], bob);
        assertEq(amounts[0], 2 ether);
        assertEq(users[1], caro);
        assertEq(amounts[1], 1.5 ether);
        assertEq(users[2], alice);
        assertEq(amounts[2], 1 ether);

        // bob withdraw
        vm.prank(bob);
        bank.withdraw(1.5 ether, GUARD, alice);
        (address[] memory users2, uint256[] memory amounts2) = bank.getTopKUsers(3);
        assertEq(users2[0], caro);
        assertEq(amounts2[0], 1.5 ether);
        assertEq(users2[1], alice);
        assertEq(amounts2[1], 1 ether);
        assertEq(users2[2], bob);
        assertEq(amounts2[2], 0.5 ether);
    }

    function testWithdrwaInsufficientBalance() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);
        bank.deposit{value: 1 ether}(GUARD, GUARD);
        vm.expectRevert("Insufficient balance");
        bank.withdraw(2 ether, GUARD, GUARD);
        vm.stopPrank();
    }
}