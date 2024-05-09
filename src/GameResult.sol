// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {GameResultStorageV1} from "src/GameResultStorage.sol";
import {DataTypes} from "src/libraries/DataTypes.sol";
import {Errors} from "src/libraries/Errors.sol";

contract GameResult is
    GameResultStorageV1,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    bytes4 private constant TRANSFER_SELECTOR =
        bytes4(keccak256("transfer(address,uint256)"));

    event GameInitialized(uint256 indexed gameId, string gameName);
    event RoundCreated(uint256 indexed gameId, uint256 indexed roundId);
    event RoundCancelled(uint256 indexed gameId, uint256 indexed roundId);
    event RoundStarted(
        uint256 indexed gameId,
        uint256 indexed roundId,
        address[] players,
        uint256 timestamp
    );
    event RoundFinished(
        uint256 indexed gameId,
        uint256 indexed roundId,
        uint256[] positions,
        uint256[] points
    );
    event RewardClaimed(
        address indexed player,
        address indexed token,
        uint256 amount
    );

    modifier onlyWhitelisted(address token) {
        _;
        require(tokenWhitelist[token], Errors.VL_NOT_WHITELISTED);
    }

    function initialize(uint256 maxGame) external initializer {
        require(
            maxGame > 0 && maxGame < type(uint16).max,
            Errors.VL_MAX_GAME_INVALID
        );
        _maxGame = uint16(maxGame);
        __Ownable_init(msg.sender);
    }

    function initializeGame(
        uint256 gameId,
        string memory gameName
    ) external onlyOwner {
        require(gameId < uint256(_maxGame), Errors.VL_GAME_OVERFLOW);
        DataTypes.Game storage game = _games[gameId];
        require(game.id == 0, Errors.VL_GAME_INITIALIZED);
        // skip round 0
        _nextIds[gameId]++;
        game.id = gameId;
        game.name = gameName;
        emit GameInitialized(gameId, gameName);
    }

    function createRound(
        uint256 gameId,
        uint256 prize,
        address token,
        uint256[] memory values
    ) external onlyOwner onlyWhitelisted(token) returns (uint256 roundId) {
        require(gameId < uint256(_maxGame), Errors.VL_GAME_OVERFLOW);
        require(_nextIds[gameId] > 0, Errors.VL_GAME_UNINITIALIZED);
        roundId = _createRound(gameId, prize, token, values);
        emit RoundCreated(gameId, roundId);
    }

    function cancelRound(uint256 gameId, uint256 roundId) external onlyOwner {
        require(gameId < uint256(_maxGame), Errors.VL_GAME_OVERFLOW);
        require(_nextIds[gameId] > 0, Errors.VL_GAME_UNINITIALIZED);
        _cancelRound(gameId, roundId);
        emit RoundCancelled(gameId, roundId);
    }

    function startRound(
        uint256 gameId,
        uint256 roundId,
        address[] memory players
    ) external onlyOwner {
        require(gameId < uint256(_maxGame), Errors.VL_GAME_OVERFLOW);
        require(_nextIds[gameId] > 0, Errors.VL_GAME_UNINITIALIZED);
        _startRound(gameId, roundId, players);
        emit RoundStarted(gameId, roundId, players, block.timestamp);
    }

    function finishRound(
        uint256 gameId,
        uint256 roundId,
        uint256[] memory positions,
        uint256[] memory points
    ) external onlyOwner {
        require(gameId < uint256(_maxGame), Errors.VL_GAME_OVERFLOW);
        require(_nextIds[gameId] > 0, Errors.VL_GAME_UNINITIALIZED);
        _finishRound(gameId, roundId, positions, points);
        emit RoundFinished(gameId, roundId, positions, points);
    }

    function claimRewards(
        address player,
        address token,
        uint256 amount
    ) onlyWhitelisted(token) external {
        require(msg.sender == player, Errors.VL_INVALID_MSG_SENDER);
        if (amount == type(uint256).max) {
            amount = _rewards[player][token];
        }
        require(
            _rewards[player][token] >= amount,
            Errors.VL_INVALID_REWARD_AMOUNT
        );
        // check token is whitelisted

        _claimRewards(player, token, amount);
        emit RewardClaimed(player, token, amount);
    }

    function setMaxGame(uint256 _max) external onlyOwner {
        require(
            _max > 0 && _max < type(uint16).max,
            Errors.VL_MAX_GAME_INVALID
        );
        _maxGame = uint16(_max);
    }

    function whitelistToken(address token) external onlyOwner {
        require(token != address(0), Errors.VL_INVALID_ADDRESS);
        require(!tokenWhitelist[token], Errors.VL_ALREADY_WHITELISTED);

        tokenWhitelist[token] = true;
    }

    /**
     * @dev create new round and initialize
     * @param gameId id of current game
     * @param prize total prize for this round
     * @param token address of reward token
     * @param values prize for first, second, third position
     */
    function _createRound(
        uint256 gameId,
        uint256 prize,
        address token,
        uint256[] memory values
    ) internal returns (uint256 roundId) {
        require(values.length == 3, Errors.VL_INVALID_VALUES_LEN);
        require(
            values[0] + values[1] + values[2] == prize,
            Errors.VL_SUM_VALUES_DONT_MATCH
        );
        roundId = _nextIds[gameId];
        DataTypes.Round storage round = _rounds[gameId][roundId];
        round.gameId = gameId;
        round.roundId = roundId;
        round.treasuryToken = token;
        round.status = DataTypes.RoundStatus.PENDING;
        round.prize = prize;
        round.values = values;
        _nextIds[gameId]++;
    }

    /**
     * @dev set player list to round info
     * @param gameId id of current game
     * @param roundId id of current round
     * @param players list of players
     */
    function _startRound(
        uint256 gameId,
        uint256 roundId,
        address[] memory players
    ) internal {
        DataTypes.Round storage round = _rounds[gameId][roundId];
        require(
            round.status == DataTypes.RoundStatus.PENDING,
            Errors.VL_INVALID_STATUS
        );
        round.startTime = block.timestamp;
        round.status = DataTypes.RoundStatus.STARTED;
        round.participants = players;
    }

    /**
     * @dev cancel round
     * @param gameId id of current game
     * @param roundId id of current round
     */
    function _cancelRound(uint256 gameId, uint256 roundId) internal {
        DataTypes.Round storage round = _rounds[gameId][roundId];
        require(
            round.status == DataTypes.RoundStatus.PENDING,
            Errors.VL_INVALID_STATUS
        );
        round.status = DataTypes.RoundStatus.CANCELLED;
    }

    /**
     * @dev record of game result and finish game
     * @param gameId id of current game
     * @param roundId id of current round
     * @param positions the array of game result
     */
    function _finishRound(
        uint256 gameId,
        uint256 roundId,
        uint256[] memory positions,
        uint256[] memory points
    ) internal {
        DataTypes.Round storage round = _rounds[gameId][roundId];
        address[] memory participants = round.participants;
        require(
            participants.length == positions.length,
            Errors.VL_POS_LEN_DONT_MATCH
        );
        require(
            participants.length == points.length,
            Errors.VL_POS_LEN_DONT_MATCH
        );
        require(
            round.status == DataTypes.RoundStatus.STARTED,
            Errors.VL_INVALID_STATUS
        );
        round.positions = positions;
        round.endTime = block.timestamp;
        round.status = DataTypes.RoundStatus.FINISHED;

        for (uint256 i = 0; i < positions.length; i++) {
            _points[gameId][participants[i]] += points[i];
            if (positions[i] < 4) {
                if (positions[i] == 1) {
                    _rewards[participants[i]][round.treasuryToken] += round
                        .values[0];
                } else if (positions[i] == 2) {
                    _rewards[participants[i]][round.treasuryToken] += round
                        .values[1];
                } else if (positions[i] == 3) {
                    _rewards[participants[i]][round.treasuryToken] += round
                        .values[2];
                }
            }
        }
    }

    /**
     * @dev transfer reward from this to player
     * @param player address of player
     * @param token address of token
     * @param amount amount of token
     */
    function _claimRewards(
        address player,
        address token,
        uint256 amount
    ) internal {
        _rewards[player][token] -= amount;
        bytes memory data = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            player,
            amount
        );
        (bool success, ) = address(token).call(data);
        require(success, Errors.TOKEN_TRASFER_FAILED);
    }

    function getMaxGame() external view returns (uint256 maxGame) {
        maxGame = _maxGame;
    }

    function getGame(
        uint256 gameId
    ) external view returns (string memory name, uint256 id) {
        require(gameId < uint256(_maxGame), Errors.VL_GAME_OVERFLOW);
        DataTypes.Game storage game = _games[gameId];
        return (game.name, game.id);
    }

    function getRound(
        uint256 gameId,
        uint256 roundId
    ) external view returns (DataTypes.Round memory round) {
        require(gameId < uint256(_maxGame), Errors.VL_GAME_OVERFLOW);
        return _rounds[gameId][roundId];
    }

    function getPoints(
        uint256 gameId,
        address player
    ) external view returns (uint256 point) {
        require(gameId < uint256(_maxGame), Errors.VL_GAME_OVERFLOW);
        point = _points[gameId][player];
    }

    function getRewards(
        address player,
        address token
    ) external view returns (uint256 amount) {
        return _rewards[player][token];
    }

    function getNextRoundId(
        uint256 gameId
    ) external view returns (uint256 roundId) {
        roundId = _nextIds[gameId];
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
