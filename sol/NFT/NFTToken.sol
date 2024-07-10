// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface INFTMarket {
    function onTransferReceived(address from, uint256 amount, bytes calldata data) external returns (bool);
}

contract MyERC20 is ERC20 {

    event Trade(address indexed from, address indexed to, uint256 amout);

    constructor() ERC20 ("MyERC20", "CJW") {
        _mint(msg.sender,  10000 * 10 ** decimals());
    }

    /**
     * transfer token and buy nft
     * @param {address} recipient EOA or nft market address
     * @param {uint256} amount payed token 
     * @param {bytes32} data maybe a nftContract address and tokenId, need decode
     * @return {*}
     */    
    function transferAndCall(address recipient, uint256 amount, bytes calldata data) public returns (bool)  {
        require(recipient != address(0), "invalid address");
        // if the address is a nft contract, try to notify it to receive
         _transfer(msg.sender, recipient, amount);
        if (isContract(recipient)) {
            require (INFTMarket(recipient).onTransferReceived(msg.sender, amount, data));
        } 
        emit Trade(msg.sender, recipient, amount);
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

    function decodePrice(bytes32 data) private pure returns (uint256) {
        uint256 result;
        assembly {
            result := mload(add(data, 32))
        }
        return result;
    }  
}