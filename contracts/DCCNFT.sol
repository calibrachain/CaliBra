// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Digital Calibration Certificate NFT (DCCNFT)
 * @author CaliBRA 
 * @notice Emits non-transferable NFTs representing calibration certificates
 * @dev Custom URI storage, CEI pattern, revocation, pausability, and OpenZeppelin Counters
 */
contract DCCNFT is ERC721, Ownable, Pausable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // ----------------------------- //
    // --------- Errors ------------ //
    // ----------------------------- //

    /// @dev Thrown when minting to the zero address
    error InvalidRecipient();

    /// @dev Thrown when certificate expiration is not in the future
    error InvalidExpiration();

    /// @dev Thrown when querying metadata of a nonexistent token
    error TokenDoesNotExist();

    // ----------------------------- //
    // --------- Structs ----------- //
    // ----------------------------- //

    /**
     * @dev Calibration metadata associated with each NFT
     * @param xmlHash SHA-256 hash of the original signed XML file
     * @param issuedAt UNIX timestamp of issuance
     * @param expiresAt UNIX timestamp of ISO 17025 expiration
     * @param calibrationType Domain of calibration (e.g., temperature, mass)
     */
    struct DCCMetadata {
        bytes32 xmlHash;
        uint256 issuedAt;
        uint256 expiresAt;
        string calibrationType;
    }

    // ----------------------------- //
    // --------- Storage ----------- //
    // ----------------------------- //

    Counters.Counter private _tokenIdCounter;

    /// @notice Maps tokenId to associated certificate metadata
    mapping(uint256 => DCCMetadata) private _dccData;

    /// @notice Maps tokenId to off-chain URI (e.g., IPFS)
    mapping(uint256 => string) private _tokenURIs;

    // ----------------------------- //
    // ---------- Events ----------- //
    // ----------------------------- //

    /**
     * @notice Emitted when a new Digital Calibration Certificate is minted
     * @param to Address receiving the NFT
     * @param tokenId Unique token ID
     * @param calibrationType Calibration domain string
     */
    event DCCMinted(
        address indexed to,
        uint256 indexed tokenId,
        string calibrationType
    );

    // ----------------------------- //
    // -------- Constructor -------- //
    // ----------------------------- //

    /**
     * @notice Initializes the ERC721 contract with name and symbol
     * @param initialOwner Address that will be granted the owner role
     */
    constructor(
        address initialOwner
    ) ERC721("Digital Calibration Certificate", "DCC") Ownable(initialOwner) {}

    // ----------------------------- //
    // --------- Minting ----------- //
    // ----------------------------- //

    /**
     * @notice Mints a new calibration certificate NFT
     * @dev Only callable by the contract owner (e.g., calibration authority)
     * @param to Address to receive the NFT
     * @param certificateURI Off-chain URI pointing to the XML certificate (e.g., IPFS)
     * @param xmlHash SHA-256 hash of the signed XML file
     * @param expiresAt UNIX timestamp when the certificate expires
     * @param calibrationType Domain of the calibration (mass, temperature, etc.)
     * @return tokenId ID of the newly minted NFT
     */
    function mintDCC(
        address to,
        string calldata certificateURI,
        bytes32 xmlHash,
        uint256 expiresAt,
        string calldata calibrationType
    ) external onlyOwner whenNotPaused returns (uint256 tokenId) {
        // === Checks ===
        if (to == address(0)) revert InvalidRecipient();
        if (expiresAt <= block.timestamp) revert InvalidExpiration();

        // === Effects ===
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _dccData[tokenId] = DCCMetadata({
            xmlHash: xmlHash,
            issuedAt: block.timestamp,
            expiresAt: expiresAt,
            calibrationType: calibrationType
        });

        _tokenURIs[tokenId] = certificateURI;

        // === Interactions ===
        _mint(to, tokenId);

        emit DCCMinted(to, tokenId, calibrationType);
    }

    // ----------------------------- //
    // --------- Getters ----------- //
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
     * @notice Returns true if the DCC is still valid (not expired)
     * @param tokenId ID of the NFT
     * @return valid True if the current time is before expiration
     */
    function isValid(uint256 tokenId) external view returns (bool valid) {
        if (!exists(tokenId)) revert TokenDoesNotExist();
        return block.timestamp <= _dccData[tokenId].expiresAt;
    }

    /**
     * @notice Returns the SHA-256 hash of the XML calibration certificate
     * @param tokenId ID of the NFT
     * @return xmlHash The stored certificate hash
     */
    function getXMLHash(
        uint256 tokenId
    ) external view returns (bytes32 xmlHash) {
        if (!exists(tokenId)) revert TokenDoesNotExist();
        return _dccData[tokenId].xmlHash;
    }

    /**
     * @notice Returns complete metadata for a given token ID
     * @param tokenId ID of the NFT
     * @return metadata Struct containing all DCC data
     */
    function getMetadata(
        uint256 tokenId
    ) external view returns (DCCMetadata memory metadata) {
        if (!exists(tokenId)) revert TokenDoesNotExist();
        return _dccData[tokenId];
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
        return _tokenURIs[tokenId];
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
