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

  constructor(address _surveyManagerAddress) {
        surveyManager = SurveyManager(_surveyManagerAddress);
  }

  function submitResponse(uint256 _surveyId, uint256 _selectedOption) public {
    require(bytes(surveyManager.getSurvey(_surveyId).question).length != 0, "Survey does not exist");

    Response memory response = Response({
      surveyId: _surveyId,
      participant: msg.sender,
      selectedOption: _selectedOption
    });
    surveyResponses[_surveyId].push(response);
  }

  function getResponses(uint256 _surveyId) public view returns (Response[] memory) {
    // Check if survey exists
    require(surveyResponses[_surveyId].length > 0);
    return surveyResponses[_surveyId];
  }
}