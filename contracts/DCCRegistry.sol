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

// -------- Chainlink ---------- //
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_X/FunctionsClient.sol";

// ----------------------------- //
// -------- Libraries ---------- //
// ----------------------------- //
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_X/libraries/FunctionsRequest.sol";

/**
 * @title Digital Calibration Certificate (DCCRegistry)
 * @author CaliBRA
 * @notice Emits non-transferable NFTs representing calibration certificates
 * @dev Custom URI storage, CEI pattern, revocation, pausability, and OpenZeppelin Counters
 */
contract DCCRegistry is ERC721, Ownable, Pausable, FunctionsClient {
    ///@notice Chainlink Functions donId for the specific chain.
    bytes32 immutable i_donId;
    ///@notice Chainlink Subscription ID to process requests
    uint64 immutable i_subscriptionId;

    ///@notice the amount of gas needed to complete the call
    // TODO
    uint32 constant CALLBACK_GAS_LIMIT = 200_000;
    ///@notice Constant variable to hold the JS Script to be executed off-chain.
    // TODO: outro javascript?
    string constant SOURCE_CODE =
        'const e=await import("npm:ethers@6.10.0");class P extends e.JsonRpcProvider{constructor(u){super(u),this.url=u}async _send(p){return(await fetch(this.url,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(p)})).json()}}const r=new P("https://ethereum.publicnode.com");if(!args?.[0]||!e.isAddress(args[0]))throw new Error("Invalid address");return Functions.encodeUint256(await r.getBalance(args[0]))';
    ///@notice magic numbers removal
    uint8 constant ZERO = 0;

    ///@notice mapping to store requests informatio
    mapping(bytes32 requestId => RequestInfo) internal s_requestStorage;

    // ----------------------------- //
    // ----- Type declarations ----- //
    // ----------------------------- //
    using FunctionsRequest for FunctionsRequest.Request;
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

    struct RequestInfo {
        uint256 requestTime;
        uint256 returnedValue;
        string target;
        bool isFulfilled;
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
    ///@notice event emitted when a new CLF request is initialized
    event FunctionsRequestSent(bytes32 requestId);
    ///@notice event emitted when functions returns
    event Response(bytes32 requestId, uint256 returnedValue);
    ///@notice event emitted when an CLF fails
    event RequestFailed(bytes32 requestId, bytes err);

    // ----------------------------- //
    // --------- Errors ------------ //
    // ----------------------------- //

    /// @dev Thrown when minting to the zero address
    error InvalidRecipient();
    /// @dev Thrown when certificate expiration is not in the future
    error InvalidExpiration();
    /// @dev Thrown when querying metadata of a nonexistent token
    error TokenDoesNotExist();
    /// @dev Thrown when the requestId is not valid
    error UnexpectedRequestID(bytes32 requestId);
    /// @dev Thrown when a callback tries to fulfill an already fulfilled request
    error RequestAlreadyFulfilled(bytes32 requestId);

    // ----------------------------- //
    // -------- Constructor -------- //
    // ----------------------------- //

    /**
     * @notice Initializes the ERC721 contract with name and symbol
     * @param _router TODO router
     * @param _owner Address that will be granted the owner role
     * @param _donId TODO donID
     * @param _subscriptionId TODO subscription
     */
    constructor(
        address _router,
        address _owner,
        bytes32 _donId,
        uint64 _subscriptionId
    )
        ERC721("Digital Calibration Certificate", "DCC")
        FunctionsClient(_router)
        Ownable(_owner)
    {
        i_donId = _donId;
        i_subscriptionId = _subscriptionId;
    }

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
        string calldata _calibrationType,
        string memory labIdentifier //TODO
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

        //TODO mint não vai ser aqui

        // === Interactions ===
        _safeMint(_to, tokenId);

        emit DCCMinted(_to, tokenId, _calibrationType);
    }

    /**
     * @notice Function to initiate a CLF simple request and query the eth balance of a address
     * @param _args List of arguments accessible from within the source code
     * @param _bytesArgs Array of bytes arguments, represented as hex strings
     */
    function sendRequest(
        string[] memory _args,
        bytes[] memory _bytesArgs
    ) external onlyOwner returns (bytes32 requestId_) {
        FunctionsRequest.Request memory req;

        req._initializeRequestForInlineJavaScript(SOURCE_CODE);

        if (_args.length > 0) req._setArgs(_args);
        if (_bytesArgs.length > 0) req._setBytesArgs(_bytesArgs);

        requestId_ = _sendRequest(
            req._encodeCBOR(),
            i_subscriptionId,
            CALLBACK_GAS_LIMIT,
            i_donId
        );

        s_requestStorage[requestId_] = RequestInfo({
            requestTime: block.timestamp,
            returnedValue: 0,
            target: _args[0],
            isFulfilled: false
        });

        emit FunctionsRequestSent(requestId_);
    }

    /*///////////////////////////////////
                internal
    ///////////////////////////////////*/
    /**
     * @notice Store latest result/error
     * @param _requestId The request ID, returned by sendRequest()
     * @param _response Aggregated response from the user code
     * @param _err Aggregated error from the user code or from the execution pipeline
     * Either response or error parameter will be set, but never both
     */
    function _fulfillRequest(
        bytes32 _requestId,
        bytes memory _response,
        bytes memory _err
    ) internal override {
        RequestInfo storage request = s_requestStorage[_requestId];
        if (request.requestTime == ZERO) revert UnexpectedRequestID(_requestId);
        if (request.isFulfilled) revert RequestAlreadyFulfilled(_requestId);

        if (_response.length > ZERO) {
            uint256 returnedValue = abi.decode(_response, (uint256));

            request.returnedValue = returnedValue;
            request.isFulfilled = true;

            emit Response(_requestId, returnedValue);
        } else {
            emit RequestFailed(_requestId, _err);
        }
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
