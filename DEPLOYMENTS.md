# MonkaBreak Contract Deployments

## Monad Testnet

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

### Available Functions
```solidity
// Core Functions
function createGame(uint256 gameId) external
function startGame(uint256 gameId) external payable  
function finalizeGame(uint256 gameId, address[] winners) external
function getGame(uint256 gameId) external view returns (address, uint256, uint256, uint256, bool, bool)

// Constants
uint256 public constant MIN_ENTRY_FEE = 1 ether
```

### Usage Instructions
1. **Create Game**: Call `createGame(uniqueId)` to create a new game room
2. **Start Game**: Creator calls `startGame(gameId)` with minimum 1 MON value
3. **Finalize Game**: Creator calls `finalizeGame(gameId, [winnerAddresses])` to distribute vault
4. **Query Game**: Anyone can call `getGame(gameId)` to view game state

### Explorer Links
- **Monad Testnet Explorer**: [View Contract](https://testnet-explorer.monad.xyz/address/0x96932903fCa2C116fFD8DEa7c5b8e87010Cfd8CC)
- **Transaction**: [View Deployment Tx](https://testnet-explorer.monad.xyz/tx/0x52f8e99df40db8eacfa3846ecae6ebe6328ad920401114847bd18837949354d3)

### Notes
- Contract implements minimal on-chain logic as per PRD requirements
- All game mechanics and player management handled off-chain
- Vault funds distributed equally among winners
- Start block number recorded for randomness purposes 