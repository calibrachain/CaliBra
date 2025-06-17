// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

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
    using Strings for uint256;

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

    uint256 private _tokenIdCounter;

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
    // --------- Errors ------------ //
    // ----------------------------- //

    /// @dev Thrown when minting to the zero address
    error InvalidRecipient();
    /// @dev Thrown when certificate expiration is not in the future
    error InvalidExpiration();
    /// @dev Thrown when querying metadata of a nonexistent token
    error TokenDoesNotExist();

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
     * @notice Create a new calibration certificate NFT
     * @dev Only callable by the contract owner (e.g., calibration authority)
     * @param _to Address to receive the NFT
     * @param _certificateURI Off-chain URI pointing to the XML certificate (e.g., IPFS)
     * @param _xmlHash SHA-256 hash of the signed XML file
     * @param _expiresAt UNIX timestamp when the certificate expires
     * @param _calibrationType Domain of the calibration (mass, temperature, etc.)
     * @return tokenId ID of the newly minted NFT
     * TODO REFACTOR
     */
    function createDCC(
        address _to,
        string calldata _certificateURI,
        bytes32 _xmlHash,
        uint256 _expiresAt,
        string calldata _calibrationType
    ) external onlyOwner whenNotPaused returns (uint256 tokenId) {
        // === Checks ===
        if (_to == address(0)) revert InvalidRecipient();
        if (_expiresAt <= block.timestamp) revert InvalidExpiration();

        // === Effects ===
        tokenId = _tokenIdCounter;
        _tokenIdCounter += 1;

        _dccData[tokenId] = DCCMetadata({
            xmlHash: _xmlHash,
            issuedAt: block.timestamp,
            expiresAt: _expiresAt,
            calibrationType: _calibrationType
        });

        _tokenURIs[tokenId] = _certificateURI;

        // === Interactions ===
        _safeMint(_to, tokenId);

        emit DCCMinted(_to, tokenId, _calibrationType);
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
