// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ResponseManager.sol";

contract RewardManager {
    ResponseManager responseManager;
    mapping(address => uint256) public rewards;

    constructor(address _responseManagerAddress) {
        responseManager = ResponseManager(_responseManagerAddress);
    }

    function distributeRewards(uint256 _surveyId) public {
        ResponseManager.Response[] memory responses = responseManager.getResponses(_surveyId);
        for (uint256 i = 0; i < responses.length; i++) {
            rewards[responses[i].participant] += 1 ether;
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
