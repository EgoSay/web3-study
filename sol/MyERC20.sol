// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IBank {
    function onTransferReceived(address from, address to, uint256 amount) external returns (bool);
}

contract MyERC20 is ERC20 {

    constructor() ERC20 ("MyERC20", "CJW") {
        _mint(msg.sender,  10000 * 10 ** decimals());
    }

    function transferAndCall(address recipient, uint256 amount) public returns (bool)  {
        require(recipient != address(0), "invalid address");
        _transfer(msg.sender, recipient, amount);
        // if the address is a contract, try to notify it to receive
        if (isContract(recipient)) {
            bool rvResult = IBank(recipient).onTransferReceived(msg.sender, recipient, amount);
            require(rvResult, "the contract receive token failed");
        }
        return true;
    }

    // check if EOA
    function isContract(address user) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(user)
        }
        // eoa account have no codeHash
        return size > 0;
    }
}