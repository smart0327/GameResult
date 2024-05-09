// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IGameResult {
    function createGame() external returns (uint256 roundId);    
    function startGame(uint256 id) external;
    function finishGame(uint256 id) external;
}