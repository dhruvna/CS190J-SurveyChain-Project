#ResponseManager.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SurveyManager.sol";

contract ResponseManager {
  struct Response {
    uint256 surveyId;
    address participant;
    uint256 selectedOption;
  }

  SurveyManager surveyManager;
  mapping(uint256 => Response[]) public surveyResponses;
  mapping(uint256 => mapping(address => bool)) public hasResponded;

  constructor(address _surveyManagerAddress) {
    surveyManager = SurveyManager(_surveyManagerAddress);
  }
  
  function submitResponse(uint256 _surveyId, uint256 _selectedOption) public {
    SurveyManager.Survey memory survey = surveyManager.getSurvey(_surveyId);
    require(block.timestamp <= survey.expiryTimestamp, "Survey has expired");
    require(survey.numResponses < survey.maxDataPoints, "Max data points reached");
    require(_selectedOption < survey.options.length, "Invalid option");
    require(survey.isActive, "Survey is not active");
    require(!hasResponded[_surveyId][msg.sender], "User has already responded to this survey");
    

    surveyResponses[_surveyId].push(Response({
      surveyId: _surveyId,
      participant: msg.sender,
      selectedOption: _selectedOption
    }));
    
    // Mark user as having responded
    hasResponded[_surveyId][msg.sender] = true;

    // Update survey data point count
    surveyManager.updateSurveyDataPoints(_surveyId);

    // Close survey if max data points reached / expiry time reached
    surveyManager.checkSurvey(_surveyId);
  }

  function getResponses(uint256 _surveyId) public view returns (Response[] memory) {
    return surveyResponses[_surveyId];
  }
}
```

#RewardManager.sol
```solidity
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
            console.log("Reward distributed to:", responses[i].participant, "Amount:", 1 ether);
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
```

#SurveyManager.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./UserManager.sol";

contract SurveyManager {
    struct Survey {
        uint256 id;
        address creator;
        string question;
        uint256[] options;
        uint256 expiryTimestamp;
        uint256 maxDataPoints;
        uint256 numResponses;
        bool isActive;
    }

    UserManager userManager;
    uint256 public nextSurveyId;
    mapping(uint256 => Survey) public surveys;
    
    constructor(address _userManagerAddress) {
        userManager = UserManager(_userManagerAddress);
    }

    function createSurvey(
        string memory _question,
        uint256[] memory _options,
        uint256 _expiryTimestamp,
        uint256 _maxDataPoints
    ) public {
        require(bytes(userManager.getUsername(msg.sender)).length != 0, "User not registered");
        require(_options.length > 0, "Survey must have at least one option");
        require(_expiryTimestamp > block.timestamp, "Expiry timestamp must be in the future");
        require(_maxDataPoints > 0, "Max data points must be greater than zero");

        surveys[nextSurveyId] = Survey({
            id: nextSurveyId,
            creator: msg.sender,
            question: _question,
            options: _options,
            expiryTimestamp: _expiryTimestamp,
            maxDataPoints: _maxDataPoints,
            numResponses: 0,
            isActive: true
        });
        console.log("Survey number:", nextSurveyId, "created with description:", _question);
        nextSurveyId++;
    }

    function updateSurveyDataPoints(uint256 _surveyId) external {
        checkSurvey(_surveyId);
        Survey storage survey = surveys[_surveyId];
        survey.numResponses++;
    }

    function closeSurvey(uint256 _surveyId) internal {
        Survey storage survey = surveys[_surveyId];
        require(survey.isActive, "Survey is already closed!");
        survey.isActive = false;
        if (block.timestamp >= survey.expiryTimestamp) {
            console.log("Survey:", survey.question, "closed due to expiry");
        }
        if (survey.numResponses >= survey.maxDataPoints) {
            console.log("Survey:", survey.question, "closed due to max data points reached");
        }
        
    }

    function closeSurveyManually(uint256 _surveyId) external {
        Survey storage survey = surveys[_surveyId];
        require(survey.creator == msg.sender, "Only the survey creator can close the survey");
        closeSurvey(_surveyId);
    }
    
    function checkSurvey(uint256 _surveyId) public {
        Survey storage survey = surveys[_surveyId];
        if(!survey.isActive) {
            return;
        }
        if (block.timestamp >= survey.expiryTimestamp || survey.numResponses >= survey.maxDataPoints) {
            closeSurvey(_surveyId);
        }
        console.log("Survey", survey.question, "checked");
    }

    function getSurvey(uint256 _surveyId) public returns (Survey memory) {
        checkSurvey(_surveyId);
        return surveys[_surveyId];
    }

    function getActiveSurveys() public view returns (Survey[] memory) {
        uint256 activeSurveyCount = 0;
        for (uint256 i = 0; i < nextSurveyId; i++) {
            if (surveys[i].isActive) {
                activeSurveyCount++;
            }
        }

        Survey[] memory activeSurveys = new Survey[](activeSurveyCount);
        uint256 activeSurveyIndex = 0;
        for (uint256 i = 0; i < nextSurveyId; i++) {
            if (surveys[i].isActive) {
                activeSurveys[activeSurveyIndex] = surveys[i];
                activeSurveyIndex++;
            }
        }
        return activeSurveys;
    }
}

```

#UserManager.sol
```solidity
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
```

#ResponseManager.t.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/UserManager.sol";
import "../src/SurveyManager.sol";
import "../src/ResponseManager.sol";

contract ResponseManagerTest is Test {
    UserManager userManager;
    SurveyManager surveyManager;
    ResponseManager responseManager;

    function setUp() public {
        userManager = new UserManager();
        surveyManager = new SurveyManager(address(userManager));
        responseManager = new ResponseManager(address(surveyManager));
        userManager.register("Alice");
    }

    function testSubmitResponse() public {
        // Register a user and create a survey for testing response submission
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for basic response submission", options, expiryTimestamp, maxDataPoints);

        responseManager.submitResponse(0, 1);
        ResponseManager.Response[] memory responses = responseManager.getResponses(0);
        assertEq(responses.length, 1);
        assertEq(responses[0].selectedOption, 1);
    }

    function testOnlyOneSubmissionPerID() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for only one submission per user", options, expiryTimestamp, maxDataPoints);

        responseManager.submitResponse(0, 1);

        // Attempt to submit a second response
        vm.expectRevert("User has already responded to this survey");
        responseManager.submitResponse(0, 2);
    }


    function testSubmitResponseSurveyExpired() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for expired survey", options, expiryTimestamp, maxDataPoints);
        vm.warp(block.timestamp + 2 days); // Warp time to after survey expiry
        vm.expectRevert("Survey has expired");
        responseManager.submitResponse(0, 1);
    }

    function testSubmitResponseMaxDataPointsReached() public {
        // Create a survey with a max of 1 data point for this test
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 1;

        surveyManager.createSurvey("Test for max data points reached", options, expiryTimestamp, maxDataPoints);

        responseManager.submitResponse(0, 1);

        vm.expectRevert("Max data points reached");
        responseManager.submitResponse(0, 2);
    }

    function testSubmitResponseInvalidOption() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for invalid option selection", options, expiryTimestamp, maxDataPoints);
        vm.expectRevert("Invalid option");
        responseManager.submitResponse(0, 5); // Option 5 does not exist
    }

    function testGetResponses() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for getting survey responses", options, expiryTimestamp, maxDataPoints);

        responseManager.submitResponse(0, 1);

        ResponseManager.Response[] memory responses = responseManager.getResponses(0);
        assertEq(responses.length, 1);
        assertEq(responses[0].selectedOption, 1);
        assertEq(responses[0].participant, address(this));
    }

    function testSubmitResponseWithoutRegistration() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for unregistered participation", options, expiryTimestamp, maxDataPoints);

        // Ensure anyone can submit a response without registration
        address unregisteredUser = address(0x1234);
        vm.prank(unregisteredUser);
        responseManager.submitResponse(0, 1);
        ResponseManager.Response[] memory responses = responseManager.getResponses(0);
        assertEq(responses.length, 1);
        assertEq(responses[0].selectedOption, 1);
        assertEq(responses[0].participant, unregisteredUser);
    }

    function testLastMinuteSubmissions() public {
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 4;

        surveyManager.createSurvey("Test for last minute submissions", options, expiryTimestamp, maxDataPoints);

        // Warp time to 1 second before survey expiry
        vm.warp(expiryTimestamp - 1);
        responseManager.submitResponse(0, 0);
        address unregisteredUser = address(0x1234);
        vm.prank(unregisteredUser);
        responseManager.submitResponse(0, 1);
        address unregisteredUser2 = address(0x5678);
        vm.prank(unregisteredUser2);
        responseManager.submitResponse(0, 2);

        // Ensure the survey is still active
        SurveyManager.Survey memory survey = surveyManager.getSurvey(0);
        assertEq(survey.numResponses, 3);
        assert(survey.isActive);

        // Warp time to survey expiry
        vm.warp(expiryTimestamp);

        // Ensure the survey is closed
        survey = surveyManager.getSurvey(0);
        assert(!survey.isActive);
    }
}
```

#RewardManager.t.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/UserManager.sol";
import "../src/SurveyManager.sol";
import "../src/ResponseManager.sol";
import "../src/RewardManager.sol";

contract RewardManagerTest is Test {
    UserManager userManager;
    SurveyManager surveyManager;
    ResponseManager responseManager;
    RewardManager rewardManager;

    function setUp() public {
        userManager = new UserManager();
        surveyManager = new SurveyManager(address(userManager));
        responseManager = new ResponseManager(address(surveyManager));
        rewardManager = new RewardManager(address(responseManager));

        // Register a user and create a survey for testing reward distribution
        userManager.register("Alice");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        surveyManager.createSurvey("Reward Manager Test Survey", options, block.timestamp + 1 days, 100);
        responseManager.submitResponse(0, 1);
    }

    function testDistributeRewards() public {
        vm.deal(address(rewardManager), 1 ether);
        rewardManager.distributeRewards(0);
        
        address participant = address(this);
        assertEq(rewardManager.rewards(participant), 1 ether);
    }

    function testClaimReward() public {
        address participant = address(this);

        // Ensure the contract has enough Ether to distribute
        vm.deal(address(rewardManager), 1 ether);
        assert(address(rewardManager).balance == 1 ether);

        rewardManager.distributeRewards(0);

        uint256 initialBalance = participant.balance;

        // Adding a log to check the balance before claiming
        console.log("Contract balance before claim:", address(rewardManager).balance);
        console.log("Participant reward before claim:", rewardManager.rewards(participant));
        console.log("Participant initial balance:", initialBalance);

        rewardManager.claimReward();

        uint256 finalBalance = participant.balance;

        console.log("Participant balance after claim:", finalBalance);

        assert(finalBalance > initialBalance);
    }

    receive() external payable {
        console.log("Received Ether:", msg.value);
    }

    fallback() external payable {
        console.log("Fallback called. Received Ether:", msg.value);
    }
}
```

#SurveyManager.t.sol
```solidity 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/UserManager.sol";
import "../src/SurveyManager.sol";

contract SurveyManagerTest is Test {
    UserManager userManager;
    SurveyManager surveyManager;

    function setUp() public {
        userManager = new UserManager();
        surveyManager = new SurveyManager(address(userManager));
    }

    //write test cases that intentionally fail each of the checks within createSurvey of SurveyManager.sol
    function testCreateSurveyUserNotRegistered() public {
        vm.expectRevert("User not registered");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for User Not Registered", options, expiryTimestamp, maxDataPoints);
    }

    function testCreateSurveyNoOptions() public {
        userManager.register("Alice");
        vm.expectRevert("Survey must have at least one option");
        uint256[] memory options = new uint256[](0);

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for at least 1 option", options, expiryTimestamp, maxDataPoints);
    }

    function testCreateSurveyExpiryTimestampInPast() public {
        userManager.register("David");
        vm.expectRevert("Expiry timestamp must be in the future");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp - 1;
        uint256 maxDataPoints = 100;

        surveyManager.createSurvey("Test for a future expiry timestamp", options, expiryTimestamp, maxDataPoints);
    }

    function testCreateSurveyMaxDataPointsZero() public {
        userManager.register("Alice");
        vm.expectRevert("Max data points must be greater than zero");
        uint256[] memory options = new uint256[](3);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;

        uint256 expiryTimestamp = block.timestamp + 1 days;
        uint256 maxDataPoints = 0;

        surveyManager.createSurvey("Test for multiple max data points", options, expiryTimestamp, maxDataPoints);
    }

    function testCreateSurvey() public {
        userManager.register("Bob");
        uint256[] memory options = new uint256[](2);
        options[0] = 5;
        options[1] = 10;

        uint256 expiryTimestamp = block.timestamp + 2 days;
        uint256 maxDataPoints = 50;

        surveyManager.createSurvey("Test for successful survey creation", options, expiryTimestamp, maxDataPoints);
    }

    function testSurveyAttributes() public {
        userManager.register("Charlie");
        uint256[] memory options = new uint256[](4);
        options[0] = 1;
        options[1] = 2;
        options[2] = 3;
        options[3] = 4;

        uint256 expiryTimestamp = block.timestamp + 3 days;
        uint256 maxDataPoints = 200;

        surveyManager.createSurvey("Test for proper survey attributes!", options, expiryTimestamp, maxDataPoints);

        SurveyManager.Survey memory survey = surveyManager.getSurvey(0);
        assertEq(survey.question, "Test for proper survey attributes!");
        assertEq(survey.options.length, 4);
        assertEq(survey.options[0], 1);
        assertEq(survey.options[1], 2);
        assertEq(survey.options[2], 3);
        assertEq(survey.options[3], 4);
        assertEq(survey.expiryTimestamp, expiryTimestamp);
        assertEq(survey.maxDataPoints, maxDataPoints);
    }

    function testGetActiveSurveys() public {
        userManager.register("Alice");
        uint256[] memory options1 = new uint256[](3);
        options1[0] = 1;
        options1[1] = 2;
        options1[2] = 3;

        uint256[] memory options2 = new uint256[](4);
        options2[0] = 10;
        options2[1] = 20;
        options2[2] = 30;
        options2[3] = 40;

        uint256 expiryTimestamp1 = block.timestamp + 1 days;
        uint256 expiryTimestamp2 = block.timestamp + 2 days;

        uint256 maxDataPoints1 = 100;
        uint256 maxDataPoints2 = 150;

        surveyManager.createSurvey("Test for getting active survey", options1, expiryTimestamp1, maxDataPoints1);
        surveyManager.createSurvey("Test for getting more than one active survey", options2, expiryTimestamp2, maxDataPoints2);

        SurveyManager.Survey[] memory activeSurveys = surveyManager.getActiveSurveys();
        assertEq(activeSurveys.length, 2);
        assertEq(activeSurveys[0].question, "Test for getting active survey");
        assertEq(activeSurveys[1].question, "Test for getting more than one active survey");
    }

    function testCloseSurveyManually() public {
        userManager.register("Bob");
        uint256[] memory options = new uint256[](2);
        options[0] = 15;
        options[1] = 30;

        uint256 expiryTimestamp = block.timestamp + 2 days;
        uint256 maxDataPoints = 50;

        surveyManager.createSurvey("Test for manual survey closing", options, expiryTimestamp, maxDataPoints);

        surveyManager.closeSurveyManually(0);
        SurveyManager.Survey memory survey = surveyManager.getSurvey(0);
        assertEq(survey.isActive, false);
    }

    function testOnlyOwnerCanCloseSurveyManually() public {
        userManager.register("Bob");
        uint256[] memory options = new uint256[](2);
        options[0] = 25;
        options[1] = 50;

        uint256 expiryTimestamp = block.timestamp + 2 days;
        uint256 maxDataPoints = 50;

        surveyManager.createSurvey("Test that only owner can close survey", options, expiryTimestamp, maxDataPoints);
        
        address unregisteredUser = address(0x4321);
        vm.prank(unregisteredUser);
        vm.expectRevert("Only the survey creator can close the survey");
        surveyManager.closeSurveyManually(0);
    }
}
```

#UserManager.t.sol
```solidity 
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
```