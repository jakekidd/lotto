// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IUtils {
    struct User {
        address addr;
        uint256 secretNumber;
        bytes32 numberHash;
    }
}