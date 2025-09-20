# Hello FHEVM: Your First Confidential dApp Tutorial

Welcome to the most beginner-friendly introduction to building confidential applications with FHEVM! This tutorial will guide you through creating your first privacy-preserving dApp using Zama's Fully Homomorphic Encryption technology.

## 🎯 What You'll Build

By the end of this tutorial, you'll have created a **Confidential Anonymous Voting dApp** where:
- Users can vote anonymously on esports competitions
- All votes are encrypted on-chain using FHE
- Vote tallying happens without revealing individual choices
- Complete privacy is maintained while ensuring transparency

## 🎓 Prerequisites

### What You Need to Know
- **Solidity Basics**: Ability to write and deploy simple smart contracts
- **Web3 Fundamentals**: Basic understanding of blockchain, MetaMask, and dApps
- **JavaScript/HTML**: Basic frontend development skills
- **Development Tools**: Familiarity with standard Ethereum tools

### What You DON'T Need
- ❌ No advanced mathematics or cryptography knowledge required
- ❌ No prior FHE (Fully Homomorphic Encryption) experience needed
- ❌ No complex deployment setup - we'll use simple static hosting

## 🚀 Learning Objectives

After completing this tutorial, you will understand:

1. **FHE Fundamentals**: How Fully Homomorphic Encryption works in smart contracts
2. **Confidential Data Types**: Using `euint8`, `ebool`, and other encrypted types
3. **Privacy-Preserving Logic**: Building applications that compute on encrypted data
4. **FHEVM Integration**: Connecting frontend to FHE-enabled smart contracts
5. **Real-World Applications**: Practical use cases for confidential computing

## 📚 Table of Contents

1. [Understanding FHEVM Basics](#understanding-fhevm-basics)
2. [Setting Up Your Development Environment](#setting-up-development-environment)
3. [Creating Your First FHE Smart Contract](#creating-fhe-smart-contract)
4. [Building the Frontend Interface](#building-frontend-interface)
5. [Implementing Confidential Voting Logic](#implementing-voting-logic)
6. [Testing and Deployment](#testing-deployment)
7. [Advanced Features and Best Practices](#advanced-features)

---

## 1. Understanding FHEVM Basics

### What is Fully Homomorphic Encryption (FHE)?

Imagine you have a locked box where you can perform calculations on the contents without ever opening it. That's essentially what FHE allows us to do with data on the blockchain.

**Traditional Smart Contracts:**
```solidity
uint256 public votes = 0;  // Everyone can see this value
votes = votes + 1;         // Everyone can see this operation
```

**FHE Smart Contracts:**
```solidity
euint8 private encryptedVotes;           // Value is encrypted
encryptedVotes = FHE.add(encryptedVotes, FHE.asEuint8(1)); // Math on encrypted data
```

### Key FHEVM Concepts

#### Encrypted Data Types
- `euint8`, `euint16`, `euint32`: Encrypted unsigned integers
- `ebool`: Encrypted boolean values
- `eaddress`: Encrypted addresses

#### Core FHE Operations
- `FHE.asEuint8(value)`: Convert plain value to encrypted
- `FHE.add(a, b)`: Add two encrypted values
- `FHE.eq(a, b)`: Compare encrypted values
- `FHE.decrypt(encryptedValue)`: Decrypt for authorized parties

### Why Use FHE for Voting?

Traditional voting systems expose vote data, creating risks:
- **Vote Buying**: Others can verify how you voted
- **Coercion**: Pressure to vote certain ways
- **Bias**: Knowing early results influences later voters

FHE solves this by keeping votes encrypted while still allowing:
- ✅ Vote counting and tallying
- ✅ Result verification
- ✅ Audit trails
- ✅ Complete transparency of the process

---

## 2. Setting Up Development Environment

### Required Tools

1. **MetaMask Wallet**: For interacting with the blockchain
2. **Code Editor**: VS Code or similar
3. **Web Browser**: Chrome/Firefox with MetaMask extension
4. **Node.js**: For running local development server (optional)

### Network Configuration

Add Zama Devnet to MetaMask:
- **Network Name**: Zama Devnet
- **RPC URL**: `https://devnet.zama.ai`
- **Chain ID**: `8009`
- **Currency Symbol**: `ZAMA`

### Project Structure

Create a new project directory:
```
anonymous-voting-dapp/
├── contracts/
│   └── AnonymousVoting.sol
├── frontend/
│   ├── index.html
│   ├── styles.css
│   └── app.js
└── README.md
```

---

## 3. Creating Your First FHE Smart Contract

### Basic Contract Structure

Let's start with a simple confidential voting contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint8, ebool } from "@fhevm/solidity/lib/FHE.sol";

contract AnonymousVoting {

    struct Competition {
        uint256 id;
        string title;
        string description;
        address organizer;
        bool isActive;
        euint8 encryptedSupportVotes;   // FHE encrypted vote count
        euint8 encryptedOpposeVotes;    // FHE encrypted vote count
    }

    struct Vote {
        address voter;
        ebool encryptedChoice;          // FHE encrypted vote choice
        euint8 encryptedRating;         // FHE encrypted rating
    }

    mapping(uint256 => Competition) public competitions;
    mapping(uint256 => Vote[]) public competitionVotes;
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    uint256 public competitionCounter;

    event CompetitionCreated(uint256 indexed competitionId, string title);
    event VoteSubmitted(uint256 indexed competitionId, address indexed voter);
}
```

### Key FHE Features Explained

#### 1. Encrypted Storage
```solidity
euint8 encryptedSupportVotes;   // Stores encrypted vote count
ebool encryptedChoice;          // Stores encrypted vote choice
```
These values are permanently encrypted on-chain. No one can see the actual numbers!

#### 2. FHE Operations
```solidity
// Adding encrypted votes
competition.encryptedSupportVotes = FHE.add(
    competition.encryptedSupportVotes,
    FHE.asEuint8(1)
);
```

#### 3. Access Control
```solidity
// Only allow specific addresses to decrypt
FHE.allowThis(encryptedVote);
FHE.allow(encryptedVote, msg.sender);
```

### Complete Voting Function

```solidity
function submitVote(
    uint256 competitionId,
    bool voteChoice,     // true = support, false = oppose
    uint8 rating        // 1-5 rating
) external {
    require(competitions[competitionId].isActive, "Competition not active");
    require(!hasVoted[msg.sender][competitionId], "Already voted");

    // Convert plain values to encrypted
    ebool encryptedChoice = FHE.asEbool(voteChoice);
    euint8 encryptedRating = FHE.asEuint8(rating);

    // Set permissions for the encrypted data
    FHE.allowThis(encryptedChoice);
    FHE.allowThis(encryptedRating);
    FHE.allow(encryptedChoice, msg.sender);
    FHE.allow(encryptedRating, msg.sender);

    // Store the encrypted vote
    competitionVotes[competitionId].push(Vote({
        voter: msg.sender,
        encryptedChoice: encryptedChoice,
        encryptedRating: encryptedRating
    }));

    // Update encrypted vote counters
    Competition storage competition = competitions[competitionId];

    if (voteChoice) {
        // Add to support votes
        competition.encryptedSupportVotes = FHE.add(
            competition.encryptedSupportVotes,
            FHE.asEuint8(1)
        );
    } else {
        // Add to oppose votes
        competition.encryptedOpposeVotes = FHE.add(
            competition.encryptedOpposeVotes,
            FHE.asEuint8(1)
        );
    }

    hasVoted[msg.sender][competitionId] = true;
    emit VoteSubmitted(competitionId, msg.sender);
}
```

### Why This Works

1. **Input Encryption**: `FHE.asEbool()` and `FHE.asEuint8()` encrypt user inputs
2. **Homomorphic Operations**: `FHE.add()` performs math on encrypted data
3. **Access Control**: `FHE.allow()` controls who can decrypt specific values
4. **Privacy Preservation**: Vote counts update without revealing individual votes

---

## 4. Building the Frontend Interface

### HTML Structure

Create a clean, user-friendly interface:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Anonymous Voting DApp</title>
    <script src="https://cdn.ethers.io/lib/ethers-6.8.0.umd.min.js"></script>
</head>
<body>
    <div class="container">
        <header>
            <h1>🎮 Anonymous Esports Voting</h1>
            <p>Vote privately on gaming competitions using FHE technology</p>
        </header>

        <div class="wallet-section">
            <button id="connectWallet">Connect MetaMask</button>
            <div id="walletInfo" class="hidden">
                <span id="walletAddress"></span>
            </div>
        </div>

        <div class="competitions-section">
            <h2>Active Competitions</h2>
            <div id="competitionsList"></div>
        </div>

        <div class="voting-section" id="votingPanel" style="display: none;">
            <h3>Cast Your Anonymous Vote</h3>
            <div class="vote-options">
                <label>
                    <input type="radio" name="vote" value="support"> Support
                </label>
                <label>
                    <input type="radio" name="vote" value="oppose"> Oppose
                </label>
            </div>
            <div class="rating-section">
                <label>Rating (1-5):</label>
                <select id="rating">
                    <option value="1">1 - Poor</option>
                    <option value="2">2 - Fair</option>
                    <option value="3">3 - Good</option>
                    <option value="4">4 - Very Good</option>
                    <option value="5">5 - Excellent</option>
                </select>
            </div>
            <button id="submitVote">Submit Anonymous Vote</button>
        </div>
    </div>
</body>
</html>
```

### JavaScript Integration

```javascript
// Contract configuration
const CONTRACT_ADDRESS = "0xYourContractAddress";
const CONTRACT_ABI = [
    "function submitVote(uint256 competitionId, bool voteChoice, uint8 rating) external",
    "function createCompetition(string title, string description) external",
    "function competitions(uint256) external view returns (uint256, string, string, address, bool)"
];

let provider, signer, contract, userAddress;

// Connect to MetaMask
async function connectWallet() {
    try {
        if (typeof window.ethereum === "undefined") {
            alert("Please install MetaMask!");
            return;
        }

        // Request account access
        await window.ethereum.request({ method: "eth_requestAccounts" });

        // Set up provider and signer
        provider = new ethers.BrowserProvider(window.ethereum);
        signer = await provider.getSigner();
        userAddress = await signer.getAddress();

        // Connect to contract
        contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

        // Update UI
        document.getElementById("connectWallet").textContent = "Connected";
        document.getElementById("walletAddress").textContent =
            `Connected: ${userAddress.substring(0, 6)}...${userAddress.substring(-4)}`;
        document.getElementById("walletInfo").classList.remove("hidden");

        // Load competitions
        loadCompetitions();

    } catch (error) {
        console.error("Connection failed:", error);
        alert("Failed to connect wallet: " + error.message);
    }
}

// Submit encrypted vote
async function submitVote(competitionId) {
    try {
        // Get user selections
        const voteChoice = document.querySelector('input[name="vote"]:checked').value === 'support';
        const rating = parseInt(document.getElementById('rating').value);

        console.log("Submitting encrypted vote...");
        console.log("Competition:", competitionId);
        console.log("Vote:", voteChoice ? "Support" : "Oppose");
        console.log("Rating:", rating);

        // Submit transaction - FHE encryption happens in the smart contract
        const tx = await contract.submitVote(competitionId, voteChoice, rating);

        alert("Vote transaction submitted! Your vote is being encrypted...");
        console.log("Transaction hash:", tx.hash);

        // Wait for confirmation
        await tx.wait();

        alert("✅ Anonymous vote successfully recorded on blockchain!");

        // Hide voting panel
        document.getElementById("votingPanel").style.display = "none";

    } catch (error) {
        console.error("Voting failed:", error);
        alert("Voting failed: " + error.message);
    }
}
```

### Key Frontend Concepts

#### 1. Web3 Integration
```javascript
// Standard Web3 connection - same as any dApp
provider = new ethers.BrowserProvider(window.ethereum);
contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
```

#### 2. FHE Transparency
```javascript
// From frontend perspective, FHE is transparent
// You send plain values, contract handles encryption
await contract.submitVote(competitionId, true, 5);
```

#### 3. Privacy Assurance
Users can be confident their votes are private because:
- Encryption happens in the smart contract
- Individual votes never appear in plain text on-chain
- Only aggregated results can be computed

---

## 5. Implementing Confidential Voting Logic

### Understanding the Vote Flow

1. **User Input**: Plain text vote and rating
2. **Contract Encryption**: Values encrypted using FHE
3. **On-Chain Storage**: Encrypted data stored permanently
4. **Homomorphic Computation**: Vote tallying on encrypted data
5. **Result Publishing**: Only aggregated results revealed

### Advanced FHE Operations

#### Conditional Logic with Encrypted Data
```solidity
function updateVoteCount(uint256 competitionId, ebool encryptedChoice) internal {
    Competition storage comp = competitions[competitionId];

    // FHE conditional: if vote is true, add to support; else add to oppose
    euint8 supportIncrement = FHE.cmux(encryptedChoice, FHE.asEuint8(1), FHE.asEuint8(0));
    euint8 opposeIncrement = FHE.cmux(encryptedChoice, FHE.asEuint8(0), FHE.asEuint8(1));

    comp.encryptedSupportVotes = FHE.add(comp.encryptedSupportVotes, supportIncrement);
    comp.encryptedOpposeVotes = FHE.add(comp.encryptedOpposeVotes, opposeIncrement);
}
```

#### Computing Encrypted Statistics
```solidity
function getEncryptedResults(uint256 competitionId)
    external
    view
    returns (euint8 supportVotes, euint8 opposeVotes)
{
    Competition storage comp = competitions[competitionId];
    return (comp.encryptedSupportVotes, comp.encryptedOpposeVotes);
}
```

### Privacy-Preserving Features

#### 1. Vote Verification Without Revelation
```solidity
// Users can prove they voted without revealing their choice
function hasUserVoted(address user, uint256 competitionId)
    external
    view
    returns (bool)
{
    return hasVoted[user][competitionId];
}
```

#### 2. Encrypted Vote History
```solidity
// Store complete encrypted vote records
mapping(uint256 => Vote[]) public competitionVotes;

struct Vote {
    address voter;              // Public: who voted
    ebool encryptedChoice;      // Private: what they voted
    euint8 encryptedRating;     // Private: their rating
    uint256 timestamp;          // Public: when they voted
}
```

### Error Handling and Security

```solidity
modifier onlyActiveCompetition(uint256 competitionId) {
    require(competitions[competitionId].isActive, "Competition not active");
    _;
}

modifier hasNotVoted(uint256 competitionId) {
    require(!hasVoted[msg.sender][competitionId], "Already voted");
    _;
}

function submitVote(uint256 competitionId, bool voteChoice, uint8 rating)
    external
    onlyActiveCompetition(competitionId)
    hasNotVoted(competitionId)
{
    require(rating >= 1 && rating <= 5, "Rating must be 1-5");
    // ... voting logic
}
```

---

## 6. Testing and Deployment

### Local Testing Setup

1. **Install Dependencies**
```bash
npm init -y
npm install --save-dev hardhat @fhevm/solidity
npx hardhat init
```

2. **Configure Hardhat for FHEVM**
```javascript
// hardhat.config.js
require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    zama: {
      url: "https://devnet.zama.ai",
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};
```

3. **Deploy Script**
```javascript
// scripts/deploy.js
async function main() {
  const AnonymousVoting = await ethers.getContractFactory("AnonymousVoting");
  const contract = await AnonymousVoting.deploy();
  await contract.deployed();

  console.log("Contract deployed to:", contract.address);

  // Create a test competition
  await contract.createCompetition(
    "Valorant Champions",
    "Vote on the best Valorant tournament"
  );

  console.log("Test competition created!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

### Frontend Testing

Create test scenarios to verify FHE functionality:

```javascript
// Test voting functionality
async function testVoting() {
    try {
        console.log("Testing encrypted voting...");

        // Submit test vote
        const tx = await contract.submitVote(1, true, 5);
        await tx.wait();
        console.log("✅ Encrypted vote submitted successfully");

        // Verify vote was recorded (without revealing content)
        const hasVoted = await contract.hasVoted(userAddress, 1);
        console.log("✅ Vote verification:", hasVoted);

        // Try to vote again (should fail)
        try {
            await contract.submitVote(1, false, 3);
            console.log("❌ Double voting should have failed");
        } catch (error) {
            console.log("✅ Double voting prevented:", error.message);
        }

    } catch (error) {
        console.error("❌ Testing failed:", error);
    }
}
```

### Deployment Checklist

- [ ] Contract compiles without errors
- [ ] All FHE operations use correct data types
- [ ] Access control properly implemented
- [ ] Frontend connects to correct network
- [ ] MetaMask integration working
- [ ] Error handling implemented
- [ ] Test voting scenarios verified

---

## 7. Advanced Features and Best Practices

### Optimizing FHE Performance

#### 1. Minimize Encrypted Operations
```solidity
// Good: Batch operations
euint8 totalVotes = FHE.add(supportVotes, opposeVotes);

// Avoid: Multiple separate operations
euint8 temp1 = FHE.add(vote1, vote2);
euint8 temp2 = FHE.add(temp1, vote3);
```

#### 2. Use Appropriate Data Types
```solidity
euint8  voteCounts;     // For small numbers (0-255)
euint16 largeVoteCounts; // For larger numbers (0-65535)
ebool   simpleChoice;    // For true/false values
```

### Security Best Practices

#### 1. Access Control Patterns
```solidity
// Role-based access control
mapping(address => bool) public organizers;

modifier onlyOrganizer() {
    require(organizers[msg.sender], "Not authorized");
    _;
}

function createCompetition(string memory title)
    external
    onlyOrganizer
{
    // Only authorized users can create competitions
}
```

#### 2. Input Validation
```solidity
function submitVote(uint256 competitionId, bool voteChoice, uint8 rating) external {
    require(competitionId > 0 && competitionId <= competitionCounter, "Invalid ID");
    require(rating >= 1 && rating <= 5, "Invalid rating");
    require(competitions[competitionId].isActive, "Competition inactive");
    // ... rest of function
}
```

### User Experience Enhancements

#### 1. Loading States
```javascript
async function submitVote(competitionId) {
    const button = document.getElementById('submitVote');
    button.disabled = true;
    button.textContent = "Encrypting vote...";

    try {
        const tx = await contract.submitVote(competitionId, voteChoice, rating);
        button.textContent = "Confirming on blockchain...";
        await tx.wait();
        button.textContent = "Vote submitted!";
    } catch (error) {
        button.textContent = "Submit Anonymous Vote";
        button.disabled = false;
        throw error;
    }
}
```

#### 2. Transaction Feedback
```javascript
function showTransactionProgress(txHash) {
    const progressDiv = document.createElement('div');
    progressDiv.innerHTML = `
        <p>✅ Vote encrypted and submitted!</p>
        <p>🔗 Transaction: <a href="https://explorer.zama.ai/tx/${txHash}" target="_blank">View on Explorer</a></p>
        <p>⏳ Waiting for blockchain confirmation...</p>
    `;
    document.body.appendChild(progressDiv);
}
```

### Extending Your dApp

#### 1. Multiple Vote Types
```solidity
enum VoteType { SUPPORT_OPPOSE, RATING_ONLY, RANKED_CHOICE }

struct Competition {
    VoteType voteType;
    // ... other fields
}
```

#### 2. Time-Based Voting
```solidity
struct Competition {
    uint256 startTime;
    uint256 endTime;
    // ... other fields
}

modifier withinVotingPeriod(uint256 competitionId) {
    Competition memory comp = competitions[competitionId];
    require(block.timestamp >= comp.startTime, "Voting not started");
    require(block.timestamp <= comp.endTime, "Voting ended");
    _;
}
```

#### 3. Result Revelation
```solidity
// Only competition organizer can reveal results
function revealResults(uint256 competitionId)
    external
    onlyOrganizer
    returns (uint8 supportVotes, uint8 opposeVotes)
{
    Competition storage comp = competitions[competitionId];
    require(!comp.isActive, "Competition still active");

    // Decrypt results for authorized party
    supportVotes = FHE.decrypt(comp.encryptedSupportVotes);
    opposeVotes = FHE.decrypt(comp.encryptedOpposeVotes);

    emit ResultsRevealed(competitionId, supportVotes, opposeVotes);
}
```

---

## 🎉 Congratulations!

You've successfully built your first confidential dApp using FHEVM! You now understand:

✅ **FHE Fundamentals**: How to work with encrypted data on-chain
✅ **Privacy-Preserving Logic**: Building applications that protect user data
✅ **Real-World Implementation**: Creating practical confidential applications
✅ **Best Practices**: Security, performance, and user experience considerations

## 🚀 Next Steps

### Explore More FHE Features
- **Encrypted Comparisons**: `FHE.gt()`, `FHE.lt()`, `FHE.eq()`
- **Conditional Logic**: `FHE.cmux()` for encrypted if/else
- **Mathematical Operations**: `FHE.mul()`, `FHE.sub()`, `FHE.div()`

### Build More Complex dApps
- **Encrypted Auctions**: Bidding with private bid amounts
- **Confidential Governance**: Private voting on DAO proposals
- **Secret Gaming**: Hidden information games and puzzles
- **Private Analytics**: Data collection without revealing individual data

### Join the Community
- **Zama Discord**: Connect with other FHE developers
- **GitHub**: Contribute to FHEVM development
- **Documentation**: Explore advanced FHEVM features

## 📚 Additional Resources

- **FHEVM Documentation**: [docs.zama.ai](https://docs.zama.ai)
- **Example Projects**: [github.com/zama-ai/fhevm](https://github.com/zama-ai/fhevm)
- **Community Forum**: [community.zama.ai](https://community.zama.ai)
- **Developer Tools**: Hardhat plugins, testing frameworks

---

*This tutorial is designed to be the most beginner-friendly introduction to FHEVM. The future of privacy-preserving applications starts with your first confidential dApp!*

**Happy Building! 🔐✨**