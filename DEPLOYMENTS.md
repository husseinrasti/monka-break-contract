# MonkaBreak Contract Deployments

## Monad Testnet

**Deployment Date**: July 28, 2024  
**Contract Address**: `0x7DdD1840B0130e7D0357f130Db52Ad1c6A833dbd`  
**Chain ID**: 10143  
**Block Number**: 28221815  
**Transaction Hash**: `0x0fa2c4c2a4907670c3a32291c0e252de414b46f594c86ee86cf124d217955114`  
**Deployer**: `0xe4efD359b6580BdF13393EeEf57322DA35881CE3`  

### Contract Details
- **Compiler Version**: Solidity 0.8.28
- **Optimization**: Enabled
- **Minimum Entry Fee**: 2 MON (2 ether)
- **Cooldown Period**: 256 blocks (≈ 4-5 minutes)
- **Gas Used**: 1,276,590
- **Deployment Cost**: 0.06382950000127659 ETH

### Available Functions
```solidity
// Core Functions
function createGame(uint256 gameId) external
function startGame(uint256 gameId) external payable  
function finalizeGame(uint256 gameId, address[] winners) external
function getGame(uint256 gameId) external view returns (address, uint256, uint256, uint256, bool, bool)

// Constants
uint256 public constant MIN_ENTRY_FEE = 2 ether
uint256 public constant COOLDOWN_BLOCKS = 256
```

### Events
```solidity
event GameCreated(uint256 indexed gameId, address indexed creator)
event GameStarted(uint256 indexed gameId, uint256 vault, uint256 blockNumber)
event GameFinalized(uint256 indexed gameId, address[] winners)
event GameRefunded(uint256 indexed gameId)  // NEW: for refund scenarios
```

### Usage Instructions
1. **Create Game**: Call `createGame(uniqueId)` to create a new game room
2. **Start Game**: Creator calls `startGame(gameId)` with minimum 2 MON value
3. **Finalize Game**: 
   - **With Winners**: Creator calls `finalizeGame(gameId, [winnerAddresses])` to distribute vault equally
   - **No Winners**: Creator calls `finalizeGame(gameId, [])` after 256 blocks to refund vault
4. **Query Game**: Anyone can call `getGame(gameId)` to view game state

### Key Features
- **Minimal On-Chain Logic**: Only handles funding, starting, and reward distribution
- **Cooldown Protection**: Prevents premature refunds (256 blocks ≈ 4-5 minutes)
- **Equal Distribution**: Vault split equally among winners
- **Refund Mechanism**: Full vault refund to creator if no winners after cooldown
- **Access Control**: Only creators can start/finalize their games

### Explorer Links
- **Monad Testnet Explorer**: [View Contract](https://testnet-explorer.monad.xyz/address/0x7DdD1840B0130e7D0357f130Db52Ad1c6A833dbd)
- **Transaction**: [View Deployment Tx](https://testnet-explorer.monad.xyz/tx/0x0fa2c4c2a4907670c3a32291c0e252de414b46f594c86ee86cf124d217955114)

### Notes
- Contract implements minimal on-chain logic as per updated PRD requirements
- All game mechanics and player management handled off-chain
- Updated minimum entry fee from 1 MON to 2 MON
- Added cooldown functionality for refund scenarios
- Start block number recorded for randomness purposes
- Contract successfully verified on Sourcify using custom Monad verifier

---

## Previous Deployment (Deprecated)

**Deployment Date**: December 2024  
**Contract Address**: `0x96932903fCa2C116fFD8DEa7c5b8e87010Cfd8CC`  
**Chain ID**: 10143  
**Block Number**: 28137526  
**Transaction Hash**: `0x52f8e99df40db8eacfa3846ecae6ebe6328ad920401114847bd18837949354d3`  
**Deployer**: `0xe4efD359b6580BdF13393EeEf57322DA35881CE3`  

### Contract Details
- **Compiler Version**: Solidity 0.8.28
- **Optimization**: Enabled
- **Minimum Entry Fee**: 1 MON (1 ether)
- **Gas Used**: 1,152,307
- **Deployment Cost**: 0.059919964 ETH

### Notes
- This deployment used the original contract with 1 MON minimum entry fee
- No cooldown functionality for refunds
- Superseded by the new deployment with updated features 