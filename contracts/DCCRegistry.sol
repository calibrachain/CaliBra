// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// ----------------------------- //
// --------- Imports ----------- //
// ----------------------------- //

// ------ Open Zeppelin -------- //
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// -------- Chainlink ---------- //
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_X/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_X/libraries/FunctionsRequest.sol";

/**
 * @title Master Contract of Digital Calibration Certificate Registry (DCCRegistry)
 * @author CaliBRA
 * @notice Validate informations about representing calibration certificates between the creation
 * @dev Custom URI storage, CEI pattern, revocation and pausability
 */
contract DCCRegistry is Ownable, FunctionsClient {
    // ----------------------------- //
    // ----- Type declarations ----- //
    // ----------------------------- //

    using FunctionsRequest for FunctionsRequest.Request;

    // ----------------------------- //
    // --------- Structs ----------- //
    // ----------------------------- //

    struct RequestInfo {
        uint256 requestTime;
        uint256 returnedValue;
        string target;
        bool isFulfilled;
    }

    ///@notice Chainlink Functions donId for the specific chain.
    bytes32 immutable i_donId;
    ///@notice Chainlink Subscription ID to process requests
    uint64 immutable i_subscriptionId;

    ///@notice the amount of gas needed to complete the call
    // TODO
    uint32 constant CALLBACK_GAS_LIMIT = 200_000;
    ///@notice Constant variable to hold the JS Script to be executed off-chain.
    // TODO: outro javascript
    string constant SOURCE_CODE =
        'const numId = args[0]; const apiResponse = await Functions.makeHttpRequest({ url: `https://laboratories.onrender.com/api/v1/laboratories/${numId}/status` }); if (apiResponse.error) { console.error(apiResponse.error); throw Error("Request failed"); } const { data } = apiResponse; if (data.status === "ACTIVE") { return Functions.encodeUint256(1); } else { return Functions.encodeUint256(0); }';
    ///@notice magic numbers removal
    uint8 constant ZERO = 0;

    ///@notice mapping to store requests informatio
    mapping(bytes32 requestId => RequestInfo) internal s_requestStorage;

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

    // ----------------------------- //
    // --------- Errors ------------ //
    // ----------------------------- //

    /// @dev Thrown when the requestId is not valid
    error UnexpectedRequestID(bytes32 requestId);
    /// @dev Thrown when a callback tries to fulfill an already fulfilled request
    error RequestAlreadyFulfilled(bytes32 requestId);

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

            //Validation if the Laboratory is active
            if (returnedValue == 1) {
                // bytes memory callData = abi.encodeWithSelector(
                //     bytes4(keccak256("safeMint(address,uint256)")),
                // address _to,
                // string calldata _certificateURI,
                // bytes32 _xmlHash,
                // uint256 _expiresAt,
                // string calldata _calibrationType
                //     recipient,
                //     tokenId
                // );
                // (bool success, ) = nftContract.call(callData);
            } else {
                emit LaboratoryInactive(_requestId, _err);
            }

            emit Response(_requestId, returnedValue);
        } else {
            emit RequestFailed(_requestId, _err);
        }
    }
}
