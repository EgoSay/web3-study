// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AutomationBank} from "../src/automation/AutomationBank.sol";

contract AutomationBankScript is Script {
    AutomationBank public bank;
    address public erc20Token;
    uint256 public constant TRIGGER_AMOUNT = 10e18;

    function setUp() public {
        erc20Token = address(0x2d606A6bd9d7f437231FcaaCb280CE211565baAf);
    }

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("deployer:", deployer);


        vm.startBroadcast();
        bank = new AutomationBank(erc20Token, TRIGGER_AMOUNT);
        console.log("deploy bank at address:", address(bank));
        vm.stopBroadcast();
    }
}
