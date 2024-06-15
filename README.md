# Blockchain Survey System

## Overview

This project is a blockchain-based survey system that allows users to create, participate in, and manage surveys securely and anonymously. The system includes smart contracts for managing users, surveys, responses, and rewards.

## Table of Contents

- [APIs](#apis)
- [Functional Tests](#functional-tests)
- [Penetrative Tests](#penetrative-tests)
- [Setup](#setup)

## APIs
### UserManager
#### Registered User
- Can register, create surveys, submit responses, and claim rewards.
- Can view surveys and their responses.
#### Anonymous User
- Can participant in surveys.
- Cannot create surveys, claim rewards.
- **Register User**
  - **Function:** `register(string memory _username)`
  - **Description:** Registers a new user in the system with a given username.
  - **Returns:** None.
  - **Notes:** Only callable by addresses not already registered. Throws an error if the address is already registered.

- **Check if User is Registered**
  - **Function:** `isRegistered(address _userAddress) public view returns (bool)`
  - **Description:** Checks if a user is registered.
  - **Returns:** `bool` indicating whether the user is registered.

- **Get Username**
  - **Function:** `getUsername(address _userAddress) public view returns (string memory)`
  - **Description:** Retrieves the username of a registered user.
  - **Returns:** `string` containing the username.
  - **Notes:** Only callable for registered users. Throws an error if the user is not registered.

- **Get Reputation**
  - **Function:** `getReputation(address _userAddress) public view returns (uint256)`
  - **Description:** Retrieves the reputation of a registered user.
  - **Returns:** `uint256` containing the reputation.
  - **Notes:** Only callable for registered users. Throws an error if the user is not registered.

- **Increase Reputation**
  - **Function:** `increaseReputation(address _userAddress, uint256 _reputationEarned)`
  - **Description:** Increases the reputation of a registered user by the amount specified.
  - **Returns:** None.
  - **Notes:** Only callable for registered users. Logs a message without updating any value if the user is not registered. If a user's reputation would increase above the maximum, clamp to the maximum value. 

### SurveyManager

- **Create Survey**
  - **Function:** `createSurvey(string memory _question, uint256[] memory _options, uint256 _expiryTimestamp, uint256 _maxDataPoints, uint256 _reward) public`
  - **Description:** Creates a new survey with the specified question, options, expiry timestamp, maximum data points, and reward.
  - **Returns:** None.
  - **Notes:** Only callable by registered users. The question must not be empty, there must be at least one option, the expiry timestamp must be in the future, the maximum data points must be greater than zero, and the reward must be greater than zero.

- **Update Survey Data Points**
  - **Function:** `updateSurveyDataPoints(uint256 _surveyId) external`
  - **Description:** Updates the number of responses for a survey when a user responds.
  - **Returns:** None.

- **Close Survey Manually**
  - **Function:** `closeSurveyManually(uint256 _surveyId) external`
  - **Description:** Closes a survey manually by its creator.
  - **Returns:** None.
  - **Notes:** Only callable by the survey creator.

- **Check Survey**
  - **Function:** `checkSurvey(uint256 _surveyId) public`
  - **Description:** Checks if a survey is active and if it needs to be closed based on expiry or maximum data points.
  - **Returns:** None.

- **Get Survey**
  - **Function:** `getSurvey(uint256 _surveyId) public returns (Survey memory)`
  - **Description:** Retrieves the details of a survey.
  - **Returns:** `Survey` struct containing the survey details.

- **Get Active Surveys**
  - **Function:** `getActiveSurveys() public view returns (Survey[] memory)`
  - **Description:** Retrieves all active surveys.
  - **Returns:** `Survey[]` array containing active surveys.

### ResponseManager

- **Submit Response**
  - **Function:** `submitResponse(uint256 _surveyId, uint256 _selectedOption) public`
  - **Description:** Submits a response to a specified survey.
  - **Returns:** None.
  - **Notes:** 
    - The survey must be active and not expired.
    - The selected option must be valid.
    - The user must not have already responded to the survey.
    - Updates the survey data points, increases user reputation, distributes rewards, and checks if the survey needs to be closed.

- **Get Responses**
  - **Function:** `getResponses(uint256 _surveyId) public view returns (Response[] memory)`
  - **Description:** Retrieves all responses for a specified survey.
  - **Returns:** `Response[]` array containing responses for the survey.


### RewardManager

- **Distribute Rewards**
  - **Function:** `distributeRewards(uint256 _surveyId, address _userAddress, uint256 amount) public`
  - **Description:** Distributes rewards to a user for a specified survey.
  - **Returns:** None.
  - **Notes:** Adds the specified amount to the user's rewards balance.

- **Claim Reward**
  - **Function:** `claimReward() public`
  - **Description:** Allows a user to claim their accumulated rewards.
  - **Returns:** None.
  - **Notes:** 
    - The user must have a non-zero rewards balance.
    - The contract must have sufficient balance to fulfill the transfer.
    - Transfers the rewards to the user's address.

- **Receive Ether**
  - **Function:** `receive() external payable`
  - **Description:** Handles receiving Ether sent directly to the contract.
  - **Returns:** None.
  - **Notes:** Logs the amount of Ether received.

- **Fallback Function**
  - **Function:** `fallback() external payable`
  - **Description:** Handles fallback functionality for the contract.
  - **Returns:** None.
  - **Notes:** Logs the amount of Ether received.

## Functional Tests
### UserManagerTest

- **Setup**
  - **Function:** `setUp() public`
  - **Description:** Initializes the `UserManager` contract before each test.
  - **Returns:** None.

- **Test Register User**
  - **Function:** `testRegisterUser() public`
  - **Description:** Ensures that a username is saved and can be retrieved properly using `getUsername`.
  - **Returns:** None.
  - **Assertions:** 
    - Registers a user with the username "Alice".
    - Asserts that the username retrieved matches "Alice".

- **Test Duplicate Register User**
  - **Function:** `testDuplicateRegisterUser() public`
  - **Description:** Ensures that the same blockchain address cannot register more than once.
  - **Returns:** None.
  - **Assertions:** 
    - Registers a user with the username "Alice".
    - Expects a revert with the message "Blockchain address already registered to an account" when attempting to register again with a different username.

### SurveyManagerTest

- **Setup**
  - **Function:** `setUp() public`
  - **Description:** Initializes the `UserManager`, `SurveyManager`, `RewardManager`, and `ResponseManager` contracts before each test.
  - **Returns:** None.

#### Survey Tests Section 1: Invalid Survey Creation Scenarios

- **Test Create Survey - User Not Registered**
  - **Function:** `testCreateSurveyUserNotRegistered() public`
  - **Description:** Ensures that only registered users can create surveys.
  - **Returns:** None.
  - **Assertions:** Expects a revert with the message "User not registered".

- **Test Create Survey - No Question**
  - **Function:** `testCreateSurveyNoQuestion() public`
  - **Description:** Ensures that the survey question must not be empty.
  - **Returns:** None.
  - **Assertions:** Expects a revert with the message "Question must not be empty".

- **Test Create Survey - No Options**
  - **Function:** `testCreateSurveyNoOptions() public`
  - **Description:** Ensures that the survey must have at least one option.
  - **Returns:** None.
  - **Assertions:** Expects a revert with the message "Survey must have at least one option".

- **Test Create Survey - Expiry Timestamp In Past**
  - **Function:** `testCreateSurveyExpiryTimestampInPast() public`
  - **Description:** Ensures that the expiry timestamp must be in the future.
  - **Returns:** None.
  - **Assertions:** Expects a revert with the message "Expiry timestamp must be in the future".

- **Test Create Survey - Max Data Points Zero**
  - **Function:** `testCreateSurveyMaxDataPointsZero() public`
  - **Description:** Ensures that the maximum data points must be greater than zero.
  - **Returns:** None.
  - **Assertions:** Expects a revert with the message "Max data points must be greater than zero".

- **Test Create Survey - No Reward**
  - **Function:** `testCreateSurveyNoReward() public`
  - **Description:** Ensures that the survey must have a reward greater than zero.
  - **Returns:** None.
  - **Assertions:** Expects a revert with the message "Reward must be greater than zero".

#### Survey Tests Section 2: Valid Survey Creation Scenarios

- **Test Create Survey**
  - **Function:** `testCreateSurvey() public`
  - **Description:** Ensures that a survey can be created successfully.
  - **Returns:** None.
  - **Assertions:** Verifies that the survey is created without any reverts.

- **Test Survey Attributes**
  - **Function:** `testSurveyAttributes() public`
  - **Description:** Ensures that survey attributes can be retrieved after creation.
  - **Returns:** None.
  - **Assertions:** 
    - Verifies that the survey question, options, expiry timestamp, maximum data points, and reward are correctly set.

- **Test Get Active Surveys**
  - **Function:** `testGetActiveSurveys() public`
  - **Description:** Ensures that multiple active surveys can be retrieved.
  - **Returns:** None.
  - **Assertions:** 
    - Verifies that active surveys are correctly listed and their attributes match the expected values.

#### Survey Tests Section 3: Survey Closure

- **Test Close Survey Manually**
  - **Function:** `testCloseSurveyManually() public`
  - **Description:** Ensures that a survey can be closed manually by its creator.
  - **Returns:** None.
  - **Assertions:** 
    - Verifies that the survey is no longer active after being closed manually.

- **Test Only Owner Can Close Survey Manually**
  - **Function:** `testOnlyOwnerCanCloseSurveyManually() public`
  - **Description:** Ensures that only the survey creator can close the survey manually.
  - **Returns:** None.
  - **Assertions:** Expects a revert with the message "Only the survey creator can close the survey" when an unauthorized user attempts to close the survey.


### ResponseManagerTest

- **Setup**
  - **Function:** `setUp() public`
  - **Description:** Initializes the `UserManager`, `SurveyManager`, `RewardManager`, and `ResponseManager` contracts before each test. Registers a user "Alice" for testing.
  - **Returns:** None.

#### Response Submission Tests

- **Test Submit Response**
  - **Function:** `testSubmitResponse() public`
  - **Description:** Ensures that responses are submitted and stored in the contract.
  - **Returns:** None.
  - **Assertions:** 
    - Verifies that the response is correctly stored and can be retrieved.

- **Test Only One Submission Per User Per Survey**
  - **Function:** `testOnlyOneSubmissionPerID() public`
  - **Description:** Ensures that only one response can be submitted per user per survey.
  - **Returns:** None.
  - **Assertions:** Expects a revert with the message "User has already responded to this survey" when attempting a second submission.

- **Test Submit Response to Expired Survey**
  - **Function:** `testSubmitResponseSurveyExpired() public`
  - **Description:** Ensures that responses cannot be submitted to expired surveys.
  - **Returns:** None.
  - **Assertions:** Expects a revert with the message "Survey has expired".

- **Test Submit Response When Max Data Points Reached**
  - **Function:** `testSubmitResponseMaxDataPointsReached() public`
  - **Description:** Ensures that responses cannot be submitted once the maximum data points are reached.
  - **Returns:** None.
  - **Assertions:** Expects a revert with the message "Max data points reached".

- **Test Submit Response with Invalid Option**
  - **Function:** `testSubmitResponseInvalidOption() public`
  - **Description:** Ensures that participants cannot select an option that does not exist in the survey.
  - **Returns:** None.
  - **Assertions:** Expects a revert with the message "Invalid option".

#### Response Retrieval Tests

- **Test Get Responses**
  - **Function:** `testGetResponses() public`
  - **Description:** Ensures that responses for a survey can be retrieved.
  - **Returns:** None.
  - **Assertions:** 
    - Verifies that the responses are correctly retrieved and match the expected values.

#### Special Response Submission Scenarios

- **Test Submit Response Without Registration**
  - **Function:** `testSubmitResponseWithoutRegistration() public`
  - **Description:** Ensures that anyone can submit a response without registration.
  - **Returns:** None.
  - **Assertions:** 
    - Verifies that unregistered users can submit responses and that the responses are correctly stored.

- **Test Last Minute Submissions**
  - **Function:** `testLastMinuteSubmissions() public`
  - **Description:** Ensures that responses can be submitted up until the last minute before survey expiry.
  - **Returns:** None.
  - **Assertions:** 
    - Verifies that the survey remains active until the expiry block is completed.
    - Ensures the survey is closed immediately after the expiry block.

#### User Reputation Tests

- **Test Increase Reputation**
  - **Function:** `testIncreaseReputation() public`
  - **Description:** Ensures that user reputation is increased after submitting a response.
  - **Returns:** None.
  - **Assertions:** 
    - Verifies that the user's reputation is correctly incremented after submitting responses.

#### Security Tests
- **Test Reputation Overflow Attack**
  - **Function:** `testReputationOverflow() public`
  - **Description:** Ensures that an overflow attack is prevented when increasing user reputation.
  - **Returns:** None.
  - **Assertions:** The increaseReputation() function within UserManager should handle overflow gracefully.

### RewardManagerTest

- **Setup**
  - **Function:** `setUp() public`
  - **Description:** Initializes the `UserManager`, `SurveyManager`, `ResponseManager`, and `RewardManager` contracts before each test. Registers a user "Alice" and creates a survey for testing reward distribution.
  - **Returns:** None.

#### Reward Distribution and Claim Tests

- **Test Distribute Rewards**
  - **Function:** `testDistributeRewards() public`
  - **Description:** Ensures that the correct amount of rewards is distributed to the participant.
  - **Returns:** None.
  - **Assertions:** 
    - Verifies that the rewards are correctly added to the participant's reward balance.

- **Test Claim Reward**
  - **Function:** `testClaimReward() public`
  - **Description:** Ensures that rewards can be claimed by participants.
  - **Returns:** None.
  - **Assertions:** 
    - Verifies that the participant's balance is correctly increased by the reward amount after claiming.

#### Ether Handling Tests

- **Receive Ether**
  - **Function:** `receive() external payable`
  - **Description:** Handles receiving Ether sent directly to the contract.
  - **Returns:** None.
  - **Notes:** Logs the amount of Ether received.

- **Fallback Function**
  - **Function:** `fallback() external payable`
  - **Description:** Handles fallback functionality for the contract.
  - **Returns:** None.
  - **Notes:** Logs the amount of Ether received.
 
## Penetrative Tests

### ResponseManagerTest

- **Test Only One Submission Per User Per Survey**
  - **Function:** `testOnlyOneSubmissionPerID() public`
  - **Description:** Ensures that only one response can be submitted per user per survey.
  - **Security Issue:** Prevents multiple submissions by the same user.
  - **Assertions:** Expects a revert with the message "User has already responded to this survey" when attempting a second submission.

- **Test Submit Response When Max Data Points Reached**
  - **Function:** `testSubmitResponseMaxDataPointsReached() public`
  - **Description:** Ensures that responses cannot be submitted once the maximum data points are reached.
  - **Security Issue:** Prevents exceeding the maximum data points limit.
  - **Assertions:** Expects a revert with the message "Max data points reached".

- **Test Submit Response with Invalid Option**
  - **Function:** `testSubmitResponseInvalidOption() public`
  - **Description:** Ensures that participants cannot select an option that does not exist in the survey.
  - **Security Issue:** Prevents invalid option selection.
  - **Assertions:** Expects a revert with the message "Invalid option".

- **Test Reputation Overflow Attack**
  - **Function:** `testReputationOverflow() public`
  - **Description:** Ensures that an overflow attack is prevented when increasing user reputation.
  - **Security Issue:** Prevents reputation overflow.
  - **Assertions:** The increaseReputation() function within UserManager should handle overflow gracefully.

- **Test Front Running Attack**
  - **Function:** `testPreventFrontRunning() public`
  - **Description:** Ensures that a front running attack is prevented when submitting responses with higher gas.
  - **Security Issue:** Prevents front running attacks.
  - **Assertions:** Verifies that the legitimate response is processed first in the responses.

### RewardManagerTest

- **Test Overflow Attack**
  - **Function:** `testOverflow() public`
  - **Description:** Ensures that an overflow attack is prevented when distributing rewards.
  - **Security Issue:** Prevents reward overflow.
  - **Assertions:** Expects a revert when attempting to overflow the rewards balance.

- **Test Reentrancy Attack**
  - **Function:** `testReentrancyAttack() public`
  - **Description:** Ensures that the contract is protected against reentrancy attacks when claiming rewards.
  - **Security Issue:** Prevents reentrancy attacks.
  - **Assertions:** Verifies that no extra Ether is claimed through a reentrant attack.

### SurveyManagerTest

- **Test Survey Responses Overflow**
  - **Function:** `testSurveyResponsesOverflow() public`
  - **Description:** Ensures that increasing the number of responses does not cause overflow.
  - **Security Issue:** Prevents overflow in the number of survey responses.
  - **Assertions:** Verifies that the number of responses is correctly incremented without overflow.

- **Test Only Owner Can Close Survey Manually**
  - **Function:** `testOnlyOwnerCanCloseSurveyManually() public`
  - **Description:** Ensures that only the survey creator can close the survey manually.
  - **Security Issue:** Prevents unauthorized users from prematurely closing surveys.
  - **Assertions:** Expects a revert with the message "Only the survey creator can close the survey" when an unauthorized user attempts to close the survey.

- **Test Create Survey User Not Registered**
  - **Function:** `testCreateSurveyUserNotRegistered() public`
  - **Description:** Ensures that only registered users can create surveys.
  - **Security Issue:** Prevents unauthorized users from creating surveys.
  - **Assertions:** Expects a revert with the message "User not registered" when an unregistered user attempts to create a survey.

- **Test Survey Creation Max Data Points Overflow**
  - **Function:** `testSurveyCreationMaxDataPointsOverflow() public`
  - **Description:** Ensures that creating a survey with an extremely large maxDataPoints does not cause any overflow issues.
  - **Security Issue:** Prevents overflow in survey creation.
  - **Assertions:** Expects a revert with the message "Max data points too large" when attempting to create a survey with an excessively large maxDataPoints.


## Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/dhruvna/CS190J-SurveyChain-Project.git
   cd CS190J-SurveyChain-Project
   ```
2. ```bash
   forge test
   ```
    (Can add -vvv for more verbose logging)
