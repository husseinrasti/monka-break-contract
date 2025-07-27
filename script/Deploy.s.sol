// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {MonkaBreak} from "../src/MonkaBreak.sol";

/**
 * @title Deploy Script for MonkaBreak
 * @notice Deploys the MonkaBreak contract to the specified network
 */
contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MonkaBreak monkaBreak = new MonkaBreak();

        console.log("MonkaBreak deployed to:", address(monkaBreak));

        vm.stopBroadcast();
    }
} 