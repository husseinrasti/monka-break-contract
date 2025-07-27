// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MonkaBreak} from "../src/MonkaBreak.sol";

contract MonkaBreakTest is Test {
    MonkaBreak public monkaBreak;
    
    address public creator = address(0x1);
    address public player1 = address(0x2);
    address public player2 = address(0x3);
    address public nonOwner = address(0x4);
    
    // Test constants - updated to match new mutable variables
    uint256 public constant MIN_ENTRY_FEE = 2 ether;
    uint256 public constant GAME_ENTRY_FEE = 3 ether;

    function setUp() public {
        // Deploy contract and set creator as owner
        vm.prank(creator);
        monkaBreak = new MonkaBreak();
        
        // Fund test accounts
        vm.deal(creator, 100 ether);
        vm.deal(player1, 100 ether);
        vm.deal(player2, 100 ether);
        vm.deal(nonOwner, 100 ether);
    }

    // ===== OWNER FUNCTIONALITY TESTS =====

    function testConstructorSetsOwner() public {
        assertEq(monkaBreak.owner(), creator);
    }

    function testOnlyOwnerModifier() public {
        vm.prank(nonOwner);
        vm.expectRevert(MonkaBreak.OnlyOwnerCanCall.selector);
        monkaBreak.setMinEntryFee(5 ether);
    }

    function testTransferOwnership() public {
        address newOwner = address(0x5);
        
        vm.prank(creator);
        vm.expectEmit(true, true, false, false);
        emit MonkaBreak.OwnershipTransferred(creator, newOwner);
        monkaBreak.transferOwnership(newOwner);
        
        assertEq(monkaBreak.owner(), newOwner);
        
        // Test new owner can call owner functions
        vm.prank(newOwner);
        monkaBreak.setMinEntryFee(5 ether);
        assertEq(monkaBreak.minEntryFee(), 5 ether);
    }

    function testTransferOwnershipToZeroAddress() public {
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.NewOwnerIsZeroAddress.selector);
        monkaBreak.transferOwnership(address(0));
    }

    function testNonOwnerCannotTransferOwnership() public {
        vm.prank(nonOwner);
        vm.expectRevert(MonkaBreak.OnlyOwnerCanCall.selector);
        monkaBreak.transferOwnership(address(0x5));
    }

    // ===== INDIVIDUAL SETTER TESTS =====

    function testSetMinEntryFee() public {
        uint256 newFee = 5 ether;
        uint256 oldFee = monkaBreak.minEntryFee();
        
        vm.prank(creator);
        vm.expectEmit(false, false, false, true);
        emit MonkaBreak.MinEntryFeeUpdated(oldFee, newFee);
        monkaBreak.setMinEntryFee(newFee);
        
        assertEq(monkaBreak.minEntryFee(), newFee);
    }

    function testSetMinEntryFeeZeroReverts() public {
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidMinEntryFee.selector);
        monkaBreak.setMinEntryFee(0);
    }

    function testSetMinThieves() public {
        uint256 newMin = 5;
        uint256 oldMin = monkaBreak.minThieves();
        
        vm.prank(creator);
        vm.expectEmit(false, false, false, true);
        emit MonkaBreak.MinThievesUpdated(oldMin, newMin);
        monkaBreak.setMinThieves(newMin);
        
        assertEq(monkaBreak.minThieves(), newMin);
    }

    function testSetMinThievesZeroReverts() public {
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidMinThieves.selector);
        monkaBreak.setMinThieves(0);
    }

    function testSetMinPolice() public {
        uint256 newMin = 4;
        uint256 oldMin = monkaBreak.minPolice();
        
        vm.prank(creator);
        vm.expectEmit(false, false, false, true);
        emit MonkaBreak.MinPoliceUpdated(oldMin, newMin);
        monkaBreak.setMinPolice(newMin);
        
        assertEq(monkaBreak.minPolice(), newMin);
    }

    function testSetMinPoliceZeroReverts() public {
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidMinPolice.selector);
        monkaBreak.setMinPolice(0);
    }

    function testSetMaxPlayers() public {
        uint256 newMax = 15;
        uint256 oldMax = monkaBreak.maxPlayers();
        
        vm.prank(creator);
        vm.expectEmit(false, false, false, true);
        emit MonkaBreak.MaxPlayersUpdated(oldMax, newMax);
        monkaBreak.setMaxPlayers(newMax);
        
        assertEq(monkaBreak.maxPlayers(), newMax);
    }

    function testSetMaxPlayersInvalidReverts() public {
        // Try to set max players less than minThieves + minPolice
        uint256 minThieves = monkaBreak.minThieves();
        uint256 minPolice = monkaBreak.minPolice();
        uint256 invalidMax = minThieves + minPolice - 1;
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidMaxPlayers.selector);
        monkaBreak.setMaxPlayers(invalidMax);
    }

    function testSetTotalStages() public {
        uint256 newStages = 3;
        uint256 oldStages = monkaBreak.totalStages();
        
        vm.prank(creator);
        vm.expectEmit(false, false, false, true);
        emit MonkaBreak.TotalStagesUpdated(oldStages, newStages);
        monkaBreak.setTotalStages(newStages);
        
        assertEq(monkaBreak.totalStages(), newStages);
    }

    function testSetTotalStagesInvalidReverts() public {
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidTotalStages.selector);
        monkaBreak.setTotalStages(0);
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidTotalStages.selector);
        monkaBreak.setTotalStages(5);
    }

    function testSetNumPaths() public {
        uint256 newPaths = 5;
        uint256 oldPaths = monkaBreak.numPaths();
        
        vm.prank(creator);
        vm.expectEmit(false, false, false, true);
        emit MonkaBreak.NumPathsUpdated(oldPaths, newPaths);
        monkaBreak.setNumPaths(newPaths);
        
        assertEq(monkaBreak.numPaths(), newPaths);
    }

    function testSetNumPathsZeroReverts() public {
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidNumPaths.selector);
        monkaBreak.setNumPaths(0);
    }

    // ===== BULK UPDATE TESTS =====

    function testUpdateGameParameters() public {
        uint256 newMinEntryFee = 5 ether;
        uint256 newMinThieves = 4;
        uint256 newMinPolice = 4;
        uint256 newMaxPlayers = 12;
        uint256 newTotalStages = 3;
        uint256 newNumPaths = 4;
        
        vm.prank(creator);
        vm.expectEmit(false, false, false, true);
        emit MonkaBreak.GameParametersUpdated(
            newMinEntryFee, 
            newMinThieves, 
            newMinPolice, 
            newMaxPlayers, 
            newTotalStages, 
            newNumPaths
        );
        
        monkaBreak.updateGameParameters(
            newMinEntryFee,
            newMinThieves,
            newMinPolice,
            newMaxPlayers,
            newTotalStages,
            newNumPaths
        );
        
        assertEq(monkaBreak.minEntryFee(), newMinEntryFee);
        assertEq(monkaBreak.minThieves(), newMinThieves);
        assertEq(monkaBreak.minPolice(), newMinPolice);
        assertEq(monkaBreak.maxPlayers(), newMaxPlayers);
        assertEq(monkaBreak.totalStages(), newTotalStages);
        assertEq(monkaBreak.numPaths(), newNumPaths);
    }

    function testUpdateGameParametersInvalidValues() public {
        // Test invalid minEntryFee
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidMinEntryFee.selector);
        monkaBreak.updateGameParameters(0, 3, 3, 10, 4, 3);
        
        // Test invalid minThieves
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidMinThieves.selector);
        monkaBreak.updateGameParameters(2 ether, 0, 3, 10, 4, 3);
        
        // Test invalid minPolice
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidMinPolice.selector);
        monkaBreak.updateGameParameters(2 ether, 3, 0, 10, 4, 3);
        
        // Test invalid maxPlayers
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidMaxPlayers.selector);
        monkaBreak.updateGameParameters(2 ether, 3, 3, 5, 4, 3);
        
        // Test invalid totalStages
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidTotalStages.selector);
        monkaBreak.updateGameParameters(2 ether, 3, 3, 10, 0, 3);
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidTotalStages.selector);
        monkaBreak.updateGameParameters(2 ether, 3, 3, 10, 5, 3);
        
        // Test invalid numPaths
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InvalidNumPaths.selector);
        monkaBreak.updateGameParameters(2 ether, 3, 3, 10, 4, 0);
    }

    // ===== INTEGRATION TESTS WITH NEW PARAMETERS =====

    function testGameCreationWithUpdatedMinFee() public {
        // Update minimum entry fee
        vm.prank(creator);
        monkaBreak.setMinEntryFee(5 ether);
        
        // Try to create game with old fee - should fail
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InsufficientEntryFee.selector);
        monkaBreak.createGame(3 ether);
        
        // Create game with new fee - should succeed
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(5 ether);
        assertEq(gameId, 1);
    }

    function testMaxPlayersEnforced() public {
        // Update max players to 6
        vm.prank(creator);
        monkaBreak.setMaxPlayers(6);
        
        // Create game
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        // Add 6 players (should work)
        for (uint160 i = 1; i <= 6; i++) {
            address player = address(i);
            vm.deal(player, 10 ether);
            vm.prank(player);
            monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Player", i % 2 == 0);
        }
        
        // Try to add 7th player (should fail)
        address player7 = address(0x7);
        vm.deal(player7, 10 ether);
        vm.prank(player7);
        vm.expectRevert(MonkaBreak.GameIsFull.selector);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Player7", true);
    }

    function testUpdatedMinThievesAndPoliceEnforced() public {
        // Update min thieves and police to 2 each
        vm.prank(creator);
        monkaBreak.setMinThieves(2);
        vm.prank(creator);
        monkaBreak.setMinPolice(2);
        
        // Create game
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        // Add 1 thief and 1 police
        vm.prank(player1);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Thief1", true);
        vm.prank(player2);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Police1", false);
        
        // Try to start (should fail - not enough players)
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InsufficientPlayers.selector);
        monkaBreak.startGame(gameId);
        
        // Add one more thief and police
        address player3 = address(0x5);
        address player4 = address(0x6);
        vm.deal(player3, 10 ether);
        vm.deal(player4, 10 ether);
        
        vm.prank(player3);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Thief2", true);
        vm.prank(player4);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Police2", false);
        
        // Now start should work
        vm.prank(creator);
        monkaBreak.startGame(gameId);
        
        (,,bool started,,,,,,) = monkaBreak.getGameState(gameId);
        assertTrue(started);
    }

    // ===== EXISTING TESTS (Updated to use mutable variables) =====

    function testCreateGame() public {
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        assertEq(gameId, 1);
        assertEq(monkaBreak.getCurrentGameId(), 1);
        
        (address gameCreator, uint256 entryFee,,,,,,,) = monkaBreak.getGameState(gameId);
        assertEq(gameCreator, creator);
        assertEq(entryFee, GAME_ENTRY_FEE);
    }

    function testCreateGameInsufficientFee() public {
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InsufficientEntryFee.selector);
        monkaBreak.createGame(1 ether); // Less than MIN_ENTRY_FEE
    }

    function testJoinGame() public {
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        vm.prank(player1);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Alice", true);
        
        MonkaBreak.Player[] memory players = monkaBreak.getPlayers(gameId);
        assertEq(players.length, 1);
        assertEq(players[0].addr, player1);
    }

    function testJoinGameInsufficientPayment() public {
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        vm.prank(player1);
        vm.expectRevert(MonkaBreak.InsufficientEntryFee.selector);
        monkaBreak.joinGame{value: 1 ether}(gameId, "Alice", true);
    }

    function testJoinGameAlreadyJoined() public {
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        vm.prank(player1);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Alice", true);
        
        vm.prank(player1);
        vm.expectRevert(MonkaBreak.PlayerAlreadyJoined.selector);
        monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, "Alice2", false);
    }

    function testStartGame() public {
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        // Add minimum required players
        _addMinimumPlayers(gameId);
        
        vm.prank(creator);
        monkaBreak.startGame(gameId);
        
        (,,bool started,,,,,,) = monkaBreak.getGameState(gameId);
        assertTrue(started);
    }

    function testStartGameInsufficientPlayers() public {
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InsufficientPlayers.selector);
        monkaBreak.startGame(gameId);
    }

    function testCommitMove() public {
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        _addMinimumPlayers(gameId);
        
        vm.prank(creator);
        monkaBreak.startGame(gameId);
        
        vm.prank(player1);
        monkaBreak.commitMove(gameId, 1); // Path B
        
        // Verify move was committed (can't test exact move due to private storage)
        vm.prank(player1);
        vm.expectRevert(MonkaBreak.MoveAlreadyCommitted.selector);
        monkaBreak.commitMove(gameId, 2);
    }

    function testVoteBlock() public {
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        _addMinimumPlayers(gameId);
        
        vm.prank(creator);
        monkaBreak.startGame(gameId);
        
        // Find a police player and use them for voting
        MonkaBreak.Player[] memory players = monkaBreak.getPlayers(gameId);
        address policePlayer;
        for (uint256 i = 0; i < players.length; i++) {
            if (!players[i].isThief) {
                policePlayer = players[i].addr;
                break;
            }
        }
        
        vm.prank(policePlayer);
        monkaBreak.voteBlock(gameId, 0); // Block path A
        
        uint8 policeVote = monkaBreak.getPoliceVote(gameId, 0);
        assertEq(policeVote, 0);
    }

    function testProcessStage() public {
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        _addMinimumPlayersAndStart(gameId);
        
        // Commit moves for all thieves
        MonkaBreak.Player[] memory players = monkaBreak.getPlayers(gameId);
        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i].addr;
            bool isThief = players[i].isThief;
            if (isThief) {
                vm.prank(player);
                monkaBreak.commitMove(gameId, uint8(i % 3));
            }
        }
        
        // Vote for all police
        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i].addr;
            bool isThief = players[i].isThief;
            if (!isThief) {
                vm.prank(player);
                monkaBreak.voteBlock(gameId, uint8(i % 3));
            }
        }
        
        vm.prank(creator);
        monkaBreak.processStage(gameId);
        
        // Verify stage was processed
        (,,,,uint256 currentStage,,,,) = monkaBreak.getGameState(gameId);
        assertEq(currentStage, 1);
    }

    function testGetVaultBalance() public {
        vm.prank(creator);
        uint256 gameId = monkaBreak.createGame(GAME_ENTRY_FEE);
        _addMinimumPlayers(gameId);
        
        uint256 expectedVault = GAME_ENTRY_FEE * 6; // 6 players joined
        uint256 actualVault = monkaBreak.getVaultBalance(gameId);
        assertEq(actualVault, expectedVault);
    }

    // ===== HELPER FUNCTIONS =====

    function _addMinimumPlayers(uint256 gameId) internal {
        // Add 3 thieves
        for (uint160 i = 1; i <= 3; i++) {
            address player = address(i);
            vm.deal(player, 10 ether);
            vm.prank(player);
            monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, string(abi.encodePacked("Thief", i)), true);
        }
        
        // Add 3 police
        for (uint160 i = 4; i <= 6; i++) {
            address player = address(i);
            vm.deal(player, 10 ether);
            vm.prank(player);
            monkaBreak.joinGame{value: GAME_ENTRY_FEE}(gameId, string(abi.encodePacked("Police", i)), false);
        }
    }

    function _addMinimumPlayersAndStart(uint256 gameId) internal {
        _addMinimumPlayers(gameId);
        vm.prank(creator);
        monkaBreak.startGame(gameId);
    }

    // ===== FUZZ TESTS =====

    function testFuzzSetMinEntryFee(uint256 fee) public {
        vm.assume(fee > 0 && fee <= type(uint128).max);
        
        vm.prank(creator);
        monkaBreak.setMinEntryFee(fee);
        assertEq(monkaBreak.minEntryFee(), fee);
    }

    function testFuzzSetMaxPlayers(uint8 maxPlayers) public {
        uint256 minThieves = monkaBreak.minThieves();
        uint256 minPolice = monkaBreak.minPolice();
        vm.assume(maxPlayers >= minThieves + minPolice && maxPlayers <= 50);
        
        vm.prank(creator);
        monkaBreak.setMaxPlayers(maxPlayers);
        assertEq(monkaBreak.maxPlayers(), maxPlayers);
    }

    function testFuzzSetTotalStages(uint256 stages) public {
        vm.assume(stages > 0 && stages <= 4);
        
        vm.prank(creator);
        monkaBreak.setTotalStages(stages);
        assertEq(monkaBreak.totalStages(), stages);
    }
} 