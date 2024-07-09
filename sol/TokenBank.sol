// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenBank {

    IERC20 token ;

    // Mapping to track the balance of each depositor
    mapping (address => uint) balances;

    constructor(address tokenAddr) {
        token = IERC20(tokenAddr);
    }

    // Event to log deposits
    event Deposit(address indexed from, address indexed to, uint256 amount);
    event Banlances(address  indexed user, uint256 amount);

    // Event to log withdraw
    event Withdraw(address indexed user, uint256 bankBalance, uint256 adminBanlance);

    modifier checkAmount(uint256 amount) {
        require (amount > 0, "amount must be greater than 0");
        _;
    }

    // transfer user token to the bank
    function deposit(uint256 amount) public virtual checkAmount(amount) {
        require (amount <= token.balanceOf(msg.sender), "Insufficient balance");
        // require 保证转账安全性
        require(token.transferFrom(msg.sender, address(this), amount), "TOKEN_TRANSFER_OUT_FAILED");
        balances[msg.sender] += amount;
        emit Deposit(msg.sender, address(this), amount);
        emit Banlances(msg.sender, balances[msg.sender]);
    }

    // withdraw amount token to the user wallet
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

    // the callback receives the token and records it
    function onTransferReceived(address from, address to, uint256 amount) public returns (bool) {
        balances[to] += amount;
        emit Deposit(from, to, amount);
        emit Banlances(to, balances[msg.sender]);
        return true;
    }
}