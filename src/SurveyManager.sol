// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SurveyManager {
    struct Survey {
        uint256 id;
        address creator;
        string question;
        string[] options;
        uint256 expiryTimestamp;
        uint256 maxDataPoints;
    }

    uint256 public nextSurveyId;
    mapping(uint256 => Survey) public surveys;

    function createSurvey(
        string memory _question,
        string[] memory _options,
        uint256 _expiryTimestamp,
        uint256 _maxDataPoints
    ) public {
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
