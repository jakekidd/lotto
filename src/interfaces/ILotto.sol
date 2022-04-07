// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

interface ILotto {

    struct Round {
        // Block timestamp of when the round started.
        uint startTimestamp;
        // Pool of winnings.
        uint pool;
        // Winner of this round.
        address winner;
        // Random number for this round, which is generated from users' secret numbers.
        uint seed;
        // depositor addr => sha3 encrypted random number commitments.
        mapping(address => bytes32) commitments;
    }

    // Called when a new lottery round begins.
    event NewRoundStarted(bytes32 roundId);

    // Called when a lottery winner claims the a pool of winnings.
    event WinnerClaimed(bytes32 roundId, address winner);
}