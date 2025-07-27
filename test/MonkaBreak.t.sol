// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MonkaBreak} from "../src/MonkaBreak.sol";

contract MonkaBreakTest is Test {
    MonkaBreak public monkaBreak;
    
    address public creator = address(0x1);
    address public player1 = address(0x2);
    address public player2 = address(0x3);
    address public player3 = address(0x4);
    address public nonCreator = address(0x5);
    
    uint256 public constant MIN_ENTRY_FEE = 1 ether;
    uint256 public constant TEST_GAME_ID = 1;
    uint256 public constant ANOTHER_GAME_ID = 2;

    function setUp() public {
        monkaBreak = new MonkaBreak();
        
        // Fund test accounts
        vm.deal(creator, 100 ether);
        vm.deal(player1, 100 ether);
        vm.deal(player2, 100 ether);
        vm.deal(player3, 100 ether);
        vm.deal(nonCreator, 100 ether);
    }

    // ===== CREATE GAME TESTS =====

    function testCreateGame() public {
        vm.prank(creator);
        vm.expectEmit(true, true, false, false);
        emit MonkaBreak.GameCreated(TEST_GAME_ID, creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        (address gameCreator, uint256 vault, uint256 entryFee, uint256 startBlock, bool started, bool finalized) = 
            monkaBreak.getGame(TEST_GAME_ID);
        
        assertEq(gameCreator, creator);
        assertEq(vault, 0);
        assertEq(entryFee, 0);
        assertEq(startBlock, 0);
        assertFalse(started);
        assertFalse(finalized);
    }

    function testCreateGameWithDifferentCreators() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.prank(player1);
        monkaBreak.createGame(ANOTHER_GAME_ID);
        
        (address creator1,,,,,) = monkaBreak.getGame(TEST_GAME_ID);
        (address creator2,,,,,) = monkaBreak.getGame(ANOTHER_GAME_ID);
        
        assertEq(creator1, creator);
        assertEq(creator2, player1);
    }

    function testCreateGameAlreadyExists() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.GameAlreadyExists.selector);
        monkaBreak.createGame(TEST_GAME_ID);
    }

    function testCreateGameAlreadyExistsDifferentCreator() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.prank(player1);
        vm.expectRevert(MonkaBreak.GameAlreadyExists.selector);
        monkaBreak.createGame(TEST_GAME_ID);
    }

    // ===== START GAME TESTS =====

    function testStartGame() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        uint256 entryFee = 3 ether;
        
        vm.prank(creator);
        vm.expectEmit(true, false, false, true);
        emit MonkaBreak.GameStarted(TEST_GAME_ID, entryFee, block.number);
        monkaBreak.startGame{value: entryFee}(TEST_GAME_ID);
        
        (address gameCreator, uint256 vault, uint256 gameEntryFee, uint256 startBlock, bool started, bool finalized) = 
            monkaBreak.getGame(TEST_GAME_ID);
        
        assertEq(gameCreator, creator);
        assertEq(vault, entryFee);
        assertEq(gameEntryFee, entryFee);
        assertEq(startBlock, block.number);
        assertTrue(started);
        assertFalse(finalized);
    }

    function testStartGameMinimumFee() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.prank(creator);
        monkaBreak.startGame{value: MIN_ENTRY_FEE}(TEST_GAME_ID);
        
        (, uint256 vault, uint256 entryFee,,,) = monkaBreak.getGame(TEST_GAME_ID);
        assertEq(vault, MIN_ENTRY_FEE);
        assertEq(entryFee, MIN_ENTRY_FEE);
    }

    function testStartGameInsufficientFee() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InsufficientEntryFee.selector);
        monkaBreak.startGame{value: MIN_ENTRY_FEE - 1}(TEST_GAME_ID);
    }

    function testStartGameZeroFee() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.InsufficientEntryFee.selector);
        monkaBreak.startGame{value: 0}(TEST_GAME_ID);
    }

    function testStartGameNonexistentGame() public {
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.GameNotFound.selector);
        monkaBreak.startGame{value: MIN_ENTRY_FEE}(TEST_GAME_ID);
    }

    function testStartGameNotCreator() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.prank(nonCreator);
        vm.expectRevert(MonkaBreak.OnlyCreatorCanCall.selector);
        monkaBreak.startGame{value: MIN_ENTRY_FEE}(TEST_GAME_ID);
    }

    function testStartGameAlreadyStarted() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.prank(creator);
        monkaBreak.startGame{value: MIN_ENTRY_FEE}(TEST_GAME_ID);
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.GameAlreadyStarted.selector);
        monkaBreak.startGame{value: MIN_ENTRY_FEE}(TEST_GAME_ID);
    }

    // ===== FINALIZE GAME TESTS =====

    function testFinalizeGameSingleWinner() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        uint256 entryFee = 4 ether;
        vm.prank(creator);
        monkaBreak.startGame{value: entryFee}(TEST_GAME_ID);
        
        address[] memory winners = new address[](1);
        winners[0] = player1;
        
        uint256 player1BalanceBefore = player1.balance;
        
        vm.prank(creator);
        vm.expectEmit(true, false, false, true);
        emit MonkaBreak.GameFinalized(TEST_GAME_ID, winners);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
        
        (, uint256 vault,,,, bool finalized) = monkaBreak.getGame(TEST_GAME_ID);
        assertEq(vault, 0);
        assertTrue(finalized);
        assertEq(player1.balance, player1BalanceBefore + entryFee);
    }

    function testFinalizeGameMultipleWinners() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        uint256 entryFee = 6 ether;
        vm.prank(creator);
        monkaBreak.startGame{value: entryFee}(TEST_GAME_ID);
        
        address[] memory winners = new address[](3);
        winners[0] = player1;
        winners[1] = player2;
        winners[2] = player3;
        
        uint256 player1BalanceBefore = player1.balance;
        uint256 player2BalanceBefore = player2.balance;
        uint256 player3BalanceBefore = player3.balance;
        
        uint256 expectedPrize = entryFee / 3;
        
        vm.prank(creator);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
        
        (, uint256 vault,,,, bool finalized) = monkaBreak.getGame(TEST_GAME_ID);
        assertEq(vault, 0);
        assertTrue(finalized);
        assertEq(player1.balance, player1BalanceBefore + expectedPrize);
        assertEq(player2.balance, player2BalanceBefore + expectedPrize);
        assertEq(player3.balance, player3BalanceBefore + expectedPrize);
    }

    function testFinalizeGameWithRemainder() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        uint256 entryFee = 5 ether; // Not evenly divisible by 3
        vm.prank(creator);
        monkaBreak.startGame{value: entryFee}(TEST_GAME_ID);
        
        address[] memory winners = new address[](3);
        winners[0] = player1;
        winners[1] = player2;
        winners[2] = player3;
        
        uint256 player1BalanceBefore = player1.balance;
        uint256 expectedPrize = entryFee / 3; // 1.666... ether = 1 ether (truncated)
        
        vm.prank(creator);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
        
        assertEq(player1.balance, player1BalanceBefore + expectedPrize);
        // Remainder stays in contract (locked forever)
    }

    function testFinalizeGameNoWinners() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.prank(creator);
        monkaBreak.startGame{value: MIN_ENTRY_FEE}(TEST_GAME_ID);
        
        address[] memory winners = new address[](0);
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.NoWinners.selector);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
    }

    function testFinalizeGameNonexistentGame() public {
        address[] memory winners = new address[](1);
        winners[0] = player1;
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.GameNotFound.selector);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
    }

    function testFinalizeGameNotStarted() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        address[] memory winners = new address[](1);
        winners[0] = player1;
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.GameNotStarted.selector);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
    }

    function testFinalizeGameNotCreator() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.prank(creator);
        monkaBreak.startGame{value: MIN_ENTRY_FEE}(TEST_GAME_ID);
        
        address[] memory winners = new address[](1);
        winners[0] = player1;
        
        vm.prank(nonCreator);
        vm.expectRevert(MonkaBreak.OnlyCreatorCanCall.selector);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
    }

    function testFinalizeGameAlreadyFinalized() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.prank(creator);
        monkaBreak.startGame{value: MIN_ENTRY_FEE}(TEST_GAME_ID);
        
        address[] memory winners = new address[](1);
        winners[0] = player1;
        
        vm.prank(creator);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.GameAlreadyFinalized.selector);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
    }

    function testFinalizeGameTransferFailed() public {
        // Deploy a contract that rejects ETH transfers
        RejectEther rejectContract = new RejectEther();
        
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.prank(creator);
        monkaBreak.startGame{value: MIN_ENTRY_FEE}(TEST_GAME_ID);
        
        address[] memory winners = new address[](1);
        winners[0] = address(rejectContract);
        
        vm.prank(creator);
        vm.expectRevert(MonkaBreak.TransferFailed.selector);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
    }

    // ===== GET GAME TESTS =====

    function testGetGameNonexistent() public {
        vm.expectRevert(MonkaBreak.GameNotFound.selector);
        monkaBreak.getGame(TEST_GAME_ID);
    }

    function testGetGameCreated() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        (address gameCreator, uint256 vault, uint256 entryFee, uint256 startBlock, bool started, bool finalized) = 
            monkaBreak.getGame(TEST_GAME_ID);
        
        assertEq(gameCreator, creator);
        assertEq(vault, 0);
        assertEq(entryFee, 0);
        assertEq(startBlock, 0);
        assertFalse(started);
        assertFalse(finalized);
    }

    function testGetGameStarted() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        uint256 testEntryFee = 3 ether;
        vm.prank(creator);
        monkaBreak.startGame{value: testEntryFee}(TEST_GAME_ID);
        
        (address gameCreator, uint256 vault, uint256 entryFee, uint256 startBlock, bool started, bool finalized) = 
            monkaBreak.getGame(TEST_GAME_ID);
        
        assertEq(gameCreator, creator);
        assertEq(vault, testEntryFee);
        assertEq(entryFee, testEntryFee);
        assertEq(startBlock, block.number);
        assertTrue(started);
        assertFalse(finalized);
    }

    function testGetGameFinalized() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        uint256 testEntryFee = 3 ether;
        vm.prank(creator);
        monkaBreak.startGame{value: testEntryFee}(TEST_GAME_ID);
        
        address[] memory winners = new address[](1);
        winners[0] = player1;
        
        vm.prank(creator);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
        
        (address gameCreator, uint256 vault, uint256 entryFee, uint256 startBlock, bool started, bool finalized) = 
            monkaBreak.getGame(TEST_GAME_ID);
        
        assertEq(gameCreator, creator);
        assertEq(vault, 0); // Vault cleared after finalization
        assertEq(entryFee, testEntryFee);
        assertEq(startBlock, block.number);
        assertTrue(started);
        assertTrue(finalized);
    }

    // ===== INTEGRATION TESTS =====

    function testCompleteGameFlow() public {
        // Create game
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        // Start game
        uint256 entryFee = 10 ether;
        vm.prank(creator);
        monkaBreak.startGame{value: entryFee}(TEST_GAME_ID);
        
        // Finalize game with multiple winners
        address[] memory winners = new address[](2);
        winners[0] = player1;
        winners[1] = player2;
        
        uint256 player1BalanceBefore = player1.balance;
        uint256 player2BalanceBefore = player2.balance;
        
        vm.prank(creator);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
        
        // Verify final state
        (,uint256 vault,,,, bool finalized) = monkaBreak.getGame(TEST_GAME_ID);
        assertEq(vault, 0);
        assertTrue(finalized);
        assertEq(player1.balance, player1BalanceBefore + 5 ether);
        assertEq(player2.balance, player2BalanceBefore + 5 ether);
    }

    function testMultipleGamesSimultaneously() public {
        uint256 gameId1 = 1;
        uint256 gameId2 = 2;
        uint256 entryFee1 = 3 ether;
        uint256 entryFee2 = 5 ether;
        
        // Create and start two games
        vm.prank(creator);
        monkaBreak.createGame(gameId1);
        vm.prank(player1);
        monkaBreak.createGame(gameId2);
        
        vm.prank(creator);
        monkaBreak.startGame{value: entryFee1}(gameId1);
        vm.prank(player1);
        monkaBreak.startGame{value: entryFee2}(gameId2);
        
        // Verify both games are independent
        (, uint256 vault1,,,,) = monkaBreak.getGame(gameId1);
        (, uint256 vault2,,,,) = monkaBreak.getGame(gameId2);
        
        assertEq(vault1, entryFee1);
        assertEq(vault2, entryFee2);
        
        // Finalize both games
        address[] memory winners1 = new address[](1);
        winners1[0] = player2;
        address[] memory winners2 = new address[](1);
        winners2[0] = player3;
        
        uint256 player2BalanceBefore = player2.balance;
        uint256 player3BalanceBefore = player3.balance;
        
        vm.prank(creator);
        monkaBreak.finalizeGame(gameId1, winners1);
        vm.prank(player1);
        monkaBreak.finalizeGame(gameId2, winners2);
        
        assertEq(player2.balance, player2BalanceBefore + entryFee1);
        assertEq(player3.balance, player3BalanceBefore + entryFee2);
    }

    // ===== FUZZ TESTS =====

    function testFuzzCreateGame(uint256 gameId) public {
        vm.assume(gameId != 0); // Avoid edge case where game creator would be zero address check
        
        vm.prank(creator);
        monkaBreak.createGame(gameId);
        
        (address gameCreator,,,,,) = monkaBreak.getGame(gameId);
        assertEq(gameCreator, creator);
    }

    function testFuzzStartGame(uint256 entryFee) public {
        vm.assume(entryFee >= MIN_ENTRY_FEE && entryFee <= 1000 ether);
        
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        vm.deal(creator, entryFee);
        vm.prank(creator);
        monkaBreak.startGame{value: entryFee}(TEST_GAME_ID);
        
        (, uint256 vault, uint256 gameEntryFee,,,) = monkaBreak.getGame(TEST_GAME_ID);
        assertEq(vault, entryFee);
        assertEq(gameEntryFee, entryFee);
    }

    function testFuzzFinalizeGame(uint8 numWinners) public {
        vm.assume(numWinners > 0 && numWinners <= 10);
        
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        uint256 entryFee = uint256(numWinners) * MIN_ENTRY_FEE; // Ensure even distribution and meets minimum
        vm.prank(creator);
        monkaBreak.startGame{value: entryFee}(TEST_GAME_ID);
        
        address[] memory winners = new address[](numWinners);
        for (uint256 i = 0; i < numWinners; i++) {
            winners[i] = address(uint160(i + 100)); // Use addresses 100, 101, 102, etc.
            vm.deal(winners[i], 0); // Ensure clean slate for balance checks
        }
        
        vm.prank(creator);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
        
        uint256 expectedPrize = MIN_ENTRY_FEE; // Each winner gets MIN_ENTRY_FEE since entryFee = numWinners * MIN_ENTRY_FEE
        for (uint256 i = 0; i < numWinners; i++) {
            assertEq(winners[i].balance, expectedPrize);
        }
    }

    // ===== EDGE CASE TESTS =====

    function testGameIdZero() public {
        vm.prank(creator);
        monkaBreak.createGame(0);
        
        (address gameCreator,,,,,) = monkaBreak.getGame(0);
        assertEq(gameCreator, creator);
    }

    function testGameIdMaxUint256() public {
        uint256 maxGameId = type(uint256).max;
        
        vm.prank(creator);
        monkaBreak.createGame(maxGameId);
        
        (address gameCreator,,,,,) = monkaBreak.getGame(maxGameId);
        assertEq(gameCreator, creator);
    }

    function testContractBalance() public {
        vm.prank(creator);
        monkaBreak.createGame(TEST_GAME_ID);
        
        uint256 entryFee = 5 ether;
        vm.prank(creator);
        monkaBreak.startGame{value: entryFee}(TEST_GAME_ID);
        
        assertEq(address(monkaBreak).balance, entryFee);
        
        address[] memory winners = new address[](1);
        winners[0] = player1;
        
        vm.prank(creator);
        monkaBreak.finalizeGame(TEST_GAME_ID, winners);
        
        assertEq(address(monkaBreak).balance, 0);
    }
}

// Helper contract for testing transfer failures
contract RejectEther {
    // Contract that rejects all ETH transfers
    fallback() external payable {
        revert();
    }
    
    receive() external payable {
        revert();
    }
} 