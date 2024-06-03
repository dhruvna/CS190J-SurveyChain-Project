// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./UserManager.sol";

contract SurveyManager {
    struct Survey {
        uint256 id;
        address creator;
        string question;
        uint256[] options;
        uint256 expiryTimestamp;
        uint256 maxDataPoints;
        uint256 numResponses;
        bool isActive;
    }

    UserManager userManager;
    uint256 public nextSurveyId;
    mapping(uint256 => Survey) public surveys;
    
    constructor(address _userManagerAddress) {
        userManager = UserManager(_userManagerAddress);
    }

    function createSurvey(
        string memory _question,
        uint256[] memory _options,
        uint256 _expiryTimestamp,
        uint256 _maxDataPoints
    ) public {
        require(bytes(userManager.getUsername(msg.sender)).length != 0, "User not registered");
        require(_options.length > 0, "Survey must have at least one option");
        require(_expiryTimestamp > block.timestamp, "Expiry timestamp must be in the future");
        require(_maxDataPoints > 0, "Max data points must be greater than zero");

        surveys[nextSurveyId] = Survey({
            id: nextSurveyId,
            creator: msg.sender,
            question: _question,
            options: _options,
            expiryTimestamp: _expiryTimestamp,
            maxDataPoints: _maxDataPoints,
            numResponses: 0,
            isActive: true
        });
        console.log("Survey number %s created with question %s", nextSurveyId, _question);
        nextSurveyId++;
    }

    function updateSurveyDataPoints(uint256 _surveyId) external {
        Survey storage survey = surveys[_surveyId];
        survey.numResponses++;
    }

    function closeSurvey(uint256 _surveyId) internal {
        Survey storage survey = surveys[_surveyId];
        require(survey.isActive, "Survey is already closed!");
        survey.isActive = false;
        console.log("Survey closed: %s", survey.question);
    }

    function checkAndCloseSurvey(uint256 _surveyId) external {
        Survey storage survey = surveys[_surveyId];
        if (block.timestamp >= survey.expiryTimestamp || survey.numResponses >= survey.maxDataPoints) {
            closeSurvey(_surveyId);
        }
        console.log("Survey checked: %s", survey.question);
    }

    function getSurvey(uint256 _surveyId) public view returns (Survey memory) {
        return surveys[_surveyId];
    }

    function getActiveSurveys() public view returns (Survey[] memory) {
        uint256 activeSurveyCount = 0;
        for (uint256 i = 0; i < nextSurveyId; i++) {
            if (surveys[i].isActive) {
                activeSurveyCount++;
            }
        }

        Survey[] memory activeSurveys = new Survey[](activeSurveyCount);
        uint256 activeSurveyIndex = 0;
        for (uint256 i = 0; i < nextSurveyId; i++) {
            if (surveys[i].isActive) {
                activeSurveys[activeSurveyIndex] = surveys[i];
                activeSurveyIndex++;
            }
        }
        return activeSurveys;
    }
}
