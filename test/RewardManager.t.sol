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

        rewardManager.distributeRewards(0, participants);

        uint256 initialBalance = participant.balance;
        rewardManager.claimReward();
        uint256 finalBalance = participant.balance;

        assert(finalBalance > initialBalance);
    }
}
