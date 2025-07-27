// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {MonkaBreak} from "../src/MonkaBreak.sol";

/**
 * @title Deploy Script for MonkaBreak
 * @notice Deploys the MonkaBreak contract to Monad blockchain
 */
contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        // Handle both formats: with and without 0x prefix
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        
        // Check if private key has 0x prefix, if not add it
        if (bytes(privateKeyStr).length == 64) {
            // No 0x prefix, add it
            string memory prefixedKey = string(abi.encodePacked("0x", privateKeyStr));
            deployerPrivateKey = vm.parseUint(prefixedKey);
        } else {
            // Already has 0x prefix or different format
            deployerPrivateKey = vm.parseUint(privateKeyStr);
        }
        
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        console.log("Deploying MonkaBreak contract...");
        console.log("Deployer address:", deployerAddress);
        console.log("Chain ID:", block.chainid);
        
        // Check deployer balance
        uint256 balance = deployerAddress.balance;
        console.log("Deployer balance:", balance / 1e18, "ETH");
        
        require(balance > 0.1 ether, "Insufficient balance for deployment");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MonkaBreak contract
        MonkaBreak monkaBreak = new MonkaBreak();

        console.log("==========================================");
        console.log("MonkaBreak deployed successfully!");
        console.log("Contract address:", address(monkaBreak));
        console.log("Deployer:", deployerAddress);
        console.log("Minimum entry fee:", monkaBreak.MIN_ENTRY_FEE() / 1e18, "MON");
        console.log("Block number:", block.number);
        console.log("==========================================");

        vm.stopBroadcast();
        
        // Verify contract is deployed correctly
        require(address(monkaBreak).code.length > 0, "Contract deployment failed");
        console.log("Contract deployment verified successfully");
    }
} 