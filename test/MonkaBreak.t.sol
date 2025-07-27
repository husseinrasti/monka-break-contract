// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MonkaBreak} from "../src/MonkaBreak.sol";

contract MonkaBreakTest is Test {
    MonkaBreak public monkaBreak;
    
    address public owner = makeAddr("owner");
    address public player1 = makeAddr("player1");
    address public player2 = makeAddr("player2");
    address public player3 = makeAddr("player3");
    address public player4 = makeAddr("player4");
    address public player5 = makeAddr("player5");
    address public player6 = makeAddr("player6");
    address public player7 = makeAddr("player7");
    
    uint256 public constant MIN_ENTRY_FEE = 2 ether;
    uint256 public constant GAME_ENTRY_FEE = 3 ether;
    
    event GameCreated(uint256 indexed gameId, address indexed creator, uint256 entryFee);
    event PlayerJoined(uint256 indexed gameId, address indexed player, string nickname, bool isThief);
    event GameStarted(uint256 indexed gameId, uint256 startBlock);
    event MoveCommitted(uint256 indexed gameId, address indexed player, uint256 stage);
    event VoteCast(uint256 indexed gameId, address indexed voter, uint256 stage, uint8 blockedPath);
    event StageCompleted(uint256 indexed gameId, uint256 stage, uint8 blockedPath, address[] eliminatedPlayers);
    event GameFinalized(uint256 indexed gameId, address[] winners, uint256 prizePerWinner);
    event PrizeClaimed(uint256 indexed gameId, address indexed winner, uint256 amount);

    function setUp() public {
        monkaBreak = new MonkaBreak();
        
        // Give all test addresses some ETH
        vm.deal(owner, 100 ether);
        vm.deal(player1, 100 ether);
        vm.deal(player2, 100 ether);
        vm.deal(player3, 100 ether);
        vm.deal(player4, 100 ether);
        vm.deal(player5, 100 ether);
        vm.deal(player6, 100 ether);
        vm.deal(player7, 100 ether);
    }

    // ===== Game Creation Tests =====

    function test_CreateGame() public {
        vm.startPrank(owner);
        
        vm.expectEmit(true, true, false, true);
        emit GameCreated(1, owner, GAME_ENTRY_FEE);
        
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        assertEq(gameId, 1);
        assertEq(monkaBreak.getCurrentGameId(), 1);
        
        (address creator, uint256 entryFee, bool started, bool finalized, , , , , ) = monkaBreak.getGameState(gameId);
        assertEq(creator, owner);
        assertEq(entryFee, GAME_ENTRY_FEE);
        assertFalse(started);
        assertFalse(finalized);
        
        vm.stopPrank();
    }

    function test_CreateGameRevertInsufficientEntryFee() public {
        vm.startPrank(owner);
        
        vm.expectRevert(MonkaBreak.InsufficientEntryFee.selector);
        monkaBreak.createGame(1 ether); // Less than MIN_ENTRY_FEE
        
        vm.stopPrank();
    }

    function test_CreateMultipleGames() public {
        vm.startPrank(owner);
        
        uint256 gameId1 = monkaBreak.createGame(GAME_ENTRY_FEE);
        uint256 gameId2 = monkaBreak.createGame(GAME_ENTRY_FEE + 1 ether);
        
        assertEq(gameId1, 1);
        assertEq(gameId2, 2);
        assertEq(monkaBreak.getCurrentGameId(), 2);
        
        vm.stopPrank();
    }

    // ===== Player Joining Tests =====

    function test_JoinGameAsThief() public {
        vm.prank(owner);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        vm.startPrank(player1);
        vm.expectEmit(true, true, false, true);
        emit PlayerJoined(gameId, player1, "TestThief", true);
        
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "TestThief", true);
        
        MonkaBreak.Player[] memory players = monkaBreak.getPlayers(gameId);
        assertEq(players.length, 1);
        assertEq(players[0].addr, player1);
        assertEq(players[0].nickname, "TestThief");
        assertTrue(players[0].isThief);
        assertFalse(players[0].eliminated);
        
        assertEq(monkaBreak.getVaultBalance(gameId), GAME_ENTRY_FEE);
        vm.stopPrank();
    }

    function test_JoinGameAsPolice() public {
        vm.prank(owner);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        vm.startPrank(player1);
        vm.expectEmit(true, true, false, true);
        emit PlayerJoined(gameId, player1, "TestPolice", false);
        
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "TestPolice", false);
        
        MonkaBreak.Player[] memory players = monkaBreak.getPlayers(gameId);
        assertEq(players.length, 1);
        assertEq(players[0].addr, player1);
        assertEq(players[0].nickname, "TestPolice");
        assertFalse(players[0].isThief);
        
        vm.stopPrank();
    }

    function test_JoinGameWithDefaultNicknames() public {
        vm.prank(owner);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        // Join as thief with empty nickname - should get "John"
        vm.prank(player1);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "", true);
        
        // Join as police with empty nickname - should get "Keone"
        vm.prank(player2);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "", false);
        
        MonkaBreak.Player[] memory players = monkaBreak.getPlayers(gameId);
        assertEq(players[0].nickname, "John");
        assertEq(players[1].nickname, "Keone");
    }

    function test_JoinGameRevertInsufficientEntryFee() public {
        vm.prank(owner);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        vm.startPrank(player1);
        vm.expectRevert(MonkaBreak.InsufficientEntryFee.selector);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE - 1}(gameId, "Test", true);
        vm.stopPrank();
    }

    function test_JoinGameRevertPlayerAlreadyJoined() public {
        vm.prank(owner);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        vm.startPrank(player1);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Test", true);
        
        vm.expectRevert(MonkaBreak.PlayerAlreadyJoined.selector);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Test2", false);
        vm.stopPrank();
    }

    function test_JoinGameRevertGameNotFound() public {
        vm.startPrank(player1);
        vm.expectRevert(MonkaBreak.GameNotFound.selector);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(999, "Test", true);
        vm.stopPrank();
    }

    // ===== Game Start Tests =====

    function test_StartGame() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, true);
        emit GameStarted(gameId, block.number);
        
        monkaBreak.startGame(gameId);
        
        (, , bool started, , uint256 currentStage, , , , ) = monkaBreak.getGameState(gameId);
        assertTrue(started);
        assertEq(currentStage, 0);
        vm.stopPrank();
    }

    function test_StartGameRevertInsufficientPlayers() public {
        vm.prank(owner);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        // Join only 2 thieves and 2 police (insufficient)
        vm.prank(player1);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Thief1", true);
        vm.prank(player2);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Thief2", true);
        vm.prank(player3);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Police1", false);
        vm.prank(player4);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Police2", false);
        
        vm.startPrank(owner);
        vm.expectRevert(MonkaBreak.InsufficientPlayers.selector);
        monkaBreak.startGame(gameId);
        vm.stopPrank();
    }

    function test_StartGameRevertOnlyCreatorCanStart() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        
        vm.startPrank(player1);
        vm.expectRevert(MonkaBreak.OnlyCreatorCanStart.selector);
        monkaBreak.startGame(gameId);
        vm.stopPrank();
    }

    function test_StartGameRevertGameAlreadyStarted() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        
        vm.startPrank(owner);
        monkaBreak.startGame(gameId);
        
        vm.expectRevert(MonkaBreak.GameAlreadyStarted.selector);
        monkaBreak.startGame(gameId);
        vm.stopPrank();
    }

    // ===== Gameplay Tests =====

    function test_CommitMove() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        vm.startPrank(player1); // This is a thief
        vm.expectEmit(true, true, false, true);
        emit MoveCommitted(gameId, player1, 0);
        
        monkaBreak.commitMove(gameId, 1); // Choose path B
        vm.stopPrank();
        
        MonkaBreak.Player[] memory players = monkaBreak.getPlayers(gameId);
        // Find player1
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].addr == player1) {
                assertEq(players[i].moves[0], 1);
                break;
            }
        }
    }

    function test_CommitMoveRevertOnlyThievesCanCommitMoves() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        vm.startPrank(player4); // This is police
        vm.expectRevert(MonkaBreak.OnlyThievesCanCommitMoves.selector);
        monkaBreak.commitMove(gameId, 1);
        vm.stopPrank();
    }

    function test_CommitMoveRevertMoveAlreadyCommitted() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        vm.startPrank(player1); // This is a thief
        monkaBreak.commitMove(gameId, 1);
        
        vm.expectRevert(MonkaBreak.MoveAlreadyCommitted.selector);
        monkaBreak.commitMove(gameId, 2);
        vm.stopPrank();
    }

    function test_VoteBlock() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        vm.startPrank(player4); // This is police
        vm.expectEmit(true, true, false, true);
        emit VoteCast(gameId, player4, 0, 2);
        
        monkaBreak.voteBlock(gameId, 2); // Vote to block path C
        vm.stopPrank();
        
        assertEq(monkaBreak.getPoliceVote(gameId, 0), 2);
    }

    function test_VoteBlockRevertOnlyPoliceCanVote() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        vm.startPrank(player1); // This is a thief
        vm.expectRevert(MonkaBreak.OnlyPoliceCanVote.selector);
        monkaBreak.voteBlock(gameId, 1);
        vm.stopPrank();
    }

    function test_VoteBlockRevertVoteAlreadyCast() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        vm.startPrank(player4); // This is police
        monkaBreak.voteBlock(gameId, 1);
        
        vm.expectRevert(MonkaBreak.VoteAlreadyCast.selector);
        monkaBreak.voteBlock(gameId, 2);
        vm.stopPrank();
    }

    function test_ProcessStage() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        // All thieves choose path A (0)
        vm.prank(player1);
        monkaBreak.commitMove(gameId, 0);
        vm.prank(player2);
        monkaBreak.commitMove(gameId, 0);
        vm.prank(player3);
        monkaBreak.commitMove(gameId, 0);
        
        // Police vote to block path A (0)
        vm.prank(player4);
        monkaBreak.voteBlock(gameId, 0);
        vm.prank(player5);
        monkaBreak.voteBlock(gameId, 0);
        vm.prank(player6);
        monkaBreak.voteBlock(gameId, 0);
        
        // Process stage - should eliminate all thieves
        address[] memory expectedEliminated = new address[](3);
        expectedEliminated[0] = player1;
        expectedEliminated[1] = player2;
        expectedEliminated[2] = player3;
        
        vm.expectEmit(true, false, false, true);
        emit StageCompleted(gameId, 0, 0, expectedEliminated);
        
        monkaBreak.processStage(gameId);
        
        (, , , , uint256 currentStage, , , uint256 aliveThieves, ) = monkaBreak.getGameState(gameId);
        assertEq(currentStage, 1);
        assertEq(aliveThieves, 0);
        
        // Check that all thieves are eliminated
        MonkaBreak.Player[] memory players = monkaBreak.getPlayers(gameId);
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].isThief) {
                assertTrue(players[i].eliminated);
            }
        }
    }

    function test_ProcessStagePartialElimination() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        // Thieves choose different paths
        vm.prank(player1);
        monkaBreak.commitMove(gameId, 0); // Path A
        vm.prank(player2);
        monkaBreak.commitMove(gameId, 1); // Path B
        vm.prank(player3);
        monkaBreak.commitMove(gameId, 0); // Path A
        
        // Police vote to block path A (0)
        vm.prank(player4);
        monkaBreak.voteBlock(gameId, 0);
        vm.prank(player5);
        monkaBreak.voteBlock(gameId, 0);
        vm.prank(player6);
        monkaBreak.voteBlock(gameId, 0);
        
        monkaBreak.processStage(gameId);
        
        (, , , , , , , uint256 aliveThieves, ) = monkaBreak.getGameState(gameId);
        assertEq(aliveThieves, 1); // Only player2 should survive
        
        // Check specific eliminations
        MonkaBreak.Player[] memory players = monkaBreak.getPlayers(gameId);
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].addr == player1 || players[i].addr == player3) {
                assertTrue(players[i].eliminated);
            } else if (players[i].addr == player2) {
                assertFalse(players[i].eliminated);
            }
        }
    }

    // ===== Game Finalization Tests =====

    function test_FinalizeGamePoliceWin() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        // Eliminate all thieves in first stage
        _eliminateAllThieves(gameId);
        
        vm.startPrank(owner);
        monkaBreak.finalizeGame(gameId);
        
        // Check that all police are winners
        assertTrue(monkaBreak.isWinner(gameId, player4));
        assertTrue(monkaBreak.isWinner(gameId, player5));
        assertTrue(monkaBreak.isWinner(gameId, player6));
        
        // Check that thieves are not winners
        assertFalse(monkaBreak.isWinner(gameId, player1));
        assertFalse(monkaBreak.isWinner(gameId, player2));
        assertFalse(monkaBreak.isWinner(gameId, player3));
        
        vm.stopPrank();
    }

    function test_FinalizeGameRevertGameNotReadyToFinalize() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        vm.startPrank(owner);
        vm.expectRevert(MonkaBreak.GameNotReadyToFinalize.selector);
        monkaBreak.finalizeGame(gameId);
        vm.stopPrank();
    }

    function test_FinalizeGameRevertOnlyCreatorCanFinalize() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        _eliminateAllThieves(gameId);
        
        vm.startPrank(player1);
        vm.expectRevert(MonkaBreak.OnlyCreatorCanStart.selector);
        monkaBreak.finalizeGame(gameId);
        vm.stopPrank();
    }

    // ===== View Function Tests =====

    function test_GetGameState() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        
        (
            address creator,
            uint256 entryFee,
            bool started,
            bool finalized,
            uint256 currentStage,
            uint256 thievesCount,
            uint256 policeCount,
            uint256 aliveThieves,
            uint256 totalPlayers
        ) = monkaBreak.getGameState(gameId);
        
        assertEq(creator, owner);
        assertEq(entryFee, GAME_ENTRY_FEE);
        assertFalse(started);
        assertFalse(finalized);
        assertEq(currentStage, 0);
        assertEq(thievesCount, 3);
        assertEq(policeCount, 3);
        assertEq(aliveThieves, 3);
        assertEq(totalPlayers, 6);
    }

    function test_GetVaultBalance() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        
        uint256 expectedVault = GAME_ENTRY_FEE * 6; // 6 players
        assertEq(monkaBreak.getVaultBalance(gameId), expectedVault);
    }

    function test_GetPlayers() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        
        MonkaBreak.Player[] memory players = monkaBreak.getPlayers(gameId);
        assertEq(players.length, 6);
        
        // Check that we have 3 thieves and 3 police
        uint256 thiefCount = 0;
        uint256 policeCount = 0;
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].isThief) {
                thiefCount++;
            } else {
                policeCount++;
            }
        }
        assertEq(thiefCount, 3);
        assertEq(policeCount, 3);
    }

    // ===== Integration Tests =====

    function test_FullGameThievesWin() public {
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        // Play through 4 stages with thieves surviving
        for (uint256 stage = 0; stage < 4; stage++) {
            // Thieves choose path A (0)
            vm.prank(player1);
            monkaBreak.commitMove(gameId, 0);
            vm.prank(player2);
            monkaBreak.commitMove(gameId, 0);
            vm.prank(player3);
            monkaBreak.commitMove(gameId, 0);
            
            // Police vote to block path B (1) - different from thieves' choice
            vm.prank(player4);
            monkaBreak.voteBlock(gameId, 1);
            vm.prank(player5);
            monkaBreak.voteBlock(gameId, 1);
            vm.prank(player6);
            monkaBreak.voteBlock(gameId, 1);
            
            monkaBreak.processStage(gameId);
        }
        
        // Mock random winning path to be path A (0)
        vm.mockCall(
            address(0),
            abi.encodeWithSignature("blockhash(uint256)"),
            abi.encode(bytes32(uint256(0))) // This will result in winningPath = 0
        );
        
        vm.prank(owner);
        monkaBreak.finalizeGame(gameId);
        
        // All thieves should be winners since they chose the winning path and it wasn't blocked
        assertTrue(monkaBreak.isWinner(gameId, player1));
        assertTrue(monkaBreak.isWinner(gameId, player2));
        assertTrue(monkaBreak.isWinner(gameId, player3));
        
        // Police should not be winners
        assertFalse(monkaBreak.isWinner(gameId, player4));
        assertFalse(monkaBreak.isWinner(gameId, player5));
        assertFalse(monkaBreak.isWinner(gameId, player6));
    }

    function test_TeamBalanceEnforcement() public {
        vm.prank(owner);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        // Add maximum thieves (7, since min police is 3)
        for (uint256 i = 0; i < 7; i++) {
            address playerAddr = makeAddr(string(abi.encodePacked("thief", i)));
            vm.deal(playerAddr, 10 ether);
            vm.prank(playerAddr);
            monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "", true);
        }
        
        // Try to add one more thief - should fail
        address extraThief = makeAddr("extraThief");
        vm.deal(extraThief, 10 ether);
        vm.startPrank(extraThief);
        vm.expectRevert(MonkaBreak.InvalidTeamSelection.selector);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "", true);
        vm.stopPrank();
    }

    // ===== Helper Functions =====

    function _createGameWithMinimumPlayers() internal returns (uint256 gameId) {
        vm.prank(owner);
        gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        // Add 3 thieves
        vm.prank(player1);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Thief1", true);
        vm.prank(player2);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Thief2", true);
        vm.prank(player3);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Thief3", true);
        
        // Add 3 police
        vm.prank(player4);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Police1", false);
        vm.prank(player5);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Police2", false);
        vm.prank(player6);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Police3", false);
    }

    function _eliminateAllThieves(uint256 gameId) internal {
        // All thieves choose path A (0)
        vm.prank(player1);
        monkaBreak.commitMove(gameId, 0);
        vm.prank(player2);
        monkaBreak.commitMove(gameId, 0);
        vm.prank(player3);
        monkaBreak.commitMove(gameId, 0);
        
        // Police vote to block path A (0)
        vm.prank(player4);
        monkaBreak.voteBlock(gameId, 0);
        vm.prank(player5);
        monkaBreak.voteBlock(gameId, 0);
        vm.prank(player6);
        monkaBreak.voteBlock(gameId, 0);
        
        monkaBreak.processStage(gameId);
    }

    // ===== Fuzz Tests =====

    function testFuzz_CreateGameWithValidEntryFee(uint256 entryFee) public {
        vm.assume(entryFee >= MIN_ENTRY_FEE && entryFee <= 1000 ether);
        
        vm.prank(owner);
        uint256 gameId = monkaBreak.createGame(entryFee);
        
        (, uint256 actualEntryFee, , , , , , , ) = monkaBreak.getGameState(gameId);
        assertEq(actualEntryFee, entryFee);
    }

    function testFuzz_JoinGameWithValidNickname(string memory nickname) public {
        vm.assume(bytes(nickname).length > 0 && bytes(nickname).length <= 32);
        
        vm.prank(owner);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        vm.prank(player1);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, nickname, true);
        
        MonkaBreak.Player[] memory players = monkaBreak.getPlayers(gameId);
        assertEq(players[0].nickname, nickname);
    }

    function testFuzz_CommitMoveWithValidPath(uint8 pathChoice) public {
        vm.assume(pathChoice < 3);
        
        uint256 gameId = _createGameWithMinimumPlayers();
        vm.prank(owner);
        monkaBreak.startGame(gameId);
        
        vm.prank(player1);
        monkaBreak.commitMove(gameId, pathChoice);
        
        MonkaBreak.Player[] memory players = monkaBreak.getPlayers(gameId);
        // Find player1 and check their move
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].addr == player1) {
                assertEq(players[i].moves[0], pathChoice);
                break;
            }
        }
    }
} 