# Digital Calibration Certificate (DCC) Project - Smart Contracts

---


## Overview

This project implements a decentralized system for issuing and registering Digital Calibration Certificates (DCCs) as non-fungible tokens (NFTs) on the blockchain. The architecture consists of two main smart contracts:

1.  **[`DCCNFT.sol`](src/DCCNFT.sol)**: An ERC721 contract that creates the NFTs representing the certificates. It includes access control features (`Ownable`) and the ability to pause operations (`Pausable`).

2.  **[`DCCRegistry.sol`](src/DCCRegistry.sol)**: The orchestrator contract that utilizes Chainlink Functions to validate off-chain information before authorizing the issuance of a new certificate by the `DCCNFT` contract.

This `README` serves as a comprehensive guide for developers on how to set up, test, and deploy the project's smart contracts using the Foundry framework.

---

## Project Structure

```
.
├── script/
│   ├── DeployDCCNFT.s.sol      # Script to deploy DCCNFT
│   ├── DeployDCCRegistry.s.sol # Script to deploy DCCRegistry
│   └── HelperConfig.s.sol      # Helper configuration script
├── src/
│   ├── DCCNFT.sol              # The NFT contract
│   └── DCCRegistry.sol         # Registry and orchestrator contract
├── test/
│   ├── DCCNFT.t.sol            # Tests for DCCNFT
│   └── DCCRegistry.t.sol       # Tests for DCCRegistry
├── .env.example                # Example environment file
├── foundry.toml                # Foundry configuration file
└── remappings.txt              # Foundry import remappings
```

---

## Contracts

### 1. `DCCNFT.sol`

This contract is responsible for the creation and management of the NFTs representing the Digital Calibration Certificates.

**Core Features:**

* **ERC721 Standard**: Implements the non-fungible token standard.
* **Ownable**: Only the contract owner can execute administrative functions, such as pausing the contract or setting the minter address.
* **Pausable**: The owner can pause all new token minting in case of an emergency.
* **Custom URI Storage**: Stores the URI for each certificate (pointing to an off-chain file, e.g., on IPFS) directly within the contract.
* **Designated Minter**: The issuance of new NFTs (`safeMint`) is restricted to the owner or to the designated minter to ensure only validated certificates are created.

### 2. `DCCRegistry.sol`

This contract acts as the brain of the system, orchestrating the validation of information before an NFT is issued.

**Core Features:**

* **Chainlink Functions Integration**: Sends requests to execute off-chain [JavaScript code](scripts_js/api.js) to validate data, such as the status of a calibration laboratory.
* **Access Control (`Ownable`)**: Only the owner can configure critical parameters, like the `DCCNFT` contract address and the Chainlink Functions source code.
* **Request Management**: Stores the state of each request sent to Chainlink Functions and ensures each is processed only once.
* **Callback Logic (`_fulfillRequest`)**: Processes the response from the oracle. If the validation is successful, it triggers the minting of a new NFT in the `DCCNFT` contract.

---

## Installation and Setup Guide

### Prerequisites
* [Foundry](https://getfoundry.sh/) installed.

### 1. Install Dependencies

Clone the repository and install the necessary dependencies (OpenZeppelin and Chainlink) using Foundry:

```bash
git clone https://github.com/calibrachain/calibra-contracts.git
cd calibra-contracts
forge install
```

The `forge install` command will read the `remappings.txt` file and download the required libraries into the `lib/` folder.

### 2. Compile

To compile all contracts in the project, run:

```bash
forge build
```

### 3. Run Tests

The project includes comprehensive test suites for both contracts.

#### Testing `DCCNFT.sol`
Tests are located in [test/DCCNFT.t.sol](test/DCCNFT.t.sol). To run them:

```bash
forge test --match-path test/DCCNFT.t.sol
```

#### Testing `DCCRegistry.sol`
Tests for the registry are in [test/DCCRegistry.t.sol](test/DCCRegistry.t.sol). To run them:

```bash
forge test --match-path test/DCCRegistry.t.sol
```

To run all tests in the project:
```bash
forge test
```
[[Test Evidence]](images/testes_evidence.png)

### 4. Deployment

Deployment is managed by Foundry scripts located in the `script/` folder.

#### Step 1: Set Up the Environment File (`.env`)

Before deploying, create a `.env` file in the project root. You can copy the `.env.example` file. This file must contain your private keys and RPC URLs.

**Example `.env` for the avalanche fuji network:**
```bash
#Avalanche Fuji Testnet
ROUTER_ADDRESS=0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0
DON_ID=0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000
SUBSCRIPTION_ID=your_subscription_id
#Your personal details
PRIVATE_KEY=your_private_key
RPC_URL=https://api.avax-test.network/ext/bc/C/rpc
ETHERSCAN_API_KEY=etherscan_api_key
```
**Important:** Add the `.env` file to your `.gitignore` to never commit your private keys.

#### Step 2: Execute the Deployment Scripts

**Deploying `DCCNFT.sol`**

Use the [DeployDCCNFT.s.sol](script/DeployDCCNFT.s.sol) script. This contract has no complex external dependencies.

```bash
forge script script/DeployDCCNFT.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

**Deploying `DCCRegistry.sol`**

This script, [DeployDCCRegistry.s.sol](script/DeployDCCRegistry.s.sol), uses [HelperConfig.s.sol](script/HelperConfig.s.sol) to fetch the correct parameters (Router address, DON ID, etc.) from your `.env` file.

```bash
forge script script/DeployDCCRegistry.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

After deployment, you will need to configure the interaction between the two contracts by calling `setNftContract()` on `DCCRegistry` with the address of the deployed `DCCNFT` contract.

Additionally, you will need to update the  deployed `DCCRegistry` contract address by calling `setMinterAddress` on `DCCNFT` contract.

Now, you can interact with the contracts.
