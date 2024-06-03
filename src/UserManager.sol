// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserManager {
  struct User {
    string username;
    address userAddress;
  }

  mapping(address => User) public users;

  function register(string memory _username) public {
    // Check if user already exists
    require(bytes(users[msg.sender].username).length == 0);
    users[msg.sender] = User(_username, msg.sender);
  }

  function getUsername(address _userAddress) public view returns (string memory) {
    // Check if user exists
    require (bytes(users[_userAddress].username).length != 0, "User not registered");
    return users[_userAddress].username;
  }
}