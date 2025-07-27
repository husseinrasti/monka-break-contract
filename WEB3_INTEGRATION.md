# MonkaBreak Web3 Integration Guide

This guide provides everything you need to integrate the MonkaBreak smart contract with your web3 application.

## 📋 Files Overview

### Core Files
- **`MonkaBreak.abi.json`** - Contract ABI for function calls
- **`MonkaBreak.contract.json`** - Complete contract configuration
- **`web3-integration-example.js`** - Full integration example with ethers.js
- **`package.json`** - Required dependencies

### Contract Details
- **Contract Address**: `0x8a78cCB5a19aa9098F7400891d23672E1Ed7B0D1`
- **Network**: Monad Testnet (Chain ID: 10143)
- **RPC URL**: `https://testnet-rpc.monad.xyz`
- **Explorer**: https://testnet.monadexplorer.com/address/0x8a78cCB5a19aa9098F7400891d23672E1Ed7B0D1

## 🚀 Quick Start

### 1. Install Dependencies

```bash
npm install ethers@^6.8.0
```

### 2. Import Contract Files

```javascript
import { ethers } from 'ethers';
import contractConfig from './MonkaBreak.contract.json';
import contractABI from './MonkaBreak.abi.json';
```

### 3. Initialize Contract

```javascript
const provider = new ethers.JsonRpcProvider('https://testnet-rpc.monad.xyz');
const contract = new ethers.Contract(
  contractConfig.contractAddress, 
  contractABI, 
  provider
);
```

### 4. Connect Wallet

```javascript
import { connectWallet } from './web3-integration-example.js';

const { contract: connectedContract, signer } = await connectWallet();
```

## 🎮 Game Functions

### Admin Functions

#### Create Game
```javascript
const game = new MonkaBreakGame(connectedContract, signer);
const { gameId } = await game.createGame(3); // 3 MON entry fee
```

#### Join Game
```javascript
await game.joinGame(gameId, "PlayerName", true); // true = thief, false = police
```

#### Start Game
```javascript
await game.startGame(gameId); // Only creator can start
```

### Gameplay Functions

#### Commit Move (Thieves)
```javascript
await game.commitMove(gameId, 0); // 0=A, 1=B, 2=C
```

#### Vote Block (Police)
```javascript
await game.voteBlock(gameId, 1); // Vote to block path B
```

#### Process Stage
```javascript
await game.processStage(gameId); // Advance to next stage
```

#### Finalize Game
```javascript
await game.finalizeGame(gameId); // Distribute prizes
```

### View Functions

#### Get Game State
```javascript
const state = await game.getGameState(gameId);
console.log(state);
// {
//   creator: "0x...",
//   entryFee: 3000000000000000000n,
//   started: true,
//   finalized: false,
//   currentStage: 1,
//   thievesCount: 3,
//   policeCount: 3,
//   aliveThieves: 2,
//   totalPlayers: 6
// }
```

#### Get Players
```javascript
const players = await game.getPlayers(gameId);
console.log(players);
// [
//   {
//     address: "0x...",
//     nickname: "Alice",
//     isThief: true,
//     eliminated: false,
//     moves: [0, 1, 2, 0] // Path choices for each stage
//   }
// ]
```

## 📡 Event Listening

### Setup Event Listeners
```javascript
game.setupEventListeners();

// Events will be logged to console:
// - GameCreated
// - PlayerJoined  
// - GameStarted
// - MoveCommitted
// - VoteCast
// - StageCompleted
// - GameFinalized
// - PrizeClaimed
```

### Custom Event Handling
```javascript
contract.on('GameCreated', (gameId, creator, entryFee) => {
  console.log(`New game ${gameId} created by ${creator}`);
});

contract.on('PlayerJoined', (gameId, player, nickname, isThief) => {
  const team = isThief ? 'Thieves' : 'Police';
  console.log(`${nickname} joined game ${gameId} as ${team}`);
});
```

## ⚙️ Network Configuration

### Add Monad Testnet to MetaMask
The `connectWallet()` function automatically adds Monad testnet to MetaMask:

```javascript
{
  chainId: "0x279f", // 10143 in hex
  chainName: "Monad Testnet",
  rpcUrls: ["https://testnet-rpc.monad.xyz"],
  nativeCurrency: {
    name: "MON",
    symbol: "MON", 
    decimals: 18
  },
  blockExplorerUrls: ["https://testnet.monadexplorer.com"]
}
```

## 🔧 React Integration

### Using React Hook
```javascript
import { useMonkaBreak } from './web3-integration-example.js';

function GameComponent() {
  const { game, loading, error, initialize } = useMonkaBreak();
  
  useEffect(() => {
    initialize();
  }, []);

  if (loading) return <div>Connecting...</div>;
  if (error) return <div>Error: {error}</div>;
  if (!game) return <div>Not connected</div>;

  return (
    <div>
      <button onClick={() => game.createGame(3)}>
        Create Game (3 MON)
      </button>
    </div>
  );
}
```

### Component Examples
```javascript
// Create Game Component
function CreateGame({ game }) {
  const [entryFee, setEntryFee] = useState(3);
  
  const handleCreate = async () => {
    try {
      const { gameId } = await game.createGame(entryFee);
      console.log(`Game created: ${gameId}`);
    } catch (error) {
      console.error('Failed to create game:', error);
    }
  };

  return (
    <div>
      <input 
        type="number" 
        value={entryFee} 
        onChange={(e) => setEntryFee(e.target.value)}
        min="2"
        step="0.1"
      />
      <button onClick={handleCreate}>Create Game</button>
    </div>
  );
}

// Join Game Component  
function JoinGame({ game, gameId }) {
  const [nickname, setNickname] = useState('');
  const [isThief, setIsThief] = useState(true);

  const handleJoin = async () => {
    try {
      await game.joinGame(gameId, nickname, isThief);
      console.log('Joined game successfully');
    } catch (error) {
      console.error('Failed to join game:', error);
    }
  };

  return (
    <div>
      <input 
        placeholder="Nickname" 
        value={nickname}
        onChange={(e) => setNickname(e.target.value)}
      />
      <select value={isThief} onChange={(e) => setIsThief(e.target.value === 'true')}>
        <option value="true">Thief</option>
        <option value="false">Police</option>
      </select>
      <button onClick={handleJoin}>Join Game</button>
    </div>
  );
}
```

## 🛡️ Error Handling

### Contract Errors
The contract throws custom errors that you can catch:

```javascript
try {
  await game.createGame(1); // Below minimum
} catch (error) {
  if (error.reason?.includes('InsufficientEntryFee')) {
    console.error('Entry fee too low (minimum 2 MON)');
  }
}
```

### Common Errors
- `InsufficientEntryFee()` - Entry fee below 2 MON
- `GameIsFull()` - Maximum 10 players reached
- `PlayerAlreadyJoined()` - Player already in this game
- `InsufficientPlayers()` - Need 3+ thieves and 3+ police to start
- `OnlyCreatorCanStart()` - Only game creator can start
- `OnlyThievesCanCommitMoves()` - Only thieves can commit moves
- `OnlyPoliceCanVote()` - Only police can vote
- `InvalidPath()` - Path choice must be 0, 1, or 2

## 💡 Best Practices

### 1. Always Handle Transactions
```javascript
try {
  const tx = await game.createGame(3);
  console.log('Transaction submitted:', tx.txHash);
  // Show loading state while waiting for confirmation
} catch (error) {
  console.error('Transaction failed:', error);
  // Show error message to user
}
```

### 2. Check Game State Before Actions
```javascript
const gameState = await game.getGameState(gameId);
if (!gameState.started) {
  console.log('Game not started yet');
  return;
}
```

### 3. Listen for Events
```javascript
// Set up event listeners to keep UI in sync
contract.on('PlayerJoined', (gameId, player, nickname, isThief) => {
  // Update player list in UI
  updatePlayerList(gameId);
});
```

### 4. Format Values Properly
```javascript
// Convert wei to MON for display
const entryFeeFormatted = ethers.formatEther(gameState.entryFee);
console.log(`Entry fee: ${entryFeeFormatted} MON`);

// Convert MON to wei for transactions
const entryFeeWei = ethers.parseEther("3.0");
```

## 🔍 Testing

### Local Testing
```bash
# Install dependencies
npm install

# Run the example
node web3-integration-example.js
```

### Integration Testing
```javascript
import { exampleUsage } from './web3-integration-example.js';

// Test full game flow
async function testGameFlow() {
  const { game, gameId } = await exampleUsage();
  
  // Test game creation
  assert(gameId, 'Game should be created');
  
  // Test game state
  const state = await game.getGameState(gameId);
  assert(state.creator, 'Game should have creator');
}
```

## 📚 Additional Resources

- **Contract Source**: https://github.com/your-org/monka-break-contract
- **Monad Docs**: https://docs.monad.xyz/
- **Ethers.js Docs**: https://docs.ethers.org/
- **Contract Explorer**: https://testnet.monadexplorer.com/address/0x8a78cCB5a19aa9098F7400891d23672E1Ed7B0D1

## 🆘 Support

If you encounter issues:

1. Check the [contract explorer](https://testnet.monadexplorer.com/address/0x8a78cCB5a19aa9098F7400891d23672E1Ed7B0D1) for transaction status
2. Verify you're on Monad testnet (Chain ID: 10143)
3. Ensure you have sufficient MON for gas fees
4. Check console for error messages

## 📄 License

MIT License - see LICENSE file for details 