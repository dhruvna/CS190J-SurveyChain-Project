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

        // Register a user for testing survey creation
        userManager.register("Alice");
    }
    function testCreateSurvey() public {
      string[] memory options = new string[](3);
      options[0] = "Option 1";
      options[1] = "Option 2";
      options[2] = "Option 3";

      surveyManager.createSurvey("What is your favorite color?", options, block.timestamp + 1 days, 100);

      SurveyManager.Survey memory survey = surveyManager.getSurvey(0);
        assertEq(survey.question, "What is your favorite color?");
        assertEq(survey.options.length, 3);
        assertEq(survey.options[0], "Option 1");
        assertEq(survey.options[1], "Option 2");
        assertEq(survey.options[2], "Option 3");
    }
}
