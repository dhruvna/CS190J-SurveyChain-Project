// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./SurveyManager.sol";
import "./RewardManager.sol";

contract ResponseManager {
  struct Response {
    uint256 surveyId;
    address participant;
    uint256 selectedOption;
  }

  UserManager userManager;
  SurveyManager surveyManager;
  RewardManager rewardManager;
  mapping(uint256 => Response[]) public surveyResponses;
  mapping(uint256 => mapping(address => bool)) public hasResponded;
  mapping(uint256 => mapping(address => bytes32)) public nonces;
      mapping(uint256 => mapping(address => uint256)) public revealedResponses; // Added to store revealed responses

  constructor(address _userManagerAddress, address _surveyManagerAddress, address payable _rewardManagerAddress) {
    userManager = UserManager(_userManagerAddress);
    surveyManager = SurveyManager(_surveyManagerAddress);
    rewardManager = RewardManager(_rewardManagerAddress); // Initialize RewardManager
  }

  // generate a nonce for the user based on thetimestamp
    function generateNonce() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, msg.sender));
    }


  function submitResponse(uint256 _surveyId, uint256 _selectedOption) public {
    SurveyManager.Survey memory survey = surveyManager.getSurvey(_surveyId);
    require(block.timestamp <= survey.expiryTimestamp, "Survey has expired");
    require(survey.numResponses < survey.maxDataPoints, "Max data points reached");
    require(_selectedOption < survey.options.length, "Invalid option");
    require(survey.isActive, "Survey is not active");
    require(!hasResponded[_surveyId][msg.sender], "User has already responded to this survey");
    bytes32 nonce = generateNonce();
    bytes32 commitmentHash = keccak256(abi.encodePacked(_selectedOption, nonce));
    surveyManager.commitResponse(_surveyId, commitmentHash);

    surveyResponses[_surveyId].push(Response({
      surveyId: _surveyId,
      participant: msg.sender,
      selectedOption: _selectedOption
    }));

    //Enter the nonce
    nonces[_surveyId][msg.sender] = nonce;
    // Mark user as having responded
    hasResponded[_surveyId][msg.sender] = true;
    // Update survey data point count
    surveyManager.updateSurveyDataPoints(_surveyId);
    // Increase user reputation
    userManager.increaseReputation(msg.sender, 1);
    // Distribute Rewards after each response
    rewardManager.distributeRewards(_surveyId, msg.sender, survey.reward);
    // Close survey if max data points reached / expiry time reached
    surveyManager.checkSurvey(_surveyId);
  }





    function revealResponses(uint256 _surveyId, uint256[] calldata _selectedOptions, bytes32[] calldata _nonces) public {
        require(msg.sender == surveyManager.getSurveyCreator(_surveyId), "Only the survey creator can reveal responses");
        require(_selectedOptions.length == _nonces.length, "Options and nonces arrays must be of the same length");

        for (uint256 i = 0; i < _selectedOptions.length; i++) {
            address respondent = surveyResponses[_surveyId][i].participant;
            require(hasResponded[_surveyId][respondent], "User has not committed to this survey");
            revealedResponses[_surveyId][respondent] = _selectedOptions[i];

            surveyManager.revealResponse(_surveyId, _selectedOptions[i], _nonces[i]);
        }
        surveyManager.checkSurvey(_surveyId);
    }


  function getResponses(uint256 _surveyId) public view returns (Response[] memory) {
    console.log("Fetching responses for survey ID:", _surveyId);
    console.log("Number of responses:", surveyResponses[_surveyId].length);
    return surveyResponses[_surveyId];
  }

      function getRevealedResponse(uint256 _surveyId, address _respondent) public view returns (uint256) {
        return revealedResponses[_surveyId][_respondent];
    }
}