/**
 * MonkaBreak Contract Web3 Integration Example
 * 
 * This example shows how to integrate the MonkaBreak smart contract
 * with web3 applications using ethers.js or web3.js
 */

import { ethers } from 'ethers';
import contractConfig from './MonkaBreak.contract.json';
import contractABI from './MonkaBreak.abi.json';

// Contract configuration
const CONTRACT_ADDRESS = contractConfig.contractAddress;
const CONTRACT_ABI = contractABI;
const RPC_URL = contractConfig.rpcUrl;
const CHAIN_ID = contractConfig.chainId;

// Initialize provider and contract
const provider = new ethers.JsonRpcProvider(RPC_URL);
const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, provider);

/**
 * Connect wallet and get signer
 */
async function connectWallet() {
    if (typeof window.ethereum !== 'undefined') {
        try {
            // Request account access
            await window.ethereum.request({ method: 'eth_requestAccounts' });
            
            // Switch to Monad testnet if needed
            try {
                await window.ethereum.request({
                    method: 'wallet_switchEthereumChain',
                    params: [{ chainId: `0x${CHAIN_ID.toString(16)}` }],
                });
            } catch (switchError) {
                // Chain not added, add it
                if (switchError.code === 4902) {
                    await window.ethereum.request({
                        method: 'wallet_addEthereumChain',
                        params: [{
                            chainId: `0x${CHAIN_ID.toString(16)}`,
                            chainName: 'Monad Testnet',
                            rpcUrls: [RPC_URL],
                            nativeCurrency: {
                                name: 'MON',
                                symbol: 'MON',
                                decimals: 18
                            },
                            blockExplorerUrls: [contractConfig.explorerUrl]
                        }]
                    });
                }
            }

            const web3Provider = new ethers.BrowserProvider(window.ethereum);
            const signer = await web3Provider.getSigner();
            return { provider: web3Provider, signer, contract: contract.connect(signer) };
        } catch (error) {
            console.error('Failed to connect wallet:', error);
            throw error;
        }
    } else {
        throw new Error('MetaMask not installed');
    }
}

/**
 * Contract interaction functions
 */
class MonkaBreakGame {
    constructor(contract, signer) {
        this.contract = contract;
        this.signer = signer;
    }

    // Admin Functions
    async createGame(entryFeeEth) {
        const entryFeeWei = ethers.parseEther(entryFeeEth.toString());
        
        if (entryFeeWei < BigInt(contractConfig.constants.MIN_ENTRY_FEE)) {
            throw new Error(`Minimum entry fee is ${contractConfig.gameRules.minEntryFeeETH} MON`);
        }

        const tx = await this.contract.createGame(entryFeeWei);
        const receipt = await tx.wait();
        
        // Extract game ID from event
        const event = receipt.logs.find(log => 
            log.fragment && log.fragment.name === 'GameCreated'
        );
        const gameId = event ? event.args[0] : null;
        
        return { 
            txHash: receipt.hash, 
            gameId: gameId ? gameId.toString() : null,
            blockNumber: receipt.blockNumber 
        };
    }

    async joinGame(gameId, nickname = "", isThief = true) {
        const gameState = await this.getGameState(gameId);
        const entryFee = gameState.entryFee;
        
        const tx = await this.contract.joinGame(gameId, nickname, isThief, {
            value: entryFee
        });
        
        return await tx.wait();
    }

    async startGame(gameId) {
        const tx = await this.contract.startGame(gameId);
        return await tx.wait();
    }

    // Gameplay Functions
    async commitMove(gameId, pathChoice) {
        if (pathChoice < 0 || pathChoice > 2) {
            throw new Error('Invalid path choice. Must be 0 (A), 1 (B), or 2 (C)');
        }
        
        const tx = await this.contract.commitMove(gameId, pathChoice);
        return await tx.wait();
    }

    async voteBlock(gameId, pathChoice) {
        if (pathChoice < 0 || pathChoice > 2) {
            throw new Error('Invalid path choice. Must be 0 (A), 1 (B), or 2 (C)');
        }
        
        const tx = await this.contract.voteBlock(gameId, pathChoice);
        return await tx.wait();
    }

    async processStage(gameId) {
        const tx = await this.contract.processStage(gameId);
        return await tx.wait();
    }

    async finalizeGame(gameId) {
        const tx = await this.contract.finalizeGame(gameId);
        return await tx.wait();
    }

    // View Functions
    async getGameState(gameId) {
        const result = await this.contract.getGameState(gameId);
        return {
            creator: result[0],
            entryFee: result[1],
            started: result[2],
            finalized: result[3],
            currentStage: Number(result[4]),
            thievesCount: Number(result[5]),
            policeCount: Number(result[6]),
            aliveThieves: Number(result[7]),
            totalPlayers: Number(result[8])
        };
    }

    async getPlayers(gameId) {
        const players = await this.contract.getPlayers(gameId);
        return players.map(player => ({
            address: player.addr,
            nickname: player.nickname,
            isThief: player.isThief,
            eliminated: player.eliminated,
            moves: player.moves.map(move => Number(move))
        }));
    }

    async getVaultBalance(gameId) {
        const balance = await this.contract.getVaultBalance(gameId);
        return ethers.formatEther(balance);
    }

    async isWinner(gameId, playerAddress) {
        return await this.contract.isWinner(gameId, playerAddress);
    }

    async getCurrentGameId() {
        const gameId = await this.contract.getCurrentGameId();
        return Number(gameId);
    }

    // Event Listeners
    setupEventListeners() {
        // Listen for game events
        this.contract.on('GameCreated', (gameId, creator, entryFee) => {
            console.log('Game Created:', {
                gameId: gameId.toString(),
                creator,
                entryFee: ethers.formatEther(entryFee)
            });
        });

        this.contract.on('PlayerJoined', (gameId, player, nickname, isThief) => {
            console.log('Player Joined:', {
                gameId: gameId.toString(),
                player,
                nickname,
                team: isThief ? 'Thieves' : 'Police'
            });
        });

        this.contract.on('GameStarted', (gameId, startBlock) => {
            console.log('Game Started:', {
                gameId: gameId.toString(),
                startBlock: startBlock.toString()
            });
        });

        this.contract.on('MoveCommitted', (gameId, player, stage) => {
            console.log('Move Committed:', {
                gameId: gameId.toString(),
                player,
                stage: stage.toString()
            });
        });

        this.contract.on('VoteCast', (gameId, voter, stage, blockedPath) => {
            console.log('Vote Cast:', {
                gameId: gameId.toString(),
                voter,
                stage: stage.toString(),
                blockedPath: ['A', 'B', 'C'][blockedPath]
            });
        });

        this.contract.on('StageCompleted', (gameId, stage, blockedPath, eliminatedPlayers) => {
            console.log('Stage Completed:', {
                gameId: gameId.toString(),
                stage: stage.toString(),
                blockedPath: ['A', 'B', 'C'][blockedPath],
                eliminatedCount: eliminatedPlayers.length
            });
        });

        this.contract.on('GameFinalized', (gameId, winners, prizePerWinner) => {
            console.log('Game Finalized:', {
                gameId: gameId.toString(),
                winnerCount: winners.length,
                prizePerWinner: ethers.formatEther(prizePerWinner)
            });
        });
    }

    // Utility functions
    pathToString(pathIndex) {
        return ['A', 'B', 'C'][pathIndex] || 'Unknown';
    }

    formatMON(weiAmount) {
        return ethers.formatEther(weiAmount);
    }

    parseMON(ethAmount) {
        return ethers.parseEther(ethAmount.toString());
    }
}

/**
 * Usage Examples
 */
export async function exampleUsage() {
    try {
        // Connect wallet
        const { contract: connectedContract, signer } = await connectWallet();
        const game = new MonkaBreakGame(connectedContract, signer);
        
        // Setup event listeners
        game.setupEventListeners();

        // Create a new game
        console.log('Creating new game...');
        const { gameId } = await game.createGame(3); // 3 MON entry fee
        console.log(`Game created with ID: ${gameId}`);

        // Join game as thief
        console.log('Joining game as thief...');
        await game.joinGame(gameId, "Alice", true);

        // Check game state
        const gameState = await game.getGameState(gameId);
        console.log('Game State:', gameState);

        // Get players
        const players = await game.getPlayers(gameId);
        console.log('Players:', players);

        return { game, gameId };
    } catch (error) {
        console.error('Error in example usage:', error);
        throw error;
    }
}

// Export for use in other modules
export {
    MonkaBreakGame,
    connectWallet,
    CONTRACT_ADDRESS,
    CONTRACT_ABI,
    contractConfig
};

/**
 * React Hook Example (if using React)
 */
export function useMonkaBreak() {
    const [game, setGame] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const initialize = async () => {
        try {
            setLoading(true);
            setError(null);
            const { contract, signer } = await connectWallet();
            const gameInstance = new MonkaBreakGame(contract, signer);
            gameInstance.setupEventListeners();
            setGame(gameInstance);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    return { game, loading, error, initialize };
} 