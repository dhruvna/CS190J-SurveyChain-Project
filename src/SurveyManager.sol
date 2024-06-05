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
   // RewardManager rewardManager;
    uint256 public nextSurveyId;
    mapping(uint256 => Survey) public surveys;
    
    constructor(address _userManagerAddress) {
        userManager = UserManager(_userManagerAddress);
      //  rewardManager = RewardManager(_rewardManagerAddress); // Initialize RewardManager
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
        console.log("Survey number:", nextSurveyId, "created with description:", _question);
        nextSurveyId++;
    }

    function updateSurveyDataPoints(uint256 _surveyId) external {
        Survey storage survey = surveys[_surveyId];
        survey.numResponses++;
        checkSurvey(_surveyId);
    }

    function closeSurvey(uint256 _surveyId) internal {
        Survey storage survey = surveys[_surveyId];
        require(survey.isActive, "Survey is already closed!");
        survey.isActive = false;
        if (block.timestamp >= survey.expiryTimestamp) {
            console.log("Survey:", survey.question, "closed due to expiry");
        }
        if (survey.numResponses >= survey.maxDataPoints) {
            console.log("Survey:", survey.question, "closed due to max data points reached");
        }
        // Distribute rewards when the survey is closed (if there are responses)
        
        //if(survey.numResponses > 0) {
          //  rewardManager.distributeRewards(_surveyId);
        //}
    }

    function closeSurveyManually(uint256 _surveyId) external {
        Survey storage survey = surveys[_surveyId];
        require(survey.creator == msg.sender, "Only the survey creator can close the survey");
        closeSurvey(_surveyId);
    }
    
    function checkSurvey(uint256 _surveyId) public {
        Survey storage survey = surveys[_surveyId];
        console.log("Checking Survey:", survey.question);
        console.log("Num Responses:", survey.numResponses);
        if(!survey.isActive) {
            console.log("Survey not Active");
            return;
        }
        if (block.timestamp >= survey.expiryTimestamp || survey.numResponses >= survey.maxDataPoints) {
            closeSurvey(_surveyId);
        }
    }

    //returns survey data, also ensure survey is checked to see if it needs to be closed before returning
    function getSurvey(uint256 _surveyId) public returns (Survey memory) {
        checkSurvey(_surveyId); // Call checkSurvey before returning the survey data
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
