# MonkaBreak Smart Contract

A real-time, team-based strategy game on blockchain where Thieves attempt to break into a vault while Police try to stop them.

## Game Overview

MonkaBreak is implemented as a smart contract on the Monad Testnet. Players join game rooms as either Thieves or Police and compete in a 4-stage gameplay mechanic:

- **Thieves**: Choose paths (A, B, C) to reach the vault
- **Police**: Vote to block one path per stage
- **Elimination**: Thieves who choose the blocked path are eliminated
- **Victory**: 
  - Police win if all thieves are eliminated
  - Thieves win if they survive all 4 stages and choose the randomly selected winning path

## Contract Features

### Core Mechanics
- Game rooms with customizable entry fees (minimum 2 MON)
- Team balance enforcement (3-10 players, minimum 3 thieves and 3 police)
- 4-stage elimination gameplay
- Random winning path selection using blockhash
- Automatic prize distribution to winners

### Security Features
- Custom error handling for gas efficiency
- Comprehensive input validation
- Protection against common vulnerabilities
- Event emission for all key state transitions

## Contract Functions

### Admin Functions
- `createGame(uint256 entryFee)` - Create a new game room
- `joinGame(uint256 gameId, string memory nickname, bool isThief)` - Join a game room
- `startGame(uint256 gameId)` - Start the game (creator only)

### Gameplay Functions
- `commitMove(uint256 gameId, uint8 pathChoice)` - Thieves commit path choice
- `voteBlock(uint256 gameId, uint8 pathChoice)` - Police vote to block path
- `processStage(uint256 gameId)` - Process stage eliminations and advance game
- `finalizeGame(uint256 gameId)` - Finalize game and distribute prizes

### View Functions
- `getPlayers(uint256 gameId)` - Get all players in a game
- `getGameState(uint256 gameId)` - Get current game state
- `getVaultBalance(uint256 gameId)` - Get vault balance
- `getPoliceVote(uint256 gameId, uint256 stage)` - Get police vote for stage
- `isWinner(uint256 gameId, address player)` - Check if player is winner

## Development Setup

This project uses Foundry for development and testing.

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Installation
```shell
git clone <repository-url>
cd monka-break-contract
forge install
```

### Build
```shell
forge build
```

### Test
Run all tests:
```shell
forge test
```

Run tests with verbose output:
```shell
forge test -vvv
```

Run specific test:
```shell
forge test --match-test test_CreateGame
```

### Coverage
```shell
forge coverage
```

### Gas Snapshots
```shell
forge snapshot
```

## Testing

The contract includes comprehensive unit tests covering:

- **Game Creation**: Entry fee validation, multiple game creation
- **Player Management**: Joining games, team balance enforcement, nickname handling
- **Game Lifecycle**: Starting games, player requirements validation
- **Gameplay Mechanics**: Move commits, voting, stage processing, eliminations
- **Game Finalization**: Winner determination, prize distribution
- **View Functions**: State retrieval and validation
- **Edge Cases**: Invalid inputs, unauthorized actions, game state violations
- **Integration Tests**: Full game flows for both Police and Thieves victory scenarios
- **Fuzz Testing**: Property-based testing with random inputs

Total test coverage: **32 test cases** with **100% pass rate**

## Deployment

### Local Development
```shell
# Start local node
anvil

# Deploy to local network
forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --private-key <private_key> --broadcast
```

### Testnet Deployment
```shell
# Deploy to Monad testnet
forge script script/Deploy.s.sol:DeployScript --rpc-url <monad_testnet_rpc> --private-key <private_key> --broadcast --verify
```

## Game Flow Example

1. **Game Creation**: Owner creates game with 3 MON entry fee
2. **Player Joining**: 6 players join (3 thieves, 3 police), each paying 3 MON
3. **Game Start**: Owner starts the game, total vault = 18 MON
4. **Stage 1-3**: 
   - Thieves commit moves (path A, B, or C)
   - Police vote to block one path
   - Eliminated thieves removed from game
5. **Stage 4**: Same as stages 1-3, plus random winning path selection
6. **Game End**: Winners determined and prizes distributed

## Architecture

### Data Structures
```solidity
struct Player {
    address addr;
    string nickname;
    bool isThief;
    bool eliminated;
    uint8[4] moves;
    bool hasCommittedMove;
}

struct GameRoom {
    uint256 id;
    address creator;
    uint256 entryFee;
    uint256 startBlock;
    bool started;
    bool finalized;
    uint256 currentStage;
    uint256 vault;
    Player[] players;
    // ... additional mappings for game state
}
```

### Events
All key state transitions emit events for off-chain tracking:
- `GameCreated`, `PlayerJoined`, `GameStarted`
- `MoveCommitted`, `VoteCast`, `StageCompleted`
- `GameFinalized`, `PrizeClaimed`

## Security Considerations

- **Reentrancy Protection**: Safe external calls using call pattern
- **Integer Overflow**: Solidity 0.8+ built-in protection
- **Access Control**: Function modifiers for role-based permissions
- **Input Validation**: Comprehensive validation for all user inputs
- **State Management**: Proper game state transitions and validations

## License

MIT License - see LICENSE file for details
