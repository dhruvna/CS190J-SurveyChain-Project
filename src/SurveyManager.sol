// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UserManager.sol";

contract SurveyManager {
    struct Survey {
        uint256 id;
        address creator;
        string question;
        string[] options;
        uint256 expiryTimestamp;
        uint256 maxDataPoints;
    }

    UserManager userManager;
    uint256 public nextSurveyId;
    mapping(uint256 => Survey) public surveys;
    
    constructor(address _userManagerAddress) {
        userManager = UserManager(_userManagerAddress);
    }

    function createSurvey(
        string memory _question,
        string[] memory _options,
        uint256 _expiryTimestamp,
        uint256 _maxDataPoints
    ) public {
        require(bytes(userManager.getUsername(msg.sender)).length != 0, "User not registered");
        surveys[nextSurveyId] = Survey({
            id: nextSurveyId,
            creator: msg.sender,
            question: _question,
            options: _options,
            expiryTimestamp: _expiryTimestamp,
            maxDataPoints: _maxDataPoints
        });
        nextSurveyId++;
    }

    function getSurvey(uint256 _surveyId) public view returns (Survey memory) {
        return surveys[_surveyId];
    }
}
