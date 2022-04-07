// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "./interfaces/ILotto.sol";

/**
 * @title Lotto
 * @dev A contract for conducting a lottery using ETH. Instead of relying on a typical pseudo-random generation
 * method (since the blockchain is deterministic), this contract leverages participants as input for creating the
 * random number that determines the winner.
 *
 * The lottery is divided into two phases: the commitment phase and the reveal phase. Participants must commit a
 * sha3 hashed random number of their choosing during the former phase, and then, after a designated time period,
 * reveal the number during the reveal phase.
 *
 * Users are incentivized to call `reveal`, as it reimburses them a deposit which they made when they first called
 * `commit`. If they don't reveal, their deposit gets left in the pool of winnings.
 *
 * Once the reveal phase has completed, the winner may be determined by the random number generated from every users'
 * contribution. The winner may call `claim` to claim the winnings from the pool at any point in the future, and any
 * user can start a new lottery round by calling `commit` again.
 *
 * The method used here for random number generation is a (somewhat simplified) version of the one used in the
 * discontinued project RANDAO. See: https://github.com/randao/randao
 */
contract Lotto is ILotto {
    // The time that 1 commitment phase takes (ideally). After this period, we enter the reveal round.
    uint256 public constant COMMIT_PHASE_LENGTH = 6 hours;
    // The time after which the determined revealed number for a round is solidified.
    uint256 public constant REVEAL_PHASE_LENGTH = 2 hours;
    // Deposit that is refunded to the participant if they reveal their number before the reveal
    // phase expires.
    uint256 public constant DEPOSIT_AMOUNT = 0.01 ether;
    // Price of pushing a single entry into the lottery.
    uint256 public constant TICKET_PRICE = 0.01 ether;
    // Maximum number of tickets per commitment.
    uint256 public constant MAX_TICKETS = 100;

    address public owner;

    // Current round ID, generated from block timestamp.
    bytes32 public roundId;

    // Round ID => Round
    mapping(bytes32 => Round) public rounds;

    // Depositor tickets purchased for the current round.
    mapping(address => uint256) public tickets;

    // Participants in the current round.
    address[] public participants;

    constructor() {
        owner = msg.sender;
    }

    // User commits a hash for their secret number, contributes the required deposit and purchases tickets.
    function commit(bytes32 _commit) external payable returns (bytes32) {
        // Caller must send at least the value of 1 ticket.
        require(
            msg.value >= TICKET_PRICE + DEPOSIT_AMOUNT,
            "Needs deposit + ticket payment"
        );

        // Start a new round if needed.
        if (isRoundComplete(roundId)) {
            nextRound();
        } else {
            // We're still in an open lottery round - make sure the commitment phase hasn't already ended.
            require(
                !isCommitPhaseComplete(roundId),
                "Commit phase is already complete"
            );
        }

        // Add the commitment to the round under the caller's address.
        rounds[roundId].commitments[msg.sender] = _commit;

        // Number of tickets that the caller can afford with the value sent.
        // NOTE: Caller can technically send in more than the maximum, but any leftover gets added into the pot and
        // gives them no additional benefit.
        uint256 numTickets = (msg.value - DEPOSIT_AMOUNT) / 0.01 ether;
        numTickets = numTickets > MAX_TICKETS ? MAX_TICKETS : numTickets;
        tickets[msg.sender] = numTickets;

        // Add the full message value to the round's current pool.
        // NOTE: This includes the deposit. This is intentional: if the participants fails to call reveal, they forfeit
        // their deposit to the winnings pool. Additionally, using msg.value ensures we don't lose any dust.
        rounds[roundId].pool += msg.value;

        return roundId;
    }

    // Intended to be called during the reveal phase, when participants may reveal their random numbers.
    function reveal(uint256 number) external {
        // Check if we're in the reveal phase.
        require(isCommitPhaseComplete(roundId), "Commit phase has not ended");
        require(!isRoundComplete(roundId), "Round has already ended");

        // Make sure the caller has made a commitment for this round.
        bytes32 _commit = rounds[roundId].commitments[msg.sender];
        require(_commit != 0, "Caller is missing a commitment");

        // Caller may only reveal once, erase their commitment.
        rounds[roundId].commitments[msg.sender] = 0;

        // Caller's number must match their commitment.
        require(
            keccak256(abi.encodePacked(number)) == _commit,
            "Number does not match commitment"
        );

        // Bitwise OR the current revealed number for this round.
        rounds[roundId].seed ^= number;

        // Insert the caller address once per ticket purchased.
        for (uint256 i = 0; i < tickets[msg.sender]; i++) {
            participants.push(msg.sender);
        }

        // Subtract the deposit from the pool, then refund the deposit portion to the caller. This
        // is to reward participation and incentivize revealing the amount.
        rounds[roundId].pool -= DEPOSIT_AMOUNT;
        payable(msg.sender).transfer(DEPOSIT_AMOUNT);
    }

    // If you're calling this (and it doesn't revert) - congrats! You've won the lottery!
    function claim(bytes32 _roundId) external {
        require(rounds[_roundId].pool > 0, "No winnings to claim");

        require(isRoundComplete(_roundId), "Round has not yet completed");

        if (rounds[_roundId].winner == address(0)) {
            // Round is complete, but the winner hasn't been determined yet.
            // This will close out the round, determine the winner, and start a new one.
            nextRound();
        }

        // Check to see if the caller is the winner.
        require(
            rounds[_roundId].winner == msg.sender,
            "You're not the winner :("
        );

        // Transfer the winnings to the caller.
        uint256 _pool = rounds[_roundId].pool;
        rounds[_roundId].pool = 0;
        payable(msg.sender).transfer(_pool);

        emit WinnerClaimed(_roundId, msg.sender);
    }

    // Check if the current commitment phase has expired.
    function isCommitPhaseComplete(bytes32 _roundId)
        public
        view
        returns (bool)
    {
        return (block.timestamp >
            rounds[_roundId].startTimestamp + COMMIT_PHASE_LENGTH);
    }

    // Check whether the given round's commit and reveal phases have completed (assuming rounds have
    // been initialized).
    function isRoundComplete(bytes32 _roundId) public view returns (bool) {
        return
            (block.timestamp >
                rounds[_roundId].startTimestamp +
                    COMMIT_PHASE_LENGTH +
                    REVEAL_PHASE_LENGTH) || roundId == 0;
    }

    function nextRound() private {
        // If we have a round in progress, wrap it up.
        if (rounds[roundId].seed != 0 && participants.length > 0) {
            // Get the winner's index from the revealed number.
            uint256 winnerIndex = rounds[roundId].seed % participants.length;
            // Set the winner for the round.
            rounds[roundId].winner = participants[winnerIndex];
        }

        // Clear participants.
        delete participants;

        // Update the round to a new ID.
        roundId = keccak256(abi.encodePacked(block.timestamp));
        // Set the round start timestamp.
        rounds[roundId].startTimestamp = block.timestamp;

        emit NewRoundStarted(roundId);
    }

    // Helper utility to get the sha commitment phrase (bytes) of a given number.
    function shaCommit(uint256 secretNumber) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(secretNumber));
    }
}
