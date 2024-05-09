// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library DataTypes {
    uint256 constant MAX_GAME = 256;
    // this is not clear
    uint256 constant MAX_PARTICIPANTS = 128;

    enum RoundStatus {
        NONE,
        PENDING,
        STARTED,
        CANCELLED,
        FINISHED
    }

    struct Game {
        string name;
        uint256 id;
    }

    struct Round {
        uint256 gameId;
        uint256 roundId;
        uint256 startTime;
        uint256 endTime;
        RoundStatus status;
        address treasuryToken;
        // stash or usd amount
        uint256 prize;
        uint256[] values;
        address[] participants;
        uint256[] positions;
    }
}
