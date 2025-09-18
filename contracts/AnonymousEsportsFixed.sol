// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint8, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/**
 * @title AnonymousEsportsFixed
 * @dev Anonymous Esports Competition Platform using Zama FHE - Fixed version
 * @notice All votes and evaluations are encrypted for complete anonymity
 */
contract AnonymousEsportsFixed is SepoliaConfig {

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
        ebool encryptedVote; // FHE encrypted boolean vote (true = support, false = oppose)
        euint8 encryptedRating; // FHE encrypted rating (1-5: poor to excellent)
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
        address indexed voter
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
     * @dev Submit a confidential vote for a competition - simplified version
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

        // Encrypt the vote and rating using FHE - following reference pattern
        ebool encryptedVote = FHE.asEbool(_vote);
        euint8 encryptedRating = FHE.asEuint8(_rating);

        // Set ACL permissions
        FHE.allowThis(encryptedVote);
        FHE.allowThis(encryptedRating);

        votes[voteCounter] = Vote({
            competitionId: _competitionId,
            voter: msg.sender,
            encryptedVote: encryptedVote,
            encryptedRating: encryptedRating,
            timestamp: block.timestamp
        });

        competitionVotes[_competitionId].push(voteCounter);
        hasVoted[msg.sender][_competitionId] = true;
        competitions[_competitionId].voteCount++;

        emit VoteSubmitted(voteCounter, _competitionId, msg.sender);
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