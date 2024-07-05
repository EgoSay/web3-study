// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "./Bank.sol";

contract BigBank is Bank {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier checkEither {
        require (msg.value > 0.001 ether, "Deposit amount must be greater than 0");
        _;
    }

    // 重写存款方法，添加存款金额要求
    function deposit() public virtual payable override checkEither {
        super.deposit();
    }

     // Transfers ownership of the contract to a new account (`newOwner`)
    function transferOwnership(address newOwner) public onlyOwner {
        require (newOwner != address(0), "newOwner must be a valid address");
        address oldOwner = _admin;
        _admin = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}