// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/UserManager.sol";
import "../src/SurveyManager.sol";
import "../src/ResponseManager.sol";

contract ResponseManagerTest is Test {
    UserManager userManager;
    SurveyManager surveyManager;
    ResponseManager responseManager;
    RewardManager rewardManager;
    
    function setUp() public {
        userManager = new UserManager();
        responseManager = new ResponseManager(address(0)); // Placeholder to avoid circular dependency
        rewardManager = new RewardManager(address(responseManager)); // Correct address linkage
        surveyManager = new SurveyManager(address(userManager), payable(address(rewardManager)));
        responseManager = new ResponseManager(address(surveyManager)); // Reassign correct address after instantiation
        userManager.register("Alice");
    }

    function testSubmitResponse() public {
        // Register a user and create a survey for testing response submission
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for basic response submission", options, expiryTimestamp, maxDataPoints);

        responseManager.submitResponse(0, 1);
        ResponseManager.Response[] memory responses = responseManager.getResponses(0);
        assertEq(responses.length, 1);
        assertEq(responses[0].selectedOption, 1);
    }

    function testOnlyOneSubmissionPerID() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for only one submission per user", options, expiryTimestamp, maxDataPoints);

        responseManager.submitResponse(0, 1);

        // Attempt to submit a second response
        vm.expectRevert("User has already responded to this survey");
        responseManager.submitResponse(0, 2);
    }


    function testSubmitResponseSurveyExpired() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;
        
        surveyManager.createSurvey("Test for expired survey", options, expiryTimestamp, maxDataPoints);
        vm.warp(block.timestamp + 2 days); // Warp time to after survey expiry
        vm.expectRevert("Survey has expired");
        responseManager.submitResponse(0, 1);
    }

    function testSubmitResponseMaxDataPointsReached() public {
        // Create a survey with a max of 1 data point for this test
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 1;

        surveyManager.createSurvey("Test for max data points reached", options, expiryTimestamp, maxDataPoints);

        responseManager.submitResponse(0, 1);
        console.log("First response submitted");

        vm.expectRevert("Max data points reached");
        responseManager.submitResponse(0, 2);
    }

    function testSubmitResponseInvalidOption() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for invalid option selection", options, expiryTimestamp, maxDataPoints);
        vm.expectRevert("Invalid option");
        responseManager.submitResponse(0, 5); // Option 5 does not exist
    }

    function testGetResponses() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for getting survey responses", options, expiryTimestamp, maxDataPoints);

        responseManager.submitResponse(0, 1);

        ResponseManager.Response[] memory responses = responseManager.getResponses(0);
        assertEq(responses.length, 1);
        assertEq(responses[0].selectedOption, 1);
        assertEq(responses[0].participant, address(this));
    }

    function testSubmitResponseWithoutRegistration() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for unregistered participation", options, expiryTimestamp, maxDataPoints);

        // Ensure anyone can submit a response without registration
        address unregisteredUser = address(0x1234);
        vm.prank(unregisteredUser);
        responseManager.submitResponse(0, 1);
        ResponseManager.Response[] memory responses = responseManager.getResponses(0);
        assertEq(responses.length, 1);
        assertEq(responses[0].selectedOption, 1);
        assertEq(responses[0].participant, unregisteredUser);
    }

    function testLastMinuteSubmissions() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 4;

        surveyManager.createSurvey("Test for last minute submissions", options, expiryTimestamp, maxDataPoints);

        // Warp time to 1 second before survey expiry
        vm.warp(expiryTimestamp - 1);
        responseManager.submitResponse(0, 0);
        address unregisteredUser = address(0x1234);
        vm.prank(unregisteredUser);
        responseManager.submitResponse(0, 1);
        address unregisteredUser2 = address(0x5678);
        vm.prank(unregisteredUser2);
        responseManager.submitResponse(0, 2);

        // Ensure the survey is still active
        SurveyManager.Survey memory survey = surveyManager.getSurvey(0);
        assertEq(survey.numResponses, 3);
        assert(survey.isActive);

        // Warp time to survey expiry
        vm.warp(expiryTimestamp);

        // Ensure the survey is closed
        survey = surveyManager.getSurvey(0);
        assert(!survey.isActive);
    }
}
