// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// ----------------------------- //
// --------- Imports ----------- //
// ----------------------------- //
import {Script, console} from "forge-std/Script.sol";
import {DCCRegistry} from "../src/DCCRegistry.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/**
 * @title Deployment Script for DCCRegistry
 * @notice This script handles the deployment of the DCCRegistry contract,
 * which orchestrates Chainlink Functions requests.
 */
contract DeployDCCRegistry is Script {
    // ----------------------------- //
    // ------ Main Function ------ //
    // ----------------------------- //

    /**
     * @notice Main entry point for the script execution.
     * @return registry The address of the deployed DCCRegistry contract.
     * @return config The deployment configuration used.
     */
    function run() external returns (address registry, HelperConfig config) {
        // Creates a new configuration contract to fetch network-specific variables.
        config = new HelperConfig();

        // Fetches the active network configuration.
        (
            address router,
            bytes32 donId,
            uint64 subscriptionId,
            uint256 deployerPrivateKey
        ) = config.activeNetworkConfig();

        // Starts the transaction broadcast. All subsequent contract calls
        // will be sent to the real network.
        vm.startBroadcast(deployerPrivateKey);

        // Deploys the DCCRegistry contract with network-specific parameters.
        // The deployer's address is set as the initial owner.
        address deployerAddress = vm.addr(deployerPrivateKey);
        DCCRegistry dccRegistry = new DCCRegistry(
            router,
            deployerAddress,
            donId,
            subscriptionId
        );

        // Stops the broadcast.
        vm.stopBroadcast();

        // Returns the address of the newly deployed contract.
        registry = address(dccRegistry);
    }
}
