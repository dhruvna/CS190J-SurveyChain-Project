// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/ResponseManager.sol";

contract ResponseManagerTest is Test {
  ResponseManager responseManager;

  function setUp() public {
    responseManager = new ResponseManager();
  }

  function testSubmitResponse() public {
    responseManager.submitResponse(0, 1);
    ResponseManager.Response[] memory responses = responseManager.getResponses(0);
    assertEq(responses.length, 1);
    assertEq(responses[0].selectedOption, 1);
  }
}