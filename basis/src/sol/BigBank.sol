// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "./Bank.sol";

contract BigBank is Bank {

    modifier checkEither {
        require (msg.value > 0.001 ether, "Deposit amount must be greater than 0.001 ether");
        _;
    }

    // 重写存款方法，添加存款金额要求
    function deposit() public virtual payable override checkEither {
        super.deposit();
    }
}