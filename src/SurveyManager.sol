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
        uint256 reward;
    }
        struct Commitment {
        bytes32 hash;
        bool revealed;
    }

    UserManager userManager;
    uint256 public nextSurveyId;
    mapping(uint256 => Survey) public surveys;
    mapping(uint256 => mapping(address => Commitment)) public commitments;
        mapping(uint256 => mapping(address => uint256)) public revealedResponses;
    


    constructor(address _userManagerAddress) {
        userManager = UserManager(_userManagerAddress);
    }

    function createSurvey(
        string memory _question,
        uint256[] memory _options,
        uint256 _expiryTimestamp,
        uint256 _maxDataPoints,
        uint256 _reward
    ) public {
        require(bytes(userManager.getUsername(msg.sender)).length != 0, "User not registered");
        require(bytes(_question).length > 0, "Question must not be empty");
        require(_options.length > 0, "Survey must have at least one option");
        require(_options.length <= 10, "Survey must have at most 10 options");
        require(_expiryTimestamp > block.timestamp, "Expiry timestamp must be in the future");
        require(_maxDataPoints > 0, "Max data points must be greater than zero");
        require(_reward > 0, "Reward must be greater than zero");

        surveys[nextSurveyId] = Survey({
            id: nextSurveyId,
            creator: msg.sender,
            question: _question,
            options: _options,
            expiryTimestamp: _expiryTimestamp,
            maxDataPoints: _maxDataPoints,
            numResponses: 0,
            isActive: true,
            reward: _reward
        });
        console.log("Survey number:", nextSurveyId, "created with description:", _question);
        nextSurveyId++;
    }

    function commitResponse(uint256 _surveyId, bytes32 _commitmentHash) public {
        require(surveys[_surveyId].isActive, "Survey is not active");
        commitments[_surveyId][msg.sender] = Commitment({
            hash: _commitmentHash,
            revealed: false
        });
    }

    function revealResponse(uint256 _surveyId, uint256 _selectedOption, bytes32 _nonce) public {
        Commitment storage commitment = commitments[_surveyId][msg.sender];
        require(commitment.hash != 0, "No commitment found");
        require(!commitment.revealed, "Response already revealed");

        bytes32 commitmentHash = keccak256(abi.encodePacked(_selectedOption, _nonce));
        require(commitmentHash == commitment.hash, "Invalid reveal");

        commitment.revealed = true;
        revealedResponses[_surveyId][msg.sender] = _selectedOption;
        surveys[_surveyId].numResponses++;

        checkSurvey(_surveyId);
    }

    //getter for other contracts to check the creator 
    function getSurveyCreator(uint256 _surveyId) public view returns (address) {
        return surveys[_surveyId].creator;
    }

    // Update survey data points when a user responds to a survey
    function updateSurveyDataPoints(uint256 _surveyId) external {
        Survey storage survey = surveys[_surveyId];
        survey.numResponses++;
        checkSurvey(_surveyId);
    }

    // Close survey if it has expired or reached max data points
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
    }

    // Close survey manually by the creator
    function closeSurveyManually(uint256 _surveyId) external {
        Survey storage survey = surveys[_surveyId];
        require(survey.creator == msg.sender, "Only the survey creator can close the survey");
        closeSurvey(_surveyId);
    }
    
    // Check if survey is active and if it needs to be closed
    function checkSurvey(uint256 _surveyId) public {
        Survey storage survey = surveys[_surveyId];
        console.log("Checking Survey:", survey.question);
        console.log("Num Responses:", survey.numResponses);
        if(!survey.isActive) {
            console.log("Survey not Active");
            return;
        }
        if (block.timestamp > survey.expiryTimestamp || survey.numResponses >= survey.maxDataPoints) {
            closeSurvey(_surveyId);
        }
    }

    // Get survey data
    function getSurvey(uint256 _surveyId) public returns (Survey memory) {
        require(_surveyId < nextSurveyId, "Survey does not exist");
        checkSurvey(_surveyId);
        return surveys[_surveyId];
    }

    // Returns all active surveys
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
