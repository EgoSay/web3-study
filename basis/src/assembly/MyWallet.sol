// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract MyWallet { 
    string public  name;
    mapping (address => bool) private approved;
    address public owner;

    modifier auth {
        address _owner;
        assembly {
            // load from slot2
            _owner := sload(2)
        }
        require (msg.sender == _owner, "Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        owner = msg.sender;
    } 

    function transferOwernship(address _addr) public auth {
        require(_addr!=address(0), "New owner is the zero address");
        require(owner != _addr, "New owner is the same as the old owner");
        assembly {
            //  owner = _addr;
            //  store to slot2 
            sstore(2, _addr)
        }
    }
}