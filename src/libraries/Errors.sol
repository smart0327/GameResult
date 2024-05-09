// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Errors {
    
    // validation input(1xx)

    // invalid msg.sender
    string public constant VL_INVALID_MSG_SENDER = "100";
    // invalid claim amount
    string public constant VL_INVALID_REWARD_AMOUNT = "101";
    // invalid values' length
    string public constant VL_INVALID_VALUES_LEN = "102";
    // doesn't match prize with sum of values
    string public constant VL_SUM_VALUES_DONT_MATCH = "103";
    // doesn't match participants' len with len of positions
    string public constant VL_POS_LEN_DONT_MATCH = "104";
    // round status is not proper
    string public constant VL_INVALID_STATUS = "105";
    // invalid max game
    string public constant VL_MAX_GAME_INVALID = "106";
    // game overflow
    string public constant VL_GAME_OVERFLOW = "107";
    // already initialized
    string public constant VL_GAME_INITIALIZED = "108";
    // invalid address
    string public constant VL_INVALID_ADDRESS = "109";
    // already whitelisted
    string public constant VL_ALREADY_WHITELISTED = "110";
    // token didn't whitelisted
    string public constant VL_NOT_WHITELISTED = "111";
    // already initialized
    string public constant VL_GAME_UNINITIALIZED = "112";

    // error from 3rd party(2xx)
    
    // erc20(stash, usdc, ...) token transfer failed
    string public constant TOKEN_TRASFER_FAILED = "200";
}