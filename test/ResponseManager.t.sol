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
        string[] memory options = new string[](2);
        options[0] = "Option 1";
        options[1] = "Option 2";
        surveyManager.createSurvey("What is your favorite color?", options, block.timestamp + 1 days, 100);
    }

    function testSubmitResponse() public {
        responseManager.submitResponse(0, 1);

        ResponseManager.Response[] memory responses = responseManager.getResponses(0);
        assertEq(responses.length, 1);
        assertEq(responses[0].selectedOption, 1);
    }
}
