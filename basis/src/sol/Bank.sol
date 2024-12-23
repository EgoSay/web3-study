// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract Bank  is Ownable(msg.sender){
    // define admin
    address internal _admin; 
    // Mapping to track the balance of each depositor
    mapping (address => uint) balances;
    // Array to store the addresses of the top 3 depositors
    address[3] private topDepositors;

    
    receive() external payable {
        deposit();
    }
    fallback() external payable {
        deposit();
    }

    // receive ether and update top3 depositors
    function deposit() public virtual payable {
        require (msg.value > 1, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;

        // refresh top3 depositors
        _updateTopDepositors(msg.sender);

        emit Deposit(msg.sender, msg.value);
    }

    // withdraw amount, only contract owner can do it
    function withdraw(uint256 amount) external onlyOwner {
        uint256 bankBalance = address(this).balance;
        require (bankBalance >= amount, "Bank balance must be greater than withdram amount");
        // transfer address balance to admin 
        payable(msg.sender).transfer(amount);
        
        emit Withdraw(msg.sender, bankBalance, msg.sender.balance);
    }

    function _updateTopDepositors(address user) internal {
        // if user is top, sort again
        for (uint i = 0; i < topDepositors.length; i++) {
            if (topDepositors[i] == user) {
                _sortTopDepositors();
                return;
            }
        }
        // if user banlance greater than the smallest balance in the top, update the array
        for(uint i = 0; i < topDepositors.length; i++) {
            if (balances[user] > balances[topDepositors[i]]) {
                for (uint j = 2; j > i; j--) {
                    topDepositors[j] = topDepositors[j - 1];
                }
                topDepositors[i] = user;
                break;
            }
        }

    }

    // Simple bubble sort for 3 elements
    function _sortTopDepositors() internal {
        for (uint256 i = 0; i < 2; i++) {
            for (uint256 j = 0; j < 2 - i; j++) {
                if (balances[topDepositors[j]] < balances[topDepositors[j + 1]]) {
                    address temp = topDepositors[j];
                    topDepositors[j] = topDepositors[j + 1];
                    topDepositors[j + 1] = temp;
                }
            }
        }
    }

    // get getTopDepositors
    function getTopDepositors() external view returns (address[3] memory) {
        return topDepositors;
    }

    // get user balance
    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function depositETH() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Event to log deposits
    event Deposit(address user, uint256 amount);
    // Event to log withdrawals
    event Withdraw(address user, uint256 bankBalance, uint256 adminBanlance);

}