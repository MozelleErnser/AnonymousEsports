// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SimpleEsports
 * @dev Simple Esports Competition Platform - Working version first, then add FHE
 * @notice Simplified voting system that works
 */
contract SimpleEsports {

    struct Competition {
        uint256 id;
        string title;
        string description;
        string gameType;
        address organizer;
        uint256 timestamp;
        uint256 voteCount;
        bool isActive;
    }

    struct Vote {
        uint256 competitionId;
        address voter;
        bool vote; // true = support, false = oppose
        uint8 rating; // 1-5: poor to excellent
        uint256 timestamp;
    }

    // State variables
    uint256 public competitionCounter;
    uint256 public voteCounter;
    address public owner;

    mapping(uint256 => Competition) public competitions;
    mapping(uint256 => Vote) public votes;
    mapping(uint256 => uint256[]) public competitionVotes; // competitionId => voteIds
    mapping(address => uint256[]) public userCompetitions; // organizer => competitionIds
    mapping(address => mapping(uint256 => bool)) public hasVoted; // voter => competitionId => bool

    // Events
    event CompetitionCreated(
        uint256 indexed competitionId,
        address indexed organizer,
        string title,
        string gameType
    );

    event VoteSubmitted(
        uint256 indexed voteId,
        uint256 indexed competitionId,
        address indexed voter,
        bool vote,
        uint8 rating
    );

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Create a new esports competition
     */
    function createCompetition(
        string memory _title,
        string memory _description,
        string memory _gameType
    ) external {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(bytes(_gameType).length > 0, "Game type cannot be empty");

        competitionCounter++;

        competitions[competitionCounter] = Competition({
            id: competitionCounter,
            title: _title,
            description: _description,
            gameType: _gameType,
            organizer: msg.sender,
            timestamp: block.timestamp,
            voteCount: 0,
            isActive: true
        });

        userCompetitions[msg.sender].push(competitionCounter);

        emit CompetitionCreated(competitionCounter, msg.sender, _title, _gameType);
    }

    /**
     * @dev Submit a vote for a competition - simplified working version
     * @param _competitionId The ID of the competition to vote on
     * @param _vote Boolean vote (true = support, false = oppose)
     * @param _rating Quality rating (1-5: poor to excellent)
     */
    function submitVote(
        uint256 _competitionId,
        bool _vote,
        uint8 _rating
    ) external {
        require(_competitionId > 0 && _competitionId <= competitionCounter, "Invalid competition ID");
        require(competitions[_competitionId].isActive, "Competition is not active");
        require(competitions[_competitionId].organizer != msg.sender, "Cannot vote on your own competition");
        require(!hasVoted[msg.sender][_competitionId], "Already voted on this competition");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        voteCounter++;

        votes[voteCounter] = Vote({
            competitionId: _competitionId,
            voter: msg.sender,
            vote: _vote,
            rating: _rating,
            timestamp: block.timestamp
        });

        competitionVotes[_competitionId].push(voteCounter);
        hasVoted[msg.sender][_competitionId] = true;
        competitions[_competitionId].voteCount++;

        emit VoteSubmitted(voteCounter, _competitionId, msg.sender, _vote, _rating);
    }

    /**
     * @dev Get all competitions available for voting (excluding user's own competitions)
     */
    function getCompetitionsForVoting() external view returns (Competition[] memory) {
        uint256 availableCount = 0;

        // Count competitions that are not organized by the caller
        for (uint256 i = 1; i <= competitionCounter; i++) {
            if (competitions[i].isActive && competitions[i].organizer != msg.sender && !hasVoted[msg.sender][i]) {
                availableCount++;
            }
        }

        Competition[] memory availableCompetitions = new Competition[](availableCount);
        uint256 index = 0;

        for (uint256 i = 1; i <= competitionCounter; i++) {
            if (competitions[i].isActive && competitions[i].organizer != msg.sender && !hasVoted[msg.sender][i]) {
                availableCompetitions[index] = competitions[i];
                index++;
            }
        }

        return availableCompetitions;
    }

    /**
     * @dev Get competition count
     */
    function getCompetitionCount() external view returns (uint256) {
        return competitionCounter;
    }

    /**
     * @dev Get user's organized competitions
     */
    function getUserCompetitions() external view returns (Competition[] memory) {
        uint256[] memory userCompetitionIds = userCompetitions[msg.sender];
        Competition[] memory userOrganizedCompetitions = new Competition[](userCompetitionIds.length);

        for (uint256 i = 0; i < userCompetitionIds.length; i++) {
            userOrganizedCompetitions[i] = competitions[userCompetitionIds[i]];
        }

        return userOrganizedCompetitions;
    }

    /**
     * @dev Get votes for a specific competition (public in this simple version)
     */
    function getCompetitionVotes(uint256 _competitionId) external view returns (Vote[] memory) {
        require(_competitionId > 0 && _competitionId <= competitionCounter, "Invalid competition ID");

        uint256[] memory voteIds = competitionVotes[_competitionId];
        Vote[] memory competitionVotesArray = new Vote[](voteIds.length);

        for (uint256 i = 0; i < voteIds.length; i++) {
            competitionVotesArray[i] = votes[voteIds[i]];
        }

        return competitionVotesArray;
    }

    /**
     * @dev Toggle competition active status (only competition organizer)
     */
    function toggleCompetitionStatus(uint256 _competitionId) external {
        require(_competitionId > 0 && _competitionId <= competitionCounter, "Invalid competition ID");
        require(competitions[_competitionId].organizer == msg.sender, "Only competition organizer can toggle status");

        competitions[_competitionId].isActive = !competitions[_competitionId].isActive;
    }

    /**
     * @dev Get total counts
     */
    function getTotalCounts() external view returns (uint256 totalCompetitions, uint256 totalVotes) {
        return (competitionCounter, voteCounter);
    }
}