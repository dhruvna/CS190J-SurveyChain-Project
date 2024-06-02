// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/UserManager.sol";
import "../src/SurveyManager.sol";

contract SurveyManagerTest is Test {
    UserManager userManager;
    SurveyManager surveyManager;

    function setUp() public {
        userManager = new UserManager();
        surveyManager = new SurveyManager(address(userManager));
    }

    //write test cases that intentionally fail each of the checks within createSurvey of SurveyManager.sol
    function testCreateSurveyUserNotRegistered() public {
        vm.expectRevert();
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("What is your favorite number?", options, expiryTimestamp, maxDataPoints);
    }

    function testCreateSurveyNoOptions() public {
        userManager.register("Alice");
        vm.expectRevert();
        uint256[] memory options = new uint256[](0);

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("What is your favorite number?", options, expiryTimestamp, maxDataPoints);
    }

    function testCreateSurveyExpiryTimestampInPast() public {
        userManager.register("Alice");
        vm.expectRevert();
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp - 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("What is your favorite number?", options, expiryTimestamp, maxDataPoints);
    }

    function testCreateSurveyMaxDataPointsZero() public {
        userManager.register("Alice");
        vm.expectRevert();
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 0;

        surveyManager.createSurvey("What is your favorite number?", options, expiryTimestamp, maxDataPoints);
    }

    function testCompleteSurvey() public {
        userManager.register("Alice");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("What is your favorite number?", options, expiryTimestamp, maxDataPoints);

        SurveyManager.Survey memory survey = surveyManager.getSurvey(0);
        assertEq(survey.question, "What is your favorite number?");
        assertEq(survey.options.length, 3);
        assertEq(survey.options[0], 1);
        assertEq(survey.options[1], 2);
        assertEq(survey.options[2], 3);
        assertEq(survey.expiryTimestamp, expiryTimestamp);
        assertEq(survey.maxDataPoints, maxDataPoints);
    }
}
