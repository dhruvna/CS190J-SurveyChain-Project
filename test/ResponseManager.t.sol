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

        // Register a user and create a survey for testing response submission
        userManager.register("Alice");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        surveyManager.createSurvey("What is your favorite number?", options, block.timestamp + 1 days, 100);
    }

    function testSubmitResponse() public {
        responseManager.submitResponse(0, 1);

        ResponseManager.Response[] memory responses = responseManager.getResponses(0);
        assertEq(responses.length, 1);
        assertEq(responses[0].selectedOption, 1);
    }

    function testSubmitResponseSurveyExpired() public {
        vm.warp(block.timestamp + 2 days); // Fast forward time to beyond survey expiry
        vm.expectRevert("Survey has expired");
        responseManager.submitResponse(0, 1);
    }

    function testSubmitResponseMaxDataPointsReached() public {
        // Create a survey with a max of 1 data point for this test
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        surveyManager.createSurvey("How many pets do you own?", options, block.timestamp + 1 days, 1);

        // Submit the first response
        responseManager.submitResponse(1, 1);

        // Try to submit another response, which should fail
        vm.expectRevert("Max data points reached");
        responseManager.submitResponse(1, 2);
    }

    function testSubmitResponseInvalidOption() public {
        vm.expectRevert("Invalid option");
        responseManager.submitResponse(0, 5); // Option 5 does not exist
    }
}
