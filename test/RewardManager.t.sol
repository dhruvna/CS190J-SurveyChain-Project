// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/RewardManager.sol";

contract RewardManagerTest is Test {
    RewardManager rewardManager;

    function setUp() public {
        rewardManager = new RewardManager();
    }

    function testDistributeRewards() public {
        address[] memory participants = new address[](2);
        participants[0] = address(0x123);
        participants[1] = address(0x456);

        rewardManager.distributeRewards(0, participants);

        assertEq(rewardManager.rewards(address(0x123)), 1 ether);
        assertEq(rewardManager.rewards(address(0x456)), 1 ether);
    }

    function testClaimReward() public {
        address participant = address(this);
        address[] memory participants = new address[](1);
        participants[0] = participant;

        // Ensure the contract has enough Ether to distribute
        vm.deal(address(rewardManager), 1 ether);
        assert(address(rewardManager).balance == 1 ether);
        
        rewardManager.distributeRewards(0, participants);

        uint256 initialBalance = participant.balance;
        // Adding a log to check the balance before claiming
        console.log("Contract balance before claim:", address(rewardManager).balance);
        console.log("Participant reward before claim:", rewardManager.rewards(participant));

        rewardManager.claimReward();
        uint256 finalBalance = participant.balance;
        console.log("Participant balance after claim:", finalBalance);
        
        assert(finalBalance > initialBalance);
    }
}
