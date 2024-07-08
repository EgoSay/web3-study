// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface IBank {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

contract Ownable {

    address private _admin;

    constructor() {
        _admin = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == _admin, "Only admin can do this operation");
        _;
    }

    function withdraw(address bankAddr, uint256 amount) external onlyOwner {
        IBank(bankAddr).withdraw(amount);
    }

    receive() external payable {
    
    }
    fallback() external payable {
    }
}