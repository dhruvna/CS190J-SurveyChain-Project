// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/UserManager.sol";
import "../src/SurveyManager.sol";
import "../src/ResponseManager.sol";
import "../src/RewardManager.sol";
import {ReentrantContract} from "./RewardAttacker.sol";

contract RewardManagerTest is Test {
    UserManager userManager;
    SurveyManager surveyManager;
    ResponseManager responseManager;
    RewardManager rewardManager;

    function setUp() public {
        userManager = new UserManager();
        rewardManager = new RewardManager(address(0)); // Placeholder to avoid circular dependency
        surveyManager = new SurveyManager(address(userManager));
        responseManager = new ResponseManager(address(userManager), address(surveyManager), payable(address(rewardManager)));
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

    // Correct amount of rewards should be distributed to the participant, should not revert
    function testDistributeRewards(uint256 bank_balance, uint256 reward_amount) public {
        // Ensure the contract has enough Ether to distribute, and that the bounds are at least somewhat reasonable
        vm.assume(bank_balance < 1000000000000000000000000000000000000000000000000000000 ether);
        vm.assume(reward_amount > 0);
        vm.assume(bank_balance > reward_amount);
        vm.deal(address(rewardManager), bank_balance);
        
        address participant = address(this);
        rewardManager.distributeRewards(0, participant, reward_amount);

        assertEq(rewardManager.rewards(participant), reward_amount);
    }
    
    // Rewards mustbe claimable by participants, should not revert
    function testClaimReward(uint256 bank_balance, uint256 reward_amount) public {
        // Ensure the contract has enough Ether to distribute, and that the bounds are at least somewhat reasonable
        vm.assume(bank_balance < 1000000000000000000000000000000000000000000000000000000 ether);
        vm.assume(reward_amount > 0);
        vm.assume(bank_balance > reward_amount);

        vm.deal(address(rewardManager), bank_balance);
        assert(address(rewardManager).balance == bank_balance);

        address participant = address(this);
        
        rewardManager.distributeRewards(0, participant, reward_amount);

        uint256 initialBalance = participant.balance;

        // Adding a log to check the balance before claiming
        console.log("Contract balance before claim:", address(rewardManager).balance);
        console.log("Participant reward before claim:", rewardManager.rewards(participant));
        console.log("Participant initial balance:", initialBalance);

        rewardManager.claimReward();

        uint256 finalBalance = participant.balance;

        console.log("Participant balance after claim:", finalBalance);

        assert(finalBalance == initialBalance + reward_amount);
    }

    //overflow attack test, expect revert 
    // PENETRATION TEST: Prevent overflow attackers 
    function testOverflow(uint256 amount) public {
        address user = address(0xDEF);
        rewardManager.distributeRewards(0, user, type(uint256).max - 1);

        // Test: Adding any amount should overflow, but we should be handling it just fine.
        rewardManager.distributeRewards(0, user, amount);
    }


    // test re-entrancy with an attacker contract 
    // PENETRATION TEST: prevent a reetrant attacker from claiming more rewards than they deserve
    function testReentrancyAttack() public {
        // ensure the contract has enough Ether to distribute
        vm.deal(address(rewardManager), 10 ether);
        assert(address(rewardManager).balance == 10 ether);

        // Setup: Assume a user has rewards to claim
        address attacker = address(0xABC);
        rewardManager.distributeRewards(0, attacker, 1 ether);
        // Test: Call claimReward in a reentrant manner
        vm.prank(attacker);
        rewardManager.claimReward();
        ReentrantContract reentrant = new ReentrantContract(address(rewardManager));
        vm.expectRevert();
        reentrant.attack();

        // Verify: Check the final state to ensure no extra ether was claimed
        assertEq(address(rewardManager).balance, 9 ether);
    }


    //Full survey lifecycle test[createSurvey -> submitResponse -> distributeRewards -> claimReward] [TODO]
    
    receive() external payable {
        console.log("Received Ether:", msg.value);
    }

    fallback() external payable {
        console.log("Fallback called. Received Ether:", msg.value);
    }
}
