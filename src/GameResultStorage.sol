// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { DataTypes } from "src/libraries/DataTypes.sol";

abstract contract GameResultStorageV1 {
    uint16 _maxGame;
    mapping(uint256 gameId => DataTypes.Game game) _games;
    mapping(uint256 gameId => uint256 roundId) _nextIds;
    mapping(uint256 gameId => mapping(uint256 roundId => DataTypes.Round round)) _rounds;
    mapping(address player => mapping(address token => uint256 amount)) _rewards;
    mapping(uint256 gameId => mapping(address player => uint256 point)) _points;
    mapping(address token => bool isWhitelisted) tokenWhitelist;
}

// new version should inherit above contract
