/**
 * MonkaBreak Smart Contract Integration Example
 * 
 * Contract Address: 0x96932903fCa2C116fFD8DEa7c5b8e87010Cfd8CC
 * Network: Monad Testnet (Chain ID: 10143)
 * Verified: Yes (Sourcify)
 */

// Import required libraries
const Web3 = require('web3');
// const { ethers } = require('ethers'); // Alternative with ethers.js

// Contract configuration
const MONAD_TESTNET_RPC = 'https://testnet-rpc.monad.xyz';
const CONTRACT_ADDRESS = '0x96932903fCa2C116fFD8DEa7c5b8e87010Cfd8CC';
const CHAIN_ID = 10143;

// Contract ABI (minimal - only essential functions)
const CONTRACT_ABI = [
  {
    "type": "function",
    "name": "MIN_ENTRY_FEE",
    "inputs": [],
    "outputs": [{"name": "", "type": "uint256", "internalType": "uint256"}],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "createGame",
    "inputs": [{"name": "gameId", "type": "uint256", "internalType": "uint256"}],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "startGame",
    "inputs": [{"name": "gameId", "type": "uint256", "internalType": "uint256"}],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "finalizeGame",
    "inputs": [
      {"name": "gameId", "type": "uint256", "internalType": "uint256"},
      {"name": "winners", "type": "address[]", "internalType": "address[]"}
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getGame",
    "inputs": [{"name": "gameId", "type": "uint256", "internalType": "uint256"}],
    "outputs": [
      {"name": "creator", "type": "address", "internalType": "address"},
      {"name": "vault", "type": "uint256", "internalType": "uint256"},
      {"name": "entryFee", "type": "uint256", "internalType": "uint256"},
      {"name": "startBlock", "type": "uint256", "internalType": "uint256"},
      {"name": "started", "type": "bool", "internalType": "bool"},
      {"name": "finalized", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "GameCreated",
    "inputs": [
      {"name": "gameId", "type": "uint256", "indexed": true, "internalType": "uint256"},
      {"name": "creator", "type": "address", "indexed": true, "internalType": "address"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "GameStarted",
    "inputs": [
      {"name": "gameId", "type": "uint256", "indexed": true, "internalType": "uint256"},
      {"name": "vault", "type": "uint256", "indexed": false, "internalType": "uint256"},
      {"name": "blockNumber", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "GameFinalized",
    "inputs": [
      {"name": "gameId", "type": "uint256", "indexed": true, "internalType": "uint256"},
      {"name": "winners", "type": "address[]", "indexed": false, "internalType": "address[]"}
    ],
    "anonymous": false
  }
];

class MonkaBreakContract {
  constructor(privateKey) {
    // Initialize Web3 with Monad testnet
    this.web3 = new Web3(MONAD_TESTNET_RPC);
    
    // Setup account from private key
    this.account = this.web3.eth.accounts.privateKeyToAccount(privateKey);
    this.web3.eth.accounts.wallet.add(this.account);
    
    // Initialize contract instance
    this.contract = new this.web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
    
    console.log('MonkaBreak Contract initialized');
    console.log('Account:', this.account.address);
    console.log('Contract:', CONTRACT_ADDRESS);
  }

  // Get minimum entry fee
  async getMinEntryFee() {
    try {
      const minFee = await this.contract.methods.MIN_ENTRY_FEE().call();
      return {
        wei: minFee,
        ether: this.web3.utils.fromWei(minFee, 'ether'),
        mon: this.web3.utils.fromWei(minFee, 'ether') + ' MON'
      };
    } catch (error) {
      console.error('Error getting min entry fee:', error);
      throw error;
    }
  }

  // Create a new game
  async createGame(gameId) {
    try {
      console.log(`Creating game with ID: ${gameId}`);
      
      const txData = this.contract.methods.createGame(gameId);
      const gas = await txData.estimateGas({ from: this.account.address });
      
      const tx = await txData.send({
        from: this.account.address,
        gas: Math.floor(gas * 1.2), // Add 20% buffer
        gasPrice: await this.web3.eth.getGasPrice()
      });
      
      console.log('Game created successfully!');
      console.log('Transaction hash:', tx.transactionHash);
      return tx;
    } catch (error) {
      console.error('Error creating game:', error);
      throw error;
    }
  }

  // Start a game with entry fee
  async startGame(gameId, entryFeeEther = '1') {
    try {
      console.log(`Starting game ${gameId} with ${entryFeeEther} MON entry fee`);
      
      const entryFeeWei = this.web3.utils.toWei(entryFeeEther, 'ether');
      const txData = this.contract.methods.startGame(gameId);
      const gas = await txData.estimateGas({ 
        from: this.account.address, 
        value: entryFeeWei 
      });
      
      const tx = await txData.send({
        from: this.account.address,
        value: entryFeeWei,
        gas: Math.floor(gas * 1.2),
        gasPrice: await this.web3.eth.getGasPrice()
      });
      
      console.log('Game started successfully!');
      console.log('Transaction hash:', tx.transactionHash);
      return tx;
    } catch (error) {
      console.error('Error starting game:', error);
      throw error;
    }
  }

  // Finalize game with winners
  async finalizeGame(gameId, winnerAddresses) {
    try {
      console.log(`Finalizing game ${gameId} with ${winnerAddresses.length} winners`);
      
      const txData = this.contract.methods.finalizeGame(gameId, winnerAddresses);
      const gas = await txData.estimateGas({ from: this.account.address });
      
      const tx = await txData.send({
        from: this.account.address,
        gas: Math.floor(gas * 1.2),
        gasPrice: await this.web3.eth.getGasPrice()
      });
      
      console.log('Game finalized successfully!');
      console.log('Transaction hash:', tx.transactionHash);
      return tx;
    } catch (error) {
      console.error('Error finalizing game:', error);
      throw error;
    }
  }

  // Get game information
  async getGame(gameId) {
    try {
      const gameData = await this.contract.methods.getGame(gameId).call();
      
      return {
        creator: gameData.creator,
        vault: {
          wei: gameData.vault,
          ether: this.web3.utils.fromWei(gameData.vault, 'ether'),
          mon: this.web3.utils.fromWei(gameData.vault, 'ether') + ' MON'
        },
        entryFee: {
          wei: gameData.entryFee,
          ether: this.web3.utils.fromWei(gameData.entryFee, 'ether'),
          mon: this.web3.utils.fromWei(gameData.entryFee, 'ether') + ' MON'
        },
        startBlock: gameData.startBlock,
        started: gameData.started,
        finalized: gameData.finalized
      };
    } catch (error) {
      console.error('Error getting game data:', error);
      throw error;
    }
  }

  // Listen to contract events
  setupEventListeners() {
    // Game Created Event
    this.contract.events.GameCreated()
      .on('data', (event) => {
        console.log('Game Created:', {
          gameId: event.returnValues.gameId,
          creator: event.returnValues.creator,
          blockNumber: event.blockNumber,
          transactionHash: event.transactionHash
        });
      })
      .on('error', console.error);

    // Game Started Event
    this.contract.events.GameStarted()
      .on('data', (event) => {
        console.log('Game Started:', {
          gameId: event.returnValues.gameId,
          vault: this.web3.utils.fromWei(event.returnValues.vault, 'ether') + ' MON',
          blockNumber: event.returnValues.blockNumber,
          transactionHash: event.transactionHash
        });
      })
      .on('error', console.error);

    // Game Finalized Event
    this.contract.events.GameFinalized()
      .on('data', (event) => {
        console.log('Game Finalized:', {
          gameId: event.returnValues.gameId,
          winners: event.returnValues.winners,
          blockNumber: event.blockNumber,
          transactionHash: event.transactionHash
        });
      })
      .on('error', console.error);
  }

  // Check account balance
  async getBalance() {
    const balanceWei = await this.web3.eth.getBalance(this.account.address);
    return {
      wei: balanceWei,
      ether: this.web3.utils.fromWei(balanceWei, 'ether'),
      mon: this.web3.utils.fromWei(balanceWei, 'ether') + ' MON'
    };
  }
}

// Example usage
async function exampleUsage() {
  // Initialize with your private key (use environment variable in production)
  const PRIVATE_KEY = process.env.PRIVATE_KEY || '0x0000000000000000000000000000000000000000000000000000000000000001';
  
  try {
    const monkaBreak = new MonkaBreakContract(PRIVATE_KEY);
    
    // Setup event listeners
    monkaBreak.setupEventListeners();
    
    // Check balance
    const balance = await monkaBreak.getBalance();
    console.log('Account balance:', balance.mon);
    
    // Get minimum entry fee
    const minFee = await monkaBreak.getMinEntryFee();
    console.log('Minimum entry fee:', minFee.mon);
    
    // Example game flow
    const gameId = Date.now(); // Use timestamp as game ID
    
    // 1. Create game
    await monkaBreak.createGame(gameId);
    
    // 2. Start game with entry fee
    await monkaBreak.startGame(gameId, '2'); // 2 MON entry fee
    
    // 3. Get game info
    const gameInfo = await monkaBreak.getGame(gameId);
    console.log('Game info:', gameInfo);
    
    // 4. Finalize game (example with winner addresses)
    const winners = ['0x742d35Cc8Cc5C84b14c3c3Cc2A3BC3d2BC10D48C']; // Example winner
    await monkaBreak.finalizeGame(gameId, winners);
    
    console.log('Example completed successfully!');
    
  } catch (error) {
    console.error('Example failed:', error);
  }
}

// Export for use in other modules
module.exports = {
  MonkaBreakContract,
  CONTRACT_ADDRESS,
  CONTRACT_ABI,
  MONAD_TESTNET_RPC,
  CHAIN_ID
};

// Run example if this file is executed directly
if (require.main === module) {
  exampleUsage();
} 