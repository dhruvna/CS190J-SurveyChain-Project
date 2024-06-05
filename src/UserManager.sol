// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract UserManager {
  struct User {
    string username;
    address userAddress;
    //Create a member variable called reputation and initailize it to zero
    uint256 reputation;
  }

  mapping(address => User) public users;

  function register(string memory _username) public {
    // Check if user already exists
    require(bytes(users[msg.sender].username).length == 0, "Blockchain address already registered to an acccount");
    users[msg.sender] = User(_username, msg.sender, 0);
  }

  //Function to test if user is registered
  function isRegistered(address _userAddress) public view returns (bool) {
    return bytes(users[_userAddress].username).length != 0;
  }

  function getUsername(address _userAddress) public view returns (string memory) {
    // Check if user exists
    require (bytes(users[_userAddress].username).length != 0, "User not registered");
    return users[_userAddress].username;
  }

  function getReputation(address _userAddress) public view returns (uint256) {
    // Check if user exists
    require (bytes(users[_userAddress].username).length != 0, "User not registered");
    return users[_userAddress].reputation;
  }

  function increaseReputation(address _userAddress, uint256 _surveyValue) public {
    if(isRegistered(_userAddress)) {
      uint256 currentReputation = getReputation(_userAddress);
      // Check for overflow
      uint256 newReputation = 0;
      unchecked {
        newReputation = currentReputation + _surveyValue;
      }
      if (newReputation <= currentReputation) {
        console.log("Reputation overflow detected, clamping to max value.");
        users[_userAddress].reputation = type(uint256).max - 1;
      } else {
        console.log("Reputation increased successfully, new reputation: ", newReputation);
        users[_userAddress].reputation = newReputation;
      }
    } else {
        console.log("Must be logged in to increase reputation");
    }
  }
}