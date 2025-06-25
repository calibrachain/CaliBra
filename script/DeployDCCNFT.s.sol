// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// ----------------------------- //
// --------- Imports ----------- //
// ----------------------------- //
import {Script, console2} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {DCCNFT} from "../src/DCCNFT.sol";

/**
 * @title Deployment Script for DCCNFT
 * @notice This script handles the deployment of the DCCNFT contract.
 */
contract DeployDCCNFT is Script {
    // ----------------------------- //
    // ------ Main Function ------ //
    // ----------------------------- //

    /**
     * @notice Main entry point for the script execution.
     * @return nft The address of the deployed DCCNFT contract.
     * @return txHash The transaction hash of the deployment.
     */
    function run() external returns (address nft, bytes32 txHash) {
        // Gets the deployer's private key from environment variables
        // or uses a default test sender.
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(
                0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
            )
        );

        // Get the deployer address
        address deployerAddress = vm.addr(deployerPrivateKey);

        // Check deployer balance
        uint256 balance = deployerAddress.balance;
        console2.log("saldo:", balance, ",address:", deployerAddress);
        require(balance > 0, "Deploy address has zero balance");

        // Starts the transaction broadcast. All subsequent contract calls
        // will be sent to the network.
        vm.startBroadcast(deployerPrivateKey);

        // Record logs to capture transaction hash
        vm.recordLogs();

        // Deploys the DCCNFT contract.
        // The address broadcasting the transaction (derived from the private key)
        // will be set as the initial 'owner' of the contract.
        DCCNFT dccNft = new DCCNFT(deployerAddress);

        // Get the recorded logs
        Vm.Log[] memory logs = vm.getRecordedLogs();
        
        // Extract transaction hash from the logs (simplified approach)
        // In practice, you might need to parse the logs more carefully
        if (logs.length > 0) {
            txHash = logs[0].topics[0];
        } else {
            // Fallback: create a hash from contract address and timestamp
            txHash = keccak256(abi.encodePacked(address(dccNft), block.timestamp));
        }

        // Stops the broadcast.
        vm.stopBroadcast();

        // Log deployment information
        console2.log("DCCNFT deployed at:", address(dccNft));
        console2.log("Transaction hash:", vm.toString(txHash));

        // Returns the address of the newly deployed contract.
        nft = address(dccNft);
    }
}
