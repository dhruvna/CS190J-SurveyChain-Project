// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/UserManager.sol";

contract UserManagerTest is Test {
  UserManager userManager;

  function setUp() public {
    userManager = new UserManager();
  }

  function testRegisterUser() public {
    userManager.register("Alice");
    string memory username = userManager.getUsername(address(this));
    assertEq(username, "Alice");
  }
  
  function testDuplicateRegisterUser() public {
    userManager.register("Alice");
    vm.expectRevert();
    userManager.register("Bob"); // Should fail!
  }
}