// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/UserManager.sol";
import "../src/SurveyManager.sol";
import "../src/RewardManager.sol";
import "../src/ResponseManager.sol";

contract SurveyManagerTest is Test {
    UserManager userManager;
    SurveyManager surveyManager;
    RewardManager rewardManager;
    ResponseManager responseManager;

    function setUp() public {
        userManager = new UserManager();
        responseManager = new ResponseManager(address(0), payable(address(0))); // Placeholder to avoid circular dependency
        rewardManager = new RewardManager(address(responseManager)); // Correct address linkage
        surveyManager = new SurveyManager(address(userManager));
        responseManager = new ResponseManager(address(surveyManager), payable(address(rewardManager)));

    }
    // Survey Tests Section 1
    // - Intentionally fail each of the checks within createSurvey of SurveyManager.sol

    //Only registered users can create surveys, should revert
    function testCreateSurveyUserNotRegistered() public {
        vm.expectRevert("User not registered");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for User Not Registered", options, expiryTimestamp, maxDataPoints, 1 ether);
    }

    // Survey question must not be empty, should revert
    function testCreateSurveyNoQuestion() public {
        userManager.register("Alice");
        vm.expectRevert("Question must not be empty");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("", options, expiryTimestamp, maxDataPoints, 1 ether);
    }

    // Survey must have at least one option, should revert
    // No need to ensure they are numbers, as we will have a compilation error if uint256 is not used
    function testCreateSurveyNoOptions() public {
        userManager.register("Alice");
        vm.expectRevert("Survey must have at least one option");
        uint256[] memory options = new uint256[](0);

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for at least 1 option", options, expiryTimestamp, maxDataPoints, 1 ether);
    }

    // Survey expiry timestamp must be in the future, should revert
    function testCreateSurveyExpiryTimestampInPast() public {
        userManager.register("David");
        vm.expectRevert("Expiry timestamp must be in the future");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp - 1;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for a future expiry timestamp", options, expiryTimestamp, maxDataPoints, 1 ether);
    }

    // Max data points must be greater than zero, should revert
    function testCreateSurveyMaxDataPointsZero() public {
        userManager.register("Alice");
        vm.expectRevert("Max data points must be greater than zero");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 0;

        surveyManager.createSurvey("Test for multiple max data points", options, expiryTimestamp, maxDataPoints, 1 ether);
    }

    // Surveys must have some reward for users, should revert
    function testCreateSurveyNoReward() public {
        userManager.register("Alice");
        vm.expectRevert("Reward must be greater than zero");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        surveyManager.createSurvey("Test for reward greater than zero", options, block.timestamp + 1 days, 100, 0 ether);
    }

    // Survey Tests Section 2
    // - Test successful survey creation, survey attributes, and getting active surveys

    // Survey should be created successfully, should not revert
    function testCreateSurvey() public {
        userManager.register("Bob");
        uint256[] memory options = new uint256[](2);
        options[0] = 5;
        options[1] = 10;

        uint256 expiryTimestamp = block.timestamp + 2 days;
        uint256 maxDataPoints = 50;

        surveyManager.createSurvey("Test for successful survey creation", options, expiryTimestamp, maxDataPoints, 1 ether);
    }

    // Ensure that we can get survey attributes after creation, should not revert
    function testSurveyAttributes() public {
        userManager.register("Charlie");
        uint256[] memory options = new uint256[](4);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        options[3] = 4;

        uint256 expiryTimestamp = block.timestamp + 3 days;
        uint256 maxDataPoints = 200;

        surveyManager.createSurvey("Test for proper survey attributes!", options, expiryTimestamp, maxDataPoints, 4 ether);

        SurveyManager.Survey memory survey = surveyManager.getSurvey(0);
        assertEq(survey.question, "Test for proper survey attributes!");
        assertEq(survey.options.length, 4);
        assertEq(survey.options[0], 1);
        assertEq(survey.options[1], 2);
        assertEq(survey.options[2], 3);
        assertEq(survey.options[3], 4);
        assertEq(survey.expiryTimestamp, expiryTimestamp);
        assertEq(survey.maxDataPoints, maxDataPoints);
        assertEq(survey.reward, 4 ether);
    }

    // Ensure that we can get multiple survey attributes after creation, should not revert
    function testGetActiveSurveys() public {
        userManager.register("Alice");
        uint256[] memory options1 = new uint256[](3);
        options1[0] = 1;
        options1[1] = 2;
        options1[2] = 3;

        uint256[] memory options2 = new uint256[](4);
        options2[0] = 10;
        options2[1] = 20;
        options2[2] = 30;
        options2[3] = 40;

        uint256 expiryTimestamp1 = block.timestamp + 1 days;
        uint256 expiryTimestamp2 = block.timestamp + 2 days;

        uint256 maxDataPoints1 = 100;
        uint256 maxDataPoints2 = 150;

        surveyManager.createSurvey("Test for getting active survey", options1, expiryTimestamp1, maxDataPoints1, 1 ether);
        surveyManager.createSurvey("Test for getting more than one active survey", options2, expiryTimestamp2, maxDataPoints2, 1 ether);

        SurveyManager.Survey[] memory activeSurveys = surveyManager.getActiveSurveys();
        assertEq(activeSurveys.length, 2);
        assertEq(activeSurveys[0].question, "Test for getting active survey");
        assertEq(activeSurveys[1].question, "Test for getting more than one active survey");
    }

    // Survey Tests Section 3
    // Survey Closure

    // Surveys should close automatically after expiry[TODO]

    // Surveys should close automatically after reaching max data points[TODO]

    // Surveys can be closed manually, should not revert
    function testCloseSurveyManually() public {
        userManager.register("Bob");
        uint256[] memory options = new uint256[](2);
        options[0] = 15;
        options[1] = 30;

        uint256 expiryTimestamp = block.timestamp + 2 days;
        uint256 maxDataPoints = 50;

        surveyManager.createSurvey("Test for manual survey closing", options, expiryTimestamp, maxDataPoints, 1 ether);

        surveyManager.closeSurveyManually(0);
        SurveyManager.Survey memory survey = surveyManager.getSurvey(0);
        assertEq(survey.isActive, false);
    }

    // Only the survey creator can close the survey manually, should revert
    function testOnlyOwnerCanCloseSurveyManually() public {
        userManager.register("Bob");
        uint256[] memory options = new uint256[](2);
        options[0] = 25;
        options[1] = 50;

        uint256 expiryTimestamp = block.timestamp + 2 days;
        uint256 maxDataPoints = 50;

        surveyManager.createSurvey("Test that only owner can close survey", options, expiryTimestamp, maxDataPoints, 1 ether);
        
        address unregisteredUser = address(0x4321);
        vm.prank(unregisteredUser);
        vm.expectRevert("Only the survey creator can close the survey");
        surveyManager.closeSurveyManually(0);
    }
}
