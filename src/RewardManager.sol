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

    function distributeRewards(uint256 _surveyId, address _userAddress) public {
        console.log("Distributing rewards for survey ID:", _surveyId);
        rewards[_userAddress] += 1 ether;
        console.log("Reward distributed to User Address:", _userAddress, "Amount:", "1 ether");
    }

    function claimReward() public {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards available");
        rewards[msg.sender] = 0;

        console.log("Attempting to transfer reward:", reward);
        console.log("Contract balance:", address(this).balance);

        require(address(this).balance >= reward, "Insufficient contract balance");

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        // bool success = payable(msg.sender).send(reward);
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
