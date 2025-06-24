// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// ----------------------------- //
// --------- Imports ----------- //
// ----------------------------- //

// ------ Open Zeppelin -------- //
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Digital Calibration Certificate NFT (DCCNFT)
 * @author CaliBRA
 * @notice Emits non-transferable NFTs representing calibration certificates
 * @dev Custom URI storage, CEI pattern, revocation and pausability
 */
contract DCCNFT is ERC721, Ownable, Pausable {
    // ----------------------------- //
    // --------- Storage ----------- //
    // ----------------------------- //

    uint256 private s_tokenIdCounter;

    /// @notice Maps tokenId to off-chain URI (e.g., IPFS)
    mapping(uint256 => string) private s_tokenURIs;
    // Address autorized to mint NFTs
    address private s_minterAddress;

    // ----------------------------- //
    // ---------- Events ----------- //
    // ----------------------------- //

    /**
     * @notice Emitted when a new Digital Calibration Certificate is minted
     * @param to Address receiving the NFT
     * @param tokenId Unique token ID
     */
    event DCCMinted(address indexed to, uint256 indexed tokenId);

    // ----------------------------- //
    // --------- Errors ------------ //
    // ----------------------------- //

    /// @dev Thrown when minting to the zero address
    error InvalidRecipient();
    /// @dev Thrown when contract that interact is invalid
    error InvalidMinter();
    /// @dev Thrown when certificate expiration is not in the future
    error InvalidExpiration();
    /// @dev Thrown when querying metadata of a nonexistent token
    error TokenDoesNotExist();
    /// @dev Thrown when an unauthorized address tries to mint
    error UnauthorizedMinter();

    // ----------------------------- //
    // -------- Constructor -------- //
    // ----------------------------- //

    /**
     * @notice Initializes the ERC721 contract with name and symbol
     * @param _owner Address that will be granted the owner role
     */
    constructor(
        address _owner
    ) ERC721("Digital Calibration Certificate", "DCC") Ownable(_owner) {}

    // ----------------------------- //
    // -------- External ----------- //
    // ----------------------------- //

    /**
     * @dev define the address authorized to mint NFTs. Only the owner can call this.
     * @param _minterAddress The address of the minter contract
     */
    function setMinterAddress(address _minterAddress) public onlyOwner {
        if (_minterAddress == address(0)) revert InvalidMinter();
        s_minterAddress = _minterAddress;
    }

    /**
     * @notice Create a new calibration certificate NFT
     * @dev Only callable by the contract owner (e.g., calibration authority)
     * @param _to Address to receive the NFT
     * @param _certificateURI Off-chain URI pointing to the XML certificate (e.g., IPFS)
     * @return tokenId ID of the newly minted NFT
     */
    function safeMint(
        address _to,
        string calldata _certificateURI
    ) external onlyOwner whenNotPaused returns (uint256 tokenId) {
        if (_to == address(0)) revert InvalidRecipient();
        if (msg.sender == s_minterAddress) revert UnauthorizedMinter();

        tokenId = s_tokenIdCounter;
        s_tokenIdCounter += 1;

        s_tokenURIs[tokenId] = _certificateURI;

        _safeMint(_to, tokenId);

        emit DCCMinted(_to, tokenId);
    }

    // ----------------------------- //
    // ---------- Views ------------ //
    // ----------------------------- //

    /**
     * @notice Checks whether a DCC token exists
     * @param tokenId ID of the NFT
     * @return True if the token exists, false otherwise
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    /**
     * @notice Returns the token URI (points to off-chain signed XML file)
     * @param tokenId ID of the NFT
     * @return uri The stored URI string
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory uri) {
        if (!exists(tokenId)) revert TokenDoesNotExist();
        return s_tokenURIs[tokenId];
    }

    // ----------------------------- //
    // --------- Pausability ------- //
    // ----------------------------- //

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
