// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console, Test} from "forge-std/Test.sol";
import {Bank} from "../src/sol/Bank.sol";

contract BankTest is Test {

    event Deposit(address user, uint256 amount);

    address constant DEFAULT_ADDRESS = address(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);

    Bank public bank;

    function setUp() public {
        bank = new Bank();
        vm.deal(DEFAULT_ADDRESS, 10 ether);
    }

    function testDepositETH() public {
        vm.prank(DEFAULT_ADDRESS);

        uint amount = 8 ether;
        vm.expectEmit(true, true, false, true);
        emit Deposit(DEFAULT_ADDRESS, amount);
        
        bank.depositETH{value: amount}();
        uint256 banlance = bank.getUserBalance(DEFAULT_ADDRESS);
        console.log(DEFAULT_ADDRESS, banlance);
        assertEq(amount, banlance);
        
    }

    // test failed depositETH
    function testFailDepositETH() public {
        // Expect a revert due to insufficient Ether
        vm.expectRevert(bytes("Deposit amount must be greater than"));

        vm.prank(DEFAULT_ADDRESS);
        bank.depositETH();
    }
}