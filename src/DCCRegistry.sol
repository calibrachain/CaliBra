// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// ----------------------------- //
// --------- Imports ----------- //
// ----------------------------- //

// ------ Open Zeppelin -------- //
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// -------- Chainlink ---------- //
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_X/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_X/libraries/FunctionsRequest.sol";

/// @notice Minimal interface for the DCCNFT contract
interface IDCCNFT {
    /// @dev Mints a new DCC NFT. See {DCCNFT-safeMint}.
    function safeMint(
        address to,
        string calldata certificateURI
    ) external returns (uint256);
}

/**
 * @title Master Contract of Digital Calibration Certificate Registry (DCCRegistry)
 * @author CaliBRA
 * @notice Validate informations about representing calibration certificates between the creation
 * @dev Custom URI storage, CEI pattern, revocation and pausability
 */
contract DCCRegistry is Ownable, FunctionsClient {
    // ----------------------------- //
    // --------- Structs ----------- //
    // ----------------------------- //

    struct RequestInfo {
        uint256 requestTime;
        uint256 returnedValue;
        string laboratory;
        bool isFulfilled;
        address recipient;
        string certificateURI;
    }

    // ----------------------------- //
    // --------- Variables --------- //
    // ----------------------------- //

    using FunctionsRequest for FunctionsRequest.Request;

    ///@notice Chainlink Functions donId for the specific chain.
    bytes32 immutable i_donId;
    ///@notice Chainlink Subscription ID to process requests
    uint64 immutable i_subscriptionId;

    ///@notice the amount of gas needed to complete the call
    // TODO
    uint32 constant CALLBACK_GAS_LIMIT = 250_000;

    ///@notice mapping to store requests informatio
    mapping(bytes32 requestId => RequestInfo) internal s_requestStorage;

    ///@notice NFT Contract for minting the DCC NFTs
    address private s_nftContract;
    ///@notice Variable to hold the JS Script to be executed off-chain.
    ///@dev On mainnet will be immutable and setted in the constructor, but on testnet it can be changed
    string private s_source_code;

    // ----------------------------- //
    // ---------- Events ----------- //
    // ----------------------------- //

    ///@notice event emitted when a new CLF request is initialized
    event FunctionsRequestSent(bytes32 requestId);
    ///@notice event emitted when functions returns
    event Response(bytes32 requestId, uint256 returnedValue);
    ///@notice event emitted when an CLF fails
    event RequestFailed(bytes32 requestId, bytes err);
    ///@notice event emitted when a Laboratory is not active
    event LaboratoryInactive(bytes32 requestId, bytes err);
    ///@notice event when the NFT minting fails
    event MintingFailed(bytes32 requestId);

    // ----------------------------- //
    // --------- Errors ------------ //
    // ----------------------------- //

    /// @dev Thrown when the requestId is not valid
    error UnexpectedRequestID(bytes32 requestId);
    /// @dev Thrown when a callback tries to fulfill an already fulfilled request
    error RequestAlreadyFulfilled(bytes32 requestId);
    /// @dev Thrown when a required address is the zero address
    error InvalidAddress();
    /// @dev Thrown when the arguments for a request are invalid
    error InvalidArguments();

    // ----------------------------- //
    // -------- Constructor -------- //
    // ----------------------------- //

    /**
     * @notice Constructor initializes informations about the Chainlink Functions
     * @param _router Address of the Chainlink Functions Router contract
     * @param _owner Address that will be granted the owner role
     * @param _donId The Chainlink Functions DON ID for the specific chain
     * @param _subscriptionId The Chainlink Functions subscription ID to process requests
     */
    constructor(
        address _router,
        address _owner,
        bytes32 _donId,
        uint64 _subscriptionId
    ) FunctionsClient(_router) Ownable(_owner) {
        i_donId = _donId;
        i_subscriptionId = _subscriptionId;
    }

    // ----------------------------- //
    // -------- External ----------- //
    // ----------------------------- //

    /**
     * @notice Function to set the NFT contract address
     * @param _nftContract Address of the NFT contract that will mint the DCC NFTs
     */
    function setNftContract(address _nftContract) external onlyOwner {
        if (_nftContract == address(0)) revert InvalidAddress();
        s_nftContract = _nftContract;
    }

    /**
     * @notice Function to set the JavaScript source code for Chainlink Functions
     * @param _sourceCode The JavaScript source code to be executed off-chain
     */
    function setSourceCode(string memory _sourceCode) external onlyOwner {
        s_source_code = _sourceCode;
    }

    /**
     * @notice Function to initiate a CLF simple request and query the eth balance of a address
     * @param _args List of arguments accessible from within the source code (0:idLab, 1:certificateURI)
     * @dev The first argument is the laboratory address, the second is the certificate URI
     *      The source code must be set with a javascript code before calling this function
     *      On mainnet the access must be restricted
     */
    function verifyAndMint(
        string[] memory _args
    ) external returns (bytes32 requestId_) {
        if (_args.length < 2) revert InvalidArguments();
        if (bytes(s_source_code).length == 0) revert InvalidArguments();

        FunctionsRequest.Request memory req;

        req._initializeRequestForInlineJavaScript(s_source_code);

        if (_args.length > 0) req._setArgs(_args);

        requestId_ = _sendRequest(
            req._encodeCBOR(),
            i_subscriptionId,
            CALLBACK_GAS_LIMIT,
            i_donId
        );

        s_requestStorage[requestId_] = RequestInfo({
            requestTime: block.timestamp,
            returnedValue: 0,
            laboratory: _args[0],
            isFulfilled: false,
            recipient: msg.sender,
            certificateURI: _args[1]
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
        if (request.requestTime == 0) revert UnexpectedRequestID(_requestId);
        if (request.isFulfilled) revert RequestAlreadyFulfilled(_requestId);

        // Mark as fulfilled early to prevent re-entrancy
        request.isFulfilled = true;

        if (_response.length > 0) {
            uint256 returnedValue = abi.decode(_response, (uint256));
            request.returnedValue = returnedValue;
            emit Response(_requestId, returnedValue);

            //Validation if the Laboratory is active (1)
            if (returnedValue == 1) {
                // Use try/catch to handle potential minting failures gracefully
                try
                    IDCCNFT(s_nftContract).safeMint(
                        request.recipient,
                        request.certificateURI
                    )
                {
                    // NFT Minted!  \o/
                } catch {
                    emit MintingFailed(_requestId);
                }
            } else {
                emit LaboratoryInactive(
                    _requestId,
                    "Laboratory reported as not active"
                );
            }
        } else {
            emit RequestFailed(_requestId, _err);
        }
    }
}
