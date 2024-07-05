// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import "./Bank.sol";

contract Ownable {

    function withdraw(address bankAddr, uint256 amount) external {
        IBank(bankAddr).withdraw(amount);
    }

    receive() external payable {
    
    }
    fallback() external payable {
    }
}