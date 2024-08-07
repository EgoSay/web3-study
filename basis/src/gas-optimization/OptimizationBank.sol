// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract OptimizationBank is Ownable(msg.sender) {
 
    mapping(address => uint256) public balances;
    mapping(address => address) public nextUser;
    address public head;
    uint256 public constant MAX_TOP_USERS = 10;
    uint256 public topUsersCount;

    // receive ether and update top3 depositors
    function deposit() public virtual payable {
        require (msg.value > 1, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;

        // update top depositors
        _updateTopDepositors(msg.sender);

        emit Deposit(msg.sender, msg.value);
    }

    // withdraw amount
    function withdraw(uint256 amount) external {
        require (balances[msg.sender] >= amount, "Bank balance must be greater than withdram amount");
        balances[msg.sender] -= amount; 
        // transfer amount to user
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function _updateTopDepositors(address user) internal {
        uint256 userBalance = balances[user];
        address current = head;
        address previous = address(0);
        bool userFound = false;

        // Find the correct position for the user
        while (current != address(0) && balances[current] >= userBalance) {
            if (current == user) {
                userFound = true;
                break;
            }
            previous = current;
            current = nextUser[current];
        }

        if (userFound) {
            // User exists in the list
            if (previous == address(0)) {
                // User is already at the head, no need to move
                return;
            }
            // Remove user from current position
            removeUser(user, previous);
        } else if (topUsersCount == MAX_TOP_USERS && userBalance <= balances[current]) {
            // User doesn't qualify for top list
            return;
        }

        // Insert user at the correct position
        insertUser(user, userBalance);

        // Adjust topUsersCount if necessary
        if (!userFound && topUsersCount < MAX_TOP_USERS) {
            topUsersCount++;
        } else if (!userFound && topUsersCount == MAX_TOP_USERS) {
            // Remove the last user in the list
            address lastPrevious = head;
            while (nextUser[nextUser[lastPrevious]] != address(0)) {
                lastPrevious = nextUser[lastPrevious];
            }
            nextUser[lastPrevious] = address(0);
        }

        emit TopUsersUpdated(user, userBalance);
    }

    function removeUser(address user, address previous) internal {
        if (nextUser[previous] == user) {
            nextUser[previous] = nextUser[user];
        } else {
            address temp = nextUser[previous];
            while (nextUser[temp] != user) {
                temp = nextUser[temp];
            }
            nextUser[temp] = nextUser[user];
        }
    }


    function insertUser(address user, uint256 userBalance) internal {
        address current = head;
        address previous = address(0);

        while (current != address(0) && balances[current] > userBalance) {
            previous = current;
            current = nextUser[current];
        }

        if (previous == address(0)) {
            nextUser[user] = head;
            head = user;
        } else {
            nextUser[user] = current;
            nextUser[previous] = user;
        }
    }


    // getTopUsers
    function getTopUsers() public view returns (address[] memory, uint256[] memory) {
        address[] memory addrs = new address[](topUsersCount);
        uint256[] memory amounts = new uint256[](topUsersCount);

        address current = head;
        for (uint256 i = 0; i < topUsersCount; i++) {
            addrs[i] = current;
            amounts[i] = balances[current];
            current = nextUser[current];
        }
        return (addrs, amounts);
    }

    // get user balance
    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    receive() external payable {
        deposit();
    }
    fallback() external payable {
        deposit();
    }

     // Event to log deposits
    event Deposit(address user, uint256 amount);
    event TopUsersUpdated(address indexed user, uint256 newBalance);
    // Event to log withdrawals
    event Withdraw(address user, uint256 withdrawAmount);

}