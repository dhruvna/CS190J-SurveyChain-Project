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
        responseManager = new ResponseManager(address(userManager), address(0), payable(address(0))); // Placeholder to avoid circular dependency
        rewardManager = new RewardManager(address(responseManager)); // Correct address linkage
        surveyManager = new SurveyManager(address(userManager));
        responseManager = new ResponseManager(address(userManager), address(surveyManager), payable(address(rewardManager))); // Reassign correct address after instantiation
        userManager.register("Alice");
    }

    // Responses are submitted and stored in the contract, should not revert
    function testSubmitResponse() public {
        // Register a user and create a survey for testing response submission
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for basic response submission", options, expiryTimestamp, maxDataPoints, 1 ether);

        responseManager.submitResponse(0, 1);
        ResponseManager.Response[] memory responses = responseManager.getResponses(0);
        assertEq(responses.length, 1);
        assertEq(responses[0].selectedOption, 1);
    }

    // Ensure only one response can be submitted per user per survey, should revert
    // PENETRATION TEST: Attacker cannot abuse our system and submit multiple responses
    function testOnlyOneSubmissionPerID() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for only one submission per user", options, expiryTimestamp, maxDataPoints, 1 ether);

        responseManager.submitResponse(0, 1);

        // Attempt to submit a second response
        vm.expectRevert("User has already responded to this survey");
        responseManager.submitResponse(0, 2);
    }

    // Responses cannot be submitted to expired surveys, should revert
    function testSubmitResponseSurveyExpired() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;
        
        surveyManager.createSurvey("Test for expired survey", options, expiryTimestamp, maxDataPoints, 1 ether);
        vm.warp(block.timestamp + 2 days); // Warp time to after survey expiry
        vm.expectRevert("Survey has expired");
        responseManager.submitResponse(0, 1);
    }

    // Ensure responses cannot be submitted once we reach the max data points, should revert
    // PENETRATION TEST: Attacker cannot submit a response when the data points are final
    function testSubmitResponseMaxDataPointsReached() public {
        // Create a survey with a max of 1 data point for this test
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 1;

        surveyManager.createSurvey("Test for max data points reached", options, expiryTimestamp, maxDataPoints, 1 ether);

        responseManager.submitResponse(0, 1);
        console.log("First response submitted");

        vm.expectRevert("Max data points reached");
        responseManager.submitResponse(0, 2);
    }

    // Participants cannot select an option that does not exist in the survey, should revert
    // PENETRATION TEST: Attacker cannot select an invalid option to break our surveys
    function testSubmitResponseInvalidOption() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for invalid option selection", options, expiryTimestamp, maxDataPoints, 1 ether);
        vm.expectRevert("Invalid option");
        responseManager.submitResponse(0, 5); // Option 5 does not exist
    }

    //  We can get responses for a survey, should not revert
    function testGetResponses() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for getting survey responses", options, expiryTimestamp, maxDataPoints, 1 ether);

        responseManager.submitResponse(0, 1);

        ResponseManager.Response[] memory responses = responseManager.getResponses(0);
        assertEq(responses.length, 1);
        assertEq(responses[0].selectedOption, 1);
        assertEq(responses[0].participant, address(this));
    }

    // Ensure anyone can submit a response without registration, should not revert
    function testSubmitResponseWithoutRegistration() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for unregistered participation", options, expiryTimestamp, maxDataPoints, 1 ether);

        // Ensure anyone can submit a response without registration
        address unregisteredUser = address(0x1234);
        vm.prank(unregisteredUser);
        responseManager.submitResponse(0, 1);
        ResponseManager.Response[] memory responses = responseManager.getResponses(0);
        assertEq(responses.length, 1);
        assertEq(responses[0].selectedOption, 1);
        assertEq(responses[0].participant, unregisteredUser);
    }

    // Ensure that responses can be submitted up until the last minute before survey expiry, should not revert
    function testLastMinuteSubmissions() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 4;

        surveyManager.createSurvey("Test for last minute submissions", options, expiryTimestamp, maxDataPoints, 1 ether);

        // Warp time to the expiry block
        vm.warp(expiryTimestamp);
        responseManager.submitResponse(0, 0);
        address unregisteredUser = address(0x1234);
        vm.prank(unregisteredUser);
        responseManager.submitResponse(0, 1);
        address unregisteredUser2 = address(0x5678);
        vm.prank(unregisteredUser2);
        responseManager.submitResponse(0, 2);

        // Ensure the survey is still active until the block finishes
        SurveyManager.Survey memory survey = surveyManager.getSurvey(0);
        assertEq(survey.numResponses, 3);
        assert(survey.isActive);

        // Warp time to the next block
        vm.warp(expiryTimestamp + 1);

        // Ensure the survey is closed
        survey = surveyManager.getSurvey(0);
        assert(!survey.isActive);
    }

    // Ensure that user reputation is increased after submitting a response, should not revert
    function testIncreaseReputation() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for reputation increase", options, expiryTimestamp, maxDataPoints, 1 ether);

        uint256 initialReputation = userManager.getReputation(address(this));
        responseManager.submitResponse(0, 1);
        uint256 finalReputation = userManager.getReputation(address(this));
        assertEq(finalReputation, initialReputation + 1);

        surveyManager.createSurvey("Test for reputation increase 2", options, expiryTimestamp, maxDataPoints, 1 ether);
        responseManager.submitResponse(1, 1);
        finalReputation = userManager.getReputation(address(this));
        assertEq(finalReputation, initialReputation + 2);
    }

    // Check that we have protection in place for reputation overflow, should not revert
    // PENETRATION TEST: Prevent an overflow attack 
    function testReputationOverflow() public {
        address user = address(0xDEF);
        vm.prank(user);
        userManager.register("Bob");
        vm.prank(user);
        userManager.increaseReputation(user, type(uint256).max - 1);
        vm.prank(user);
        userManager.increaseReputation(user, 2);
    }



    // Check a front running attack fails 
    // PENETRATION TEST: Prevent a front running attacker from beating out survey responses with higher gas  
    function testPreventFrontRunning() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        surveyManager.createSurvey("Front Running Test Survey", options, block.timestamp + 1 days, 100, 1 ether);

        // Legitimate user (Alice) and Attacker register and commit their responses
        address Alice = address(0xABC);
        address attacker = address(0x123);

        vm.prank(Alice);
        userManager.register("Alice");

        vm.prank(attacker);
        userManager.register("Attacker");

        // Both users commit their responses
        vm.prank(Alice);
        responseManager.submitResponse{gas: 300000}(0, 1);
        // Attacker gives more gas to get processed first
        vm.prank(attacker);
        responseManager.submitResponse{gas: 300001}(0, 2);

        // Fetch committed responses to verify the commit phase
        ResponseManager.Response[] memory responses = responseManager.getResponses(0);

        // Check that both responses are committed
        assertEq(responses.length, 2);
        assertEq(responses[0].participant, address(Alice));
        assertEq(responses[1].participant, address(attacker));

        // Move time forward to end commit phase
        vm.warp(block.timestamp + 2 days);


        // Verify that the legitimate response is processed first in the responses
        responses = responseManager.getResponses(0);
        assertEq(responses[0].selectedOption, 1);
        assertEq(responses[1].selectedOption, 2);
    }

}
