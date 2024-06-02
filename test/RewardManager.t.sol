// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/UserManager.sol";
import "../src/SurveyManager.sol";
import "../src/ResponseManager.sol";
import "../src/RewardManager.sol";

contract RewardManagerTest is Test {
    UserManager userManager;
    SurveyManager surveyManager;
    ResponseManager responseManager;
    RewardManager rewardManager;

    function setUp() public {
        userManager = new UserManager();
        surveyManager = new SurveyManager(address(userManager));
        responseManager = new ResponseManager(address(surveyManager));
        rewardManager = new RewardManager(address(responseManager));

        // Register a user and create a survey for testing reward distribution
        userManager.register("Alice");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        surveyManager.createSurvey("What is your favorite number?", options, block.timestamp + 1 days, 100);
        responseManager.submitResponse(0, 1);
        vm.deal(address(this), 1 ether);
    }

    function testDistributeRewards() public {
        rewardManager.distributeRewards(0);

        address participant = address(this);
        assertEq(rewardManager.rewards(participant), 1 ether);
    }

    function testClaimReward() public {
        address participant = address(this);
        address[] memory participants = new address[](1);
        participants[0] = participant;

        // Ensure the contract has enough Ether to distribute
        vm.deal(address(rewardManager), 1 ether);
        assert(address(rewardManager).balance == 1 ether);

        rewardManager.distributeRewards(0);

        uint256 initialBalance = participant.balance;

        // Adding a log to check the balance before claiming
        console.log("Contract balance before claim:", address(rewardManager).balance);
        console.log("Participant reward before claim:", rewardManager.rewards(participant));
        console.log("Participant initial balance:", initialBalance);

        rewardManager.claimReward();

        uint256 finalBalance = participant.balance;

        console.log("Participant balance after claim:", finalBalance);

        assert(finalBalance > initialBalance);
    }
}
