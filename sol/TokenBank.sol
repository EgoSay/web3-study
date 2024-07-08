// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC20.sol";

contract TokenBank {

    BaseERC20 token;

    // Mapping to track the balance of each depositor
    mapping (address => uint) balances;

    constructor(address tokenAddr) {
        token = BaseERC20(tokenAddr);
    }

    // Event to log deposits
    event Deposit(address indexed user, uint256 amount);
    event Banlances(address  indexed user, uint256 amount);

    // Event to log withdraw
    event Withdraw(address indexed user, uint256 bankBalance, uint256 adminBanlance);

    modifier checkAmount(uint256 amount) {
        require (amount > 0, "amount must be greater than 0");
        _;
    }
    function deposit(uint256 amount) public virtual checkAmount(amount) {
        require (amount <= token.balanceOf(msg.sender), "Insufficient balance");
        // require 保证转账安全性
        require(token.transferFrom(msg.sender, address(this), amount), "TOKEN_TRANSFER_OUT_FAILED");
        balances[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
        emit Banlances(msg.sender, balances[msg.sender]);
    }

    // withdraw amount, only contract owner can do it
    function withdraw(uint256 amount) external checkAmount(amount) {
        // check bank has enough token
        require (balances[msg.sender] >= amount, "Bank balance must be greater than withdraw amount");
        // require 保证转账安全性
        require(token.transfer(msg.sender, amount), "withdraw failed");
        balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, balances[msg.sender], amount);
    }

    // get user balance
    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}