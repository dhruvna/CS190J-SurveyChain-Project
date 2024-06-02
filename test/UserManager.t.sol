// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/UserManager.sol";

contract UserManagerTest is Test {
  UserManager userManager;

  function setUp() public {
    userManager = new UserManager();
  }

  function testRegisterUser() public {
    userManager.registerUser("Alice");
    string memory username = userManager.getUsername(address(this));
    assertEq(username, "Alice");
  }

  function testDuplicateRegisterUser() public {
    userManager.registerUser("Alice");
    userManager.registerUser("Bob"); // Should fail!
  }
}