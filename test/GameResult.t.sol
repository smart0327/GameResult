// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GameResult} from "src/GameResult.sol";
import {DataTypes} from "src/libraries/DataTypes.sol";
import {MockStash} from "./mocks/MockStash.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract GameResultTest is Test {
    GameResult resultContract;    
    address owner;
    function setUp() public {
        owner = makeAddr("owner");
        vm.startPrank(owner);
        address implementation = address(new GameResult());
        bytes memory data = abi.encodeCall(GameResult.initialize, 256);
        address proxy = address(new ERC1967Proxy(implementation, data));
        resultContract = GameResult(proxy);
        vm.stopPrank();
    }

    function test_initialize(uint256 gameId, string memory gameName) public {
        vm.assume(gameId < resultContract.getMaxGame());

        vm.expectEmit(true, true, false, true);
        emit GameResult.GameInitialized(gameId, gameName);

        vm.startPrank(owner);
        (string memory newGame, uint256 newId) = _initializeGame(gameId, gameName);
        vm.stopPrank();

        assert(keccak256(abi.encodePacked(newGame)) == keccak256(abi.encodePacked(gameName)));
        assert(newId == gameId);        
    }

    function test_createRound(uint256 gameId, string memory gameName, uint256 prize, address token) public {
        vm.assume(gameId < resultContract.getMaxGame());
        vm.assume(token != address(0));
        vm.assume(prize > 0);
        (uint256[] memory values, , , ) = _mockValues(prize);

        vm.startPrank(owner);
        resultContract.whitelistToken(token);
        (, uint256 newId) = _initializeGame(gameId, gameName);
        // nextRoundId will be changed when initializing game, so RoundCreated event should be checked here.
        vm.expectEmit(true, true, false, false);
        emit GameResult.RoundCreated(gameId, resultContract.getNextRoundId(gameId));
        DataTypes.Round memory round = _createRound(newId, prize, token, values);
        vm.stopPrank();

        assert(round.gameId == gameId);
        assert(round.startTime == 0);
        assert(round.status == DataTypes.RoundStatus.PENDING);
        assert(round.treasuryToken == token);
        assert(round.values.length == values.length);
        assert(round.participants.length == 0);
        assert(round.positions.length == 0);
    }

    function test_cancelRound(uint256 gameId, string memory gameName, uint256 prize, address token) public {
        vm.assume(gameId < resultContract.getMaxGame());
        vm.assume(keccak256(abi.encodePacked(gameName)) != keccak256(abi.encodePacked("")));
        vm.assume(token != address(0));
        vm.assume(prize > 0);
        (uint256[] memory values, uint256 v0, uint256 v1, uint256 v2) = _mockValues(prize);

        vm.startPrank(owner);
        resultContract.whitelistToken(token);
        (, uint256 newId) = _initializeGame(gameId, gameName);
        DataTypes.Round memory round = _createRound(newId, prize, token, values);
        vm.expectEmit(true, true, false, false);        
        emit GameResult.RoundCancelled(newId, round.roundId);
        resultContract.cancelRound(newId, round.roundId);
        vm.stopPrank();

        round = resultContract.getRound(gameId, round.roundId);
        
        assert(round.gameId == gameId);
        assert(round.startTime == 0);
        assert(round.status == DataTypes.RoundStatus.CANCELLED);
        assert(round.treasuryToken == token);
        assert(round.values.length == values.length);
        assert(round.participants.length == 0);
        assert(round.positions.length == 0);
        assert(round.values[0] == v0);
        assert(round.values[1] == v1);
        assert(round.values[2] == v2);
    }

    function test_startRound(uint256 gameId, string memory gameName, uint256 prize, address token, address[] memory players) public {
        vm.assume(gameId < resultContract.getMaxGame());
        vm.assume(token != address(0));
        vm.assume(prize > 0);
        (uint256[] memory values, uint256 v0, uint256 v1, uint256 v2) = _mockValues(prize);

        vm.startPrank(owner);
        resultContract.whitelistToken(token);
        (, uint256 newId) = _initializeGame(gameId, gameName);
        DataTypes.Round memory round = _createRound(newId, prize, token, values);
        vm.expectEmit(true, true, false, false);
        // don't check data because we don't have proper timestamp now.
        emit GameResult.RoundStarted(newId, round.roundId, new address[](1), 0);
        resultContract.startRound(newId, round.roundId, players);
        vm.stopPrank();

        round = resultContract.getRound(gameId, round.roundId);

        assert(round.gameId == gameId);
        assert(round.startTime != 0);
        assert(round.status == DataTypes.RoundStatus.STARTED);
        assert(round.treasuryToken == token);
        assert(round.values.length == values.length);
        assert(round.participants.length == players.length);
        assert(round.positions.length == 0);
        assert(round.values[0] == v0);
        assert(round.values[1] == v1);
        assert(round.values[2] == v2);
    }

    function test_finishRound(uint256 gameId, string memory gameName, uint256 prize, address token) public {
        uint256 nPlayers = 5;
        vm.assume(gameId < resultContract.getMaxGame());
        vm.assume(token != address(0));
        vm.assume(prize > 0);
        (uint256[] memory values, uint256 v0, uint256 v1, uint256 v2) = _mockValues(prize);
        address[] memory players = _mockPlayers(nPlayers);
        uint256[] memory positions = _mockPositions(nPlayers);
        uint256[] memory points = _mockPoints(nPlayers);

        vm.startPrank(owner);
        resultContract.whitelistToken(token);
        (, uint256 newId) = _initializeGame(gameId, gameName);
        DataTypes.Round memory round = _createRound(newId, prize, token, values);
        resultContract.startRound(newId, round.roundId, players);
        vm.expectEmit(true, true, false, true);
        emit GameResult.RoundFinished(newId, round.roundId, positions, points);
        resultContract.finishRound(newId, round.roundId, positions, points);
        vm.stopPrank();

        round = resultContract.getRound(gameId, round.roundId);
        
        assert(round.gameId == gameId);
        assert(round.startTime != 0);
        assert(round.endTime != 0);
        assert(round.status == DataTypes.RoundStatus.FINISHED);
        assert(round.treasuryToken == token);
        assert(round.values.length == values.length);
        assert(round.participants.length == players.length);
        assert(round.positions.length == players.length);
        assert(round.values[0] == v0);
        assert(round.values[1] == v1);
        assert(round.values[2] == v2);
        for (uint256 i = 0; i < nPlayers; i++) {
            assert(round.participants[i] == players[i]);
            assert(round.positions[i] == positions[i]);
            assert(resultContract.getPoints(round.gameId, players[i]) == points[i]);
        }
    }

    function test_claimRewards(uint256 gameId, string memory gameName, uint256 prize) public {

        uint256 nPlayers = 5;
        vm.assume(gameId < resultContract.getMaxGame());        
        vm.assume(prize > 1e18);
        (uint256[] memory values, , ,) = _mockValues(prize);
        address[] memory players = _mockPlayers(nPlayers);
        uint256[] memory positions = _mockPositions(nPlayers);
        uint256[] memory points = _mockPoints(nPlayers);

        vm.startPrank(owner);
        address token = _mockStash();        
        console.log("amount", prize);
        MockStash(token).mint(address(resultContract), prize);
        resultContract.whitelistToken(token);

        (, uint256 newId) = _initializeGame(gameId, gameName);
        DataTypes.Round memory round = _createRound(newId, prize, token, values);
        resultContract.startRound(newId, round.roundId, players);
        resultContract.finishRound(newId, round.roundId, positions, points);
        vm.stopPrank();

        round = resultContract.getRound(gameId, round.roundId);
        uint256 reward0 = resultContract.getRewards(round.participants[0], token);
        uint256 reward1 = resultContract.getRewards(round.participants[1], token);
        uint256 reward2 = resultContract.getRewards(round.participants[2], token);
        vm.prank(round.participants[0]);
        vm.expectEmit(true, true, false, true);
        emit GameResult.RewardClaimed(round.participants[0], token, reward0);
        resultContract.claimRewards(round.participants[0], token, reward0);
        vm.prank(round.participants[1]);
        vm.expectEmit(true, true, false, true);
        emit GameResult.RewardClaimed(round.participants[1], token, reward1);
        resultContract.claimRewards(round.participants[1], token, reward1);
        vm.prank(round.participants[2]);
        vm.expectEmit(true, true, false, true);
        emit GameResult.RewardClaimed(round.participants[2], token, reward2);
        resultContract.claimRewards(round.participants[2], token, reward2);

        assert(IERC20(token).balanceOf(round.participants[0]) == reward0);
        assert(IERC20(token).balanceOf(round.participants[1]) == reward1);
        assert(IERC20(token).balanceOf(round.participants[2]) == reward2);
    }

    function _initializeGame(uint256 gameId, string memory gameName) internal returns (string memory newName, uint256 newId) {
        resultContract.initializeGame(gameId, gameName);
        (newName, newId) = resultContract.getGame(gameId);
    }

    function _createRound(uint256 gameId, uint256 prize, address token, uint256[] memory values) internal returns (DataTypes.Round memory round) {
        uint256 roundId = resultContract.createRound(gameId, prize, token, values);
        round = resultContract.getRound(gameId, roundId);
    }

    function _mockValues(uint256 prize) internal pure returns (uint256[] memory values, uint256 v0, uint256 v1, uint256 v2) {
        values = new uint256[](3);
        v0 = values[0] = prize / 2;
        v1 = values[1] = prize / 3;
        v2 = values[2] = prize - values[0] - values[1];
    }

    function _mockPlayers(uint256 num) internal pure returns (address[] memory players) {
        players = new address[](num);
        for (uint256 i = 0; i < num; i++) {
            players[i] = vm.addr(200 + i);
        }
    }

    function _mockPositions(uint256 num) internal pure returns (uint256[] memory positions) {
        positions = new uint256[](num);
        for (uint256 i = 0; i < num; i++) {
            positions[i] = (i + 200) % num;
        }
    }

    function _mockPoints(uint256 num) internal pure returns (uint256[] memory points) {
        points = new uint256[](num);
        for (uint256 i = 0; i < num; i++) {
            points[i] = (i + 200) % 50;
        }
    }

    function _mockStash() internal returns (address token) {
        MockStash stash = new MockStash();
        stash.initialize();
        token = address(stash);
    }
}
