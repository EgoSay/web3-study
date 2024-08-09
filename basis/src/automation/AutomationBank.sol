// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/v0.8/automation/AutomationCompatible.sol";


// 0x15a259c9367cd1B36030170e9e7d84232bA7Ee2D
contract AutomationBank is Ownable, AutomationCompatibleInterface {

    IERC20 token;
    // chainlin automation trigger amount
    uint256 public triggerAmount;
    uint256 public totalBalance; // bank balance
 
    // Mapping to track the balance of each depositor
    mapping (address => uint) balances;

    constructor(address tokenAddr, uint256 triggerAmount_) Ownable(msg.sender) {
        token = IERC20(tokenAddr);
        triggerAmount = triggerAmount_;
    }

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
        totalBalance += amount;
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
        totalBalance -= amount;
        emit Withdraw(msg.sender, balances[msg.sender], amount);
    }

    // get user balance
    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    // the callback receives the token and records it
    function onTransferReceived(address to, uint256 amount) external checkAmount(amount) returns (bool) {
        require(msg.sender == address(token), "invalid token address");
        balances[to] += amount;
        emit Deposit(msg.sender, to, amount);
        emit Banlances(to, balances[msg.sender]);
        return true;
    }

    function checkUpkeep(bytes calldata ) external view override returns (bool upkeepNeeded, bytes memory) {
       upkeepNeeded = totalBalance >= triggerAmount;
    }

   function performUpkeep(bytes calldata /* performData */) external override {
      // when bank balance over than trigger amount, transfer half of balance to owner
      if (totalBalance >= triggerAmount) {
          require(token.transfer(owner(), totalBalance / 2), "transfer failed");
          totalBalance = totalBalance / 2;
          emit AutomaticWithdraw(owner(), block.timestamp);
      }
   }

   // Event to log deposits
    event Deposit(address indexed from, address indexed to, uint256 amount);
    event Banlances(address  indexed user, uint256 amount);

    // Event to log withdraw
    event Withdraw(address indexed user, uint256 bankBalance, uint256 adminBanlance);
    event AutomaticWithdraw(address indexed user, uint256 timeStamp);
}