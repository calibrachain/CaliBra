// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

/**
 * @title Helper Configuration Script
 * @notice Provides network-specific configuration for deployment scripts.
 * This approach keeps deployment logic clean and separates configuration.
 */
contract HelperConfig is Script {
    // Struct to hold configuration for a specific network.
    struct NetworkConfig {
        address router;
        bytes32 donId;
        uint64 subscriptionId;
        uint256 deployerPrivateKey;
    }

    // Active network configuration.
    NetworkConfig public activeNetworkConfig;

    constructor() {
        // Use vm.envOr to get values from the .env file.
        // If the variable is not set, it uses the default value.
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(
                0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
            )
        );
        address router = vm.envOr("ROUTER_ADDRESS", address(0)); // Must be set in .env
        bytes32 donId = vm.envOr("DON_ID", bytes32(0)); // Must be set in .env
        uint64 subscriptionId = uint64(vm.envOr("SUBSCRIPTION_ID", uint256(0))); // Must be set in .env

        // Check for missing required configurations
        if (router == address(0)) {
            revert("ROUTER_ADDRESS must be set in your .env file");
        }
        if (donId == bytes32(0)) {
            revert("DON_ID must be set in your .env file");
        }
        if (subscriptionId == 0) {
            revert("SUBSCRIPTION_ID must be set in your .env file");
        }

        activeNetworkConfig = NetworkConfig({
            router: router,
            donId: donId,
            subscriptionId: subscriptionId,
            deployerPrivateKey: deployerPrivateKey
        });
    }
}
