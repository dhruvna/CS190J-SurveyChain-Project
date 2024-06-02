// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RewardManager {
    mapping(address => uint256) public rewards;

    function distributeRewards(uint256 _surveyId, address[] memory _participants) public {
        for (uint256 i = 0; i < _participants.length; i++) {
            rewards[_participants[i]] += 1 ether; 
        }
    }

    function claimReward() public {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards available");
        rewards[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}
