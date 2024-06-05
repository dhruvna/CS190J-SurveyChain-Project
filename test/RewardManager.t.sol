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
        rewardManager = new RewardManager(address(0)); // Placeholder to avoid circular dependency
        surveyManager = new SurveyManager(address(userManager));
        responseManager = new ResponseManager(address(surveyManager), payable(address(rewardManager)));
        rewardManager = new RewardManager(address(responseManager)); // Correct address linkage

        // Register a user and create a survey for testing reward distribution
        userManager.register("Alice");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        surveyManager.createSurvey("Reward Manager Test Survey", options, block.timestamp + 1 days, 100, 1 ether);
        responseManager.submitResponse(0, 1);
    }

    function testDistributeRewards() public {
        // Ensure the contract has enough Ether to distribute
        vm.deal(address(rewardManager), 100 ether);
        
        address participant = address(this);
        rewardManager.distributeRewards(0, participant, 5 ether);

        assertEq(rewardManager.rewards(participant), 5 ether);
    }

    function testClaimReward() public {
        address participant = address(this);

        // Ensure the contract has enough Ether to distribute
        vm.deal(address(rewardManager), 100 ether);
        assert(address(rewardManager).balance == 100 ether);

        rewardManager.distributeRewards(0, participant, 6 ether);

        uint256 initialBalance = participant.balance;

        // Adding a log to check the balance before claiming
        console.log("Contract balance before claim:", address(rewardManager).balance);
        console.log("Participant reward before claim:", rewardManager.rewards(participant));
        console.log("Participant initial balance:", initialBalance);

        rewardManager.claimReward();

        uint256 finalBalance = participant.balance;

        console.log("Participant balance after claim:", finalBalance);

        assert(finalBalance == initialBalance + 6 ether);
    }

    receive() external payable {
        console.log("Received Ether:", msg.value);
    }

    fallback() external payable {
        console.log("Fallback called. Received Ether:", msg.value);
    }
}
