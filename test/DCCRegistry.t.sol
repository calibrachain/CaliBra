// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// ----------------------------- //
// --------- Imports ----------- //
// ----------------------------- //
import {Test, console} from "forge-std/Test.sol";
import {DCCRegistry} from "../src/DCCRegistry.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_X/FunctionsClient.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// ------------------------------------ //
// -------- Mock Contracts ---------- //
// ------------------------------------ //

/**
 * @notice A mock DCCNFT contract to simulate interactions.
 */
contract MockDCCNFT {
    // --- Events ---
    event Minted(address recipient, string uri);

    bool private s_shouldRevert = false;
    address public s_lastRecipient;
    string public s_lastURI;

    function setShouldRevert(bool _shouldRevert) external {
        s_shouldRevert = _shouldRevert;
    }

    function safeMint(
        address _recipient,
        string memory _uri
    ) external returns (uint256) {
        if (s_shouldRevert) {
            revert("Minting failed as requested by test");
        }
        s_lastRecipient = _recipient;
        s_lastURI = _uri;
        emit Minted(_recipient, _uri);
    }
}

// ------------------------------------ //
// ----------- Test Contract ---------- //
// ------------------------------------ //

/**
 * @title Test for the DCCRegistry Contract
 * @notice This contract tests all the main functionalities of DCCRegistry.
 */
contract DCCRegistryTest is Test {
    // ----------------------------- //
    // ------- State Variables ----- //
    // ----------------------------- //
    DCCRegistry private dccRegistry;
    MockDCCNFT private mockNft;

    // Addresses for simulating roles
    address private constant OWNER = address(0x1); // Contract Owner
    address private constant ROUTER = address(0x2); // Mock Chainlink Functions Router
    address private constant USER_A = address(0x3); // A random user

    // Chainlink Functions configuration
    bytes32 private constant DON_ID =
        0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000; // Mock DON ID
    uint64 private constant SUBSCRIPTION_ID = 1;

    // JS source code for requests
    string private constant SAMPLE_JS_CODE =
        "return Functions.encodeUint256(1);";

    string private constant SAMPLE_URI =
        "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi";
    // ----------------------------- //
    // ----------- Setup ----------- //
    // ----------------------------- //

    /**
     * @notice Setup run before each test.
     * Deploys a new DCCRegistry and a mock NFT contract.
     */
    function setUp() public {
        // Deploy the mock NFT contract
        mockNft = new MockDCCNFT();

        // Deploy the main contract to be tested
        dccRegistry = new DCCRegistry(ROUTER, OWNER, DON_ID, SUBSCRIPTION_ID);

        // Configure the DCCRegistry contract as the owner
        vm.startPrank(OWNER);
        dccRegistry.setNftContract(address(mockNft));
        dccRegistry.setSourceCode(SAMPLE_JS_CODE);
        vm.stopPrank();
    }

    // ----------------------------- //
    // ---- Constructor Tests ---- //
    // ----------------------------- //

    function test_InitialState() public view {
        assertEq(
            dccRegistry.owner(),
            OWNER,
            "Initial owner should be set correctly"
        );
        // We can't check immutable variables directly, but their usage in tests confirms they are set.
    }

    // ------------------------------------ //
    // ---- Access Control Tests -------- //
    // ------------------------------------ //

    function test_OwnerCanSetNftContract() public {
        vm.prank(OWNER);
        address newNftAddress = address(0xdeadbeef);
        dccRegistry.setNftContract(newNftAddress);
        // Can't view s_nftContract directly, so we test its effect in other functions.
        // This test ensures the call itself doesn't revert for the owner.
    }

    function test_Fail_SetNftContractByNonOwner() public {
        vm.prank(USER_A);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER_A
            )
        );
        dccRegistry.setNftContract(address(mockNft));
    }

    function test_Fail_SetNftContractToZeroAddress() public {
        vm.prank(OWNER);
        vm.expectRevert(DCCRegistry.InvalidAddress.selector);
        dccRegistry.setNftContract(address(0));
    }

    function test_OwnerCanSetSourceCode() public {
        vm.prank(OWNER);
        string memory newCode = "const newCode = true;";
        dccRegistry.setSourceCode(newCode);
        // Can't view s_source_code directly, this test ensures the call doesn't revert.
    }

    function test_Fail_SetSourceCodeByNonOwner() public {
        vm.prank(USER_A);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER_A
            )
        );
        dccRegistry.setSourceCode("let x = 1;");
    }

    // ------------------------------------ //
    // ---- Request Sending Tests ------- //
    // ------------------------------------ //

    function test_SuccessVerifyAndMint() public {
        vm.startPrank(OWNER);

        string[] memory args = new string[](2);
        args[0] = "1";
        args[1] = SAMPLE_URI;

        // We can't match the requestId, so we check for the event name only
        vm.expectEmit(true, false, false, false);
        emit DCCRegistry.FunctionsRequestSent(bytes32(0));

        bytes32 requestId = dccRegistry.verifyAndMint(args);
        assertTrue(requestId != 0, "Request ID should not be zero");

        vm.stopPrank();
    }

    function test_Fail_VerifyAndMintWithInvalidArguments() public {
        vm.prank(OWNER);
        string[] memory args = new string[](1); // Invalid length
        args[0] = "1";

        vm.expectRevert(DCCRegistry.InvalidArguments.selector);
        dccRegistry.verifyAndMint(args);
    }

    // ------------------------------------ //
    // ---- Fulfillment (Callback) Tests -- //
    // ------------------------------------ //

    function test_FulfillRequest_Success_And_MintSuccess() public {
        // 1. Send a request to get a valid ID
        vm.prank(USER_A);
        string[] memory args = new string[](2);
        args[0] = "1";
        args[1] = SAMPLE_URI;
        bytes32 requestId = dccRegistry.verifyAndMint(args);

        // 2. Prepare the successful response from the oracle (laboratory is active)
        bytes memory response = abi.encode(uint256(1));

        // 3. Ensure the mock NFT will not revert
        mockNft.setShouldRevert(false);

        // 4. Simulate the callback from the Chainlink Router
        vm.startPrank(ROUTER);
        vm.expectEmit(false, false, false, true);
        emit DCCRegistry.Response(requestId, 1);

        // This is the function the router calls on the client contract
        dccRegistry.handleOracleFulfillment(requestId, response, "");
        vm.stopPrank();

        // 5. Check that the mint was called on the mock NFT
        // The recipient is msg.sender of the fulfillment call, which is the user A random
        assertEq(
            mockNft.s_lastRecipient(),
            USER_A,
            "Mock NFT recipient should be user A"
        );
    }

    function test_FulfillRequest_Success_And_MintFails() public {
        vm.prank(USER_A);
        string[] memory args = new string[](2);
        args[0] = "1";
        args[1] = SAMPLE_URI;
        bytes32 requestId = dccRegistry.verifyAndMint(args);

        bytes memory response = abi.encode(uint256(1));

        // Configure mock NFT to fail the minting process
        mockNft.setShouldRevert(true);

        vm.startPrank(ROUTER);
        vm.expectEmit(true, false, false, true);
        emit DCCRegistry.MintingFailed(requestId);

        dccRegistry.handleOracleFulfillment(requestId, response, "");
        vm.stopPrank();
    }

    function test_FulfillRequest_LaboratoryInactive() public {
        vm.prank(USER_A);
        string[] memory args = new string[](2);
        args[0] = "1";
        args[1] = SAMPLE_URI;
        bytes32 requestId = dccRegistry.verifyAndMint(args);

        // Simulate a response where the laboratory is not active (value != 1)
        bytes memory response = abi.encode(uint256(0));

        vm.startPrank(ROUTER);
        vm.expectEmit(false, false, false, true);
        emit DCCRegistry.LaboratoryInactive(
            requestId,
            "Laboratory reported as not active"
        );

        dccRegistry.handleOracleFulfillment(requestId, response, "");
        vm.stopPrank();
    }

    function test_FulfillRequest_ChainlinkError() public {
        vm.prank(USER_A);
        string[] memory args = new string[](2);
        args[0] = "1";
        args[1] = SAMPLE_URI;
        bytes32 requestId = dccRegistry.verifyAndMint(args);

        // Simulate a scenario where the oracle returns an error instead of a response
        bytes memory errorBytes = abi.encode("off-chain lookup failed");

        vm.startPrank(ROUTER);
        vm.expectEmit(true, false, false, true);
        emit DCCRegistry.RequestFailed(requestId, errorBytes);

        dccRegistry.handleOracleFulfillment(requestId, "", errorBytes);
        vm.stopPrank();
    }

    function test_Fail_FulfillRequest_UnexpectedId() public {
        bytes32 randomId = keccak256("randomId");
        vm.prank(ROUTER);

        vm.expectRevert(
            abi.encodeWithSelector(
                DCCRegistry.UnexpectedRequestID.selector,
                randomId
            )
        );
        dccRegistry.handleOracleFulfillment(randomId, "", "");
    }

    function test_Fail_FulfillRequest_AlreadyFulfilled() public {
        // 1. Send and fulfill a request successfully once
        vm.prank(USER_A);
        string[] memory args = new string[](2);
        args[0] = "1";
        args[1] = SAMPLE_URI;
        bytes32 requestId = dccRegistry.verifyAndMint(args);
        bytes memory response = abi.encode(uint256(1));

        vm.prank(ROUTER);
        dccRegistry.handleOracleFulfillment(requestId, response, "");

        // 2. Try to fulfill it again
        vm.prank(ROUTER);
        vm.expectRevert(
            abi.encodeWithSelector(
                DCCRegistry.RequestAlreadyFulfilled.selector,
                requestId
            )
        );
        dccRegistry.handleOracleFulfillment(requestId, response, "");
    }

    // ------------------------------------ //
    // -------- Gas Estimation Test ------- //
    // ------------------------------------ //

    /**
     * @notice This test is specifically for estimating the gas cost of the callback.
     * @dev Run with `forge test --match-test test_Gas_EstimateCallbackGasUsage -vvvv` to see gas details.
     *      The gas cost for `handleOracleFulfillment` will be shown in the report.
     */
    function test_Gas_EstimateCallbackGasUsage() public {
        // 1. A user sends a request to mint an NFT.
        //    Based on your current contract, any user can call this.
        vm.prank(USER_A);
        string[] memory args = new string[](2);
        args[0] = "1"; // Laboratory ID
        args[1] = SAMPLE_URI;
        bytes32 requestId = dccRegistry.verifyAndMint(args);

        // 2. Prepare a successful response from the oracle
        bytes memory response = abi.encode(uint256(1));

        // 3. Simulate the callback from the Chainlink Router and measure gas
        vm.prank(ROUTER);
        dccRegistry.handleOracleFulfillment(requestId, response, "");
    }
}
