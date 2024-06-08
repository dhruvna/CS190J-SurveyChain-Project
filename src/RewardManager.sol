// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./ResponseManager.sol";

contract RewardManager {
    ResponseManager responseManager;
    mapping(address => uint256) public rewards;

    constructor(address _responseManagerAddress) {
        responseManager = ResponseManager(_responseManagerAddress);
    }

    function distributeRewards(uint256 _surveyId, address _userAddress, uint256 amount) public {
        console.log("Distributing rewards for survey ID:", _surveyId);
        uint256 currentBalance = rewards[_userAddress];
        uint256 newBalance = 0;
        unchecked {
            newBalance = currentBalance + amount;
        }

        if (newBalance < currentBalance) {
            console.log("Reward overflow detected, clamping to max value.");
            rewards[_userAddress] = type(uint256).max - 1;
        } else {
            console.log("Reward distributed successfully, new balance:", newBalance);
            rewards[_userAddress] = newBalance;
        }

    }

    function claimReward() public {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards available");
        rewards[msg.sender] = 0;

        console.log("Attempting to transfer reward:", reward);
        console.log("Contract balance:", address(this).balance);

        require(address(this).balance >= reward, "Insufficient contract balance");

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "Transfer failed");

        console.log("Transfer successful:", success);
    }

    receive() external payable {
        console.log("Received Ether:", msg.value);
    }

    fallback() external payable {
        console.log("Fallback called. Received Ether:", msg.value);
    }
}
