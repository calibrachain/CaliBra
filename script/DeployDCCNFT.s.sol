// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// ----------------------------- //
// --------- Imports ----------- //
// ----------------------------- //
import {Script, console2} from "forge-std/Script.sol";
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
     */
    function run() external returns (address nft) {
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

        // Deploys the DCCNFT contract.
        // The address broadcasting the transaction (derived from the private key)
        // will be set as the initial 'owner' of the contract.
        //address deployerAddress = vm.addr(deployerPrivateKey);
        DCCNFT dccNft = new DCCNFT(deployerAddress);

        // Stops the broadcast.
        vm.stopBroadcast();

        // Returns the address of the newly deployed contract.
        nft = address(dccNft);
    }
}
