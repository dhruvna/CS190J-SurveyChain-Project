// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SurveyManager.sol";

contract ResponseManager {
  struct Response {
    uint256 surveyId;
    address participant;
    uint256 selectedOption;
  }

  SurveyManager surveyManager;
  mapping(uint256 => Response[]) public surveyResponses;
  mapping(uint256 => mapping(address => bool)) public hasResponded;

  constructor(address _surveyManagerAddress) {
    surveyManager = SurveyManager(_surveyManagerAddress);
  }
  
  function submitResponse(uint256 _surveyId, uint256 _selectedOption) public {
    SurveyManager.Survey memory survey = surveyManager.getSurvey(_surveyId);
    require(block.timestamp <= survey.expiryTimestamp, "Survey has expired");
    require(survey.numResponses < survey.maxDataPoints, "Max data points reached");
    require(_selectedOption < survey.options.length, "Invalid option");
    require(survey.isActive, "Survey is not active");
    require(!hasResponded[_surveyId][msg.sender], "User has already responded to this survey");
    

    surveyResponses[_surveyId].push(Response({
      surveyId: _surveyId,
      participant: msg.sender,
      selectedOption: _selectedOption
    }));
    
    // Mark user as having responded
    hasResponded[_surveyId][msg.sender] = true;

    // Update survey data point count
    surveyManager.updateSurveyDataPoints(_surveyId);
     //Distribute Rewards after each response
    rewardManager.distributeRewards(_surveyId, msg.sender);
    // Close survey if max data points reached / expiry time reached
    surveyManager.checkSurvey(_surveyId);
  }

  function getResponses(uint256 _surveyId) public view returns (Response[] memory) {
    return surveyResponses[_surveyId];
  }
}