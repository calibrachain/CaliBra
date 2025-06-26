// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// ----------------------------- //
// --------- Imports ----------- //
// ----------------------------- //
import {Test, console} from "forge-std/Test.sol";
import {DCCNFT} from "../src/DCCNFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Test for the DCCNFT Contract
 * @notice This contract tests all the main functionalities of DCCNFT.
 */
contract DCCNFTTest is Test {
    // ----------------------------- //
    // ------- State Variables ----- //
    // ----------------------------- //
    DCCNFT private dccNft;

    // Addresses to simulate different roles
    address private constant OWNER = address(0x1); // Contract Owner
    address private constant MINTER_CONTRACT = address(0x2); // Address that would be the authorized minter
    address private constant USER_A = address(0x3); // A random user
    address private constant USER_B = address(0x4); // Another user

    // Sample data
    string private constant SAMPLE_URI =
        "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi";
    uint256 private constant FIRST_TOKEN_ID = 0;

    // ----------------------------- //
    // ----------- Setup ----------- //
    // ----------------------------- //

    /**
     * @notice Setup run before each test.
     * Deploys a new DCCNFT contract.
     */
    function setUp() public {
        // Deploy the contract, setting OWNER as the initial owner
        dccNft = new DCCNFT(OWNER);
    }

    // ----------------------------- //
    // ---- Constructor Tests ---- //
    // ----------------------------- //

    function test_InitialState() public view {
        assertEq(
            dccNft.name(),
            "Digital Calibration Certificate",
            "The contract name should be as expected"
        );
        assertEq(
            dccNft.symbol(),
            "DCC",
            "The contract symbol should be as expected"
        );
        assertEq(
            dccNft.owner(),
            OWNER,
            "The initial owner was not set correctly"
        );
    }

    // ------------------------------------ //
    // ---- Access Control Tests -------- //
    // ------------------------------------ //

    function test_OwnerCanSetMinterAddress() public {
        vm.prank(OWNER); // Simulates the call coming from the OWNER
        dccNft.setMinterAddress(MINTER_CONTRACT);
        // There is no public view for s_minterAddress, the indirect functionality test (safeMint) covers this.
        // This test just ensures the call does not revert.
    }

    function test_Fail_SetMinterAddressByNonOwner() public {
        vm.prank(USER_A); // Simulates the call coming from a random user
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER_A
            )
        );
        dccNft.setMinterAddress(MINTER_CONTRACT);
    }

    function test_Fail_SetMinterAddressToZero() public {
        vm.prank(OWNER);
        vm.expectRevert(DCCNFT.InvalidMinter.selector);
        dccNft.setMinterAddress(address(0));
    }

    // ------------------------------------ //
    // -------- Minting Tests ----------- //
    // ------------------------------------ //

    function test_OwnerCanMint() public {
        vm.prank(OWNER);

        // Expects the DCCMinted event to be emitted with the correct parameters
        vm.expectEmit(true, true, false, true);
        emit DCCNFT.DCCMinted(USER_A, FIRST_TOKEN_ID);

        uint256 tokenId = dccNft.safeMint(USER_A, SAMPLE_URI);

        assertEq(tokenId, FIRST_TOKEN_ID, "The returned tokenId should be 0");
        assertEq(
            dccNft.ownerOf(tokenId),
            USER_A,
            "The new token's owner should be USER_A"
        );
        assertEq(dccNft.balanceOf(USER_A), 1, "USER_A's balance should be 1");
        assertEq(
            dccNft.tokenURI(tokenId),
            SAMPLE_URI,
            "The token URI was not set correctly"
        );
    }

    // function test_Fail_MintByNonOwner() public {
    //     vm.prank(USER_A); // Random user tries to mint
    //     // The correct revert is OwnableUnauthorizedAccount
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             Ownable.OwnableUnauthorizedAccount.selector,
    //             USER_A
    //         )
    //     );
    //     dccNft.safeMint(USER_B, SAMPLE_URI);
    // }

    function test_Fail_MintByAuthorizedMinter() public {
        // Sets MINTER_CONTRACT as the authorized minter
        vm.prank(OWNER);
        dccNft.setMinterAddress(MINTER_CONTRACT);

        // Tries to mint from the minter's address
        vm.prank(MINTER_CONTRACT);
        // According to your logic, this should revert, as only the owner can call safeMint
        vm.expectRevert(DCCNFT.UnauthorizedMinter.selector);
        dccNft.safeMint(USER_B, SAMPLE_URI);
    }

    function test_Fail_MintToZeroAddress() public {
        vm.prank(OWNER);
        vm.expectRevert(DCCNFT.InvalidRecipient.selector);
        dccNft.safeMint(address(0), SAMPLE_URI);
    }

    // ------------------------------------ //
    // ------- Pausability Tests -------- //
    // ------------------------------------ //

    function test_PauseAndUnpause() public {
        // Pauses the contract
        vm.prank(OWNER);
        dccNft.pause();
        assertTrue(dccNft.paused(), "The contract should be paused");

        // Tries to mint while paused
        vm.prank(OWNER);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        dccNft.safeMint(USER_A, SAMPLE_URI);

        // Unpauses the contract
        vm.prank(OWNER);
        dccNft.unpause();
        assertFalse(dccNft.paused(), "The contract should not be paused");

        // Tries to mint again
        vm.prank(OWNER);
        dccNft.safeMint(USER_A, SAMPLE_URI);
        assertEq(
            dccNft.balanceOf(USER_A),
            1,
            "Minting should succeed after unpausing"
        );
    }

    function test_Fail_PauseByNonOwner() public {
        vm.prank(USER_A);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER_A
            )
        );
        dccNft.pause();
    }

    function test_Fail_UnpauseByNonOwner() public {
        // Pauses first as owner
        vm.prank(OWNER);
        dccNft.pause();

        // Tries to unpause as non-owner
        vm.prank(USER_A);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER_A
            )
        );
        dccNft.unpause();
    }

    // ------------------------------------ //
    // ----------- View Tests ----------- //
    // ------------------------------------ //

    function test_TokenURI() public {
        vm.prank(OWNER);
        uint256 tokenId = dccNft.safeMint(USER_A, SAMPLE_URI);

        string memory uri = dccNft.tokenURI(tokenId);
        assertEq(uri, SAMPLE_URI, "The returned URI is not the expected one");
    }

    function test_Fail_TokenURINonExistent() public {
        vm.expectRevert(DCCNFT.TokenDoesNotExist.selector);
        dccNft.tokenURI(FIRST_TOKEN_ID);
    }

    function test_Exists() public {
        uint256 tokenId = 0;
        assertFalse(dccNft.exists(tokenId), "Token 0 should not exist yet");

        vm.prank(OWNER);
        tokenId = dccNft.safeMint(USER_A, SAMPLE_URI);

        assertTrue(
            dccNft.exists(tokenId),
            "Token 0 should exist after being minted"
        );
    }

    // ------------------------------------ //
    // --- Non-Transferability Test ----- //
    // ------------------------------------ //

    /**
     * @notice This test checks that the tokens ARE transferable, which might be against the @notice's intention.
     * To make the tokens truly non-transferable, you would need to override the transfer functions.
     */
    function test_TokenIsTransferable() public {
        // 1. Mint a token for USER_A
        vm.prank(OWNER);
        uint256 tokenId = dccNft.safeMint(USER_A, SAMPLE_URI);
        assertEq(dccNft.ownerOf(tokenId), USER_A);

        // 2. USER_A transfers the token to USER_B
        vm.prank(USER_A);
        dccNft.transferFrom(USER_A, USER_B, tokenId);

        // 3. Verifies that the transfer was successful
        assertEq(
            dccNft.ownerOf(tokenId),
            USER_B,
            "The transfer should have been successful"
        );
    }
}
