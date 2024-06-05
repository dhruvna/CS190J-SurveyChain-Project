// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/UserManager.sol";

contract UserManagerTest is Test {
  UserManager userManager;

  function setUp() public {
    userManager = new UserManager();
  }

  //Ensure that the username is saved and getUsername returns properly
  function testRegisterUser() public {
    userManager.register("Alice");
    string memory username = userManager.getUsername(address(this));
    assertEq(username, "Alice");
  }
  
  //Ensure that the same blockchain address cannot register more than once
  function testDuplicateRegisterUser() public {
    userManager.register("Alice");
    vm.expectRevert("Blockchain address already registered to an acccount");
    userManager.register("Bob"); // Should fail and cause revert
  }
}