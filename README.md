### Track 5: Blockchain Survey System

In this track, you will be building a blockchain survey system that collects user responses anonymously. To simplify the problem, we restrict each survey to a single choice question with integer values for each option. Similar to platforms like SurveyMonkey, the blockchain survey system will have the following main functionalities:

## A user can register customized account names and use her blockchain address to log in to the survey system; or alternatively, the system needs some form of account management. Registration is only for starting a new survey, but to participate a survey, one doesn't need to register.
### Completed
- Users can register customized account names
### In Progress
- 
### Not Implemented
- Users can log in and just answer stuff
- Anyone can just answer without being registered

## A registered user can create a new survey, which consists of a problem description and several numerical options. The survey should has an expiry block timestamp and maximum number of data points accepted.
### Completed
- Test for registered users
- Test for expiry timestamp
- Test for max number of data points
### In Progress 
### Not Implemented
- Test for a problem description
- Test for NUMERICAL options
- Test for more than one option

## One can view any active survey and its available options via its ID and participate in it by submitting her choice (only once for each ID).
### Completed
- Users can submit survey answers!
### In Progress
- 
### Not Implemented
- Viewing surveys
- Only one submission per ID

## A survey owner can close the survey or wait for it to close after the expiry block timestamp or when it reaches the maximum accepted data points. When a survey is closed, certain reward in ETH will be sent to the users participating in it.
### Completed
- Surveys close at max entry points, they also close if the expiry block timestamp is in the past. 
### In Progress
- Surveys close if the block timestamp expires, need to check with vm warping
### Not Implemented
- Owners CANNOT yet close surveys themselves
- No rewards are sent

## On a survey expiry block, the survey will always close after receiving all incoming data points in the same block (last minute submission).
### Completed
- 
### In Progress
- Need to fix logic for multiple last minute submissions
### Not Implemented
- Test case to verify last minute submission success


# Ordered Task List
1. Viewing surveys (basic functionality to check surveys).
2. Only one submission per ID (adds constraint to survey responses).
3. Allow anyone to answer without registration (broadens participant base).
4. Allow users to log in and answer (enhances user management).
5. Test for problem description in surveys (complete tests for survey creation).
6. Test for numerical options (ensure options are correctly handled).
7. Test for more than one option (verify surveys can have multiple options).
8. Owners can close surveys themselves (add flexibility for survey closure).
9. Distribute rewards to participants (implement reward logic).
10. Fix logic for multiple last-minute submissions (handle edge cases).
11. Test case for last-minute submission success (validate last-minute logic).