### Summary
A contract for conducting a lottery using ETH. Instead of relying on a typical pseudo-random generation
method (since the blockchain is deterministic), this contract leverages participants as input for creating the
random number that determines the winner.

The method used here for random number generation is a (somewhat simplified) version of the one used in the
discontinued project RANDAO. See: https://github.com/randao/randao

### Mechanics
The lottery is divided into two phases: the commitment phase and the reveal phase. Participants must commit a
sha3 hashed random number of their choosing during the former phase, and then, after a designated time period,
reveal the number during the reveal phase.

Users are incentivized to call `reveal`, as it reimburses them a deposit which they made when they first called
`commit`. If they don't reveal, their deposit gets left in the pool of winnings.

Once the reveal phase has completed, the winner may be determined by the random number generated from every users'
contribution. The winner may call `claim` to claim the winnings from the pool at any point in the future, and any
user can start a new lottery round by calling `commit` again.
