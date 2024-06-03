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

    function setUp() public {
        userManager = new UserManager();
        surveyManager = new SurveyManager(address(userManager));
        responseManager = new ResponseManager(address(surveyManager));
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

        surveyManager.createSurvey("Survey 0", options, expiryTimestamp, maxDataPoints);

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

        surveyManager.createSurvey("Survey 1", options, expiryTimestamp, maxDataPoints);

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

        surveyManager.createSurvey("Survey 2", options, expiryTimestamp, maxDataPoints);
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

        surveyManager.createSurvey("Survey 3", options, expiryTimestamp, maxDataPoints);

        responseManager.submitResponse(0, 1);

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

        surveyManager.createSurvey("Survey 4", options, expiryTimestamp, maxDataPoints);
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

        surveyManager.createSurvey("Survey 5", options, expiryTimestamp, maxDataPoints);

        responseManager.submitResponse(0, 1);

        ResponseManager.Response[] memory responses = responseManager.getResponses(0);
        assertEq(responses.length, 1);
        assertEq(responses[0].selectedOption, 1);
        assertEq(responses[0].participant, address(this));
    }
}
