## Summary
`Lotto` is a contract for conducting a lottery using ETH. Instead of relying on a typical pseudo-random generation method (since the blockchain is deterministic), this contract leverages participants as input for creating the random number that determines the winner.

The algorithm implemented here for random number generation is a (somewhat simplified) version of the one used in the discontinued project [RANDAO](https://github.com/randao/randao). It does not rely on a DAO; instead, the algorithm is integrated into the lifecycles - called lottery **rounds** - of the contract itself.

## Mechanics
The lottery is divided into two phases: the **commitment** phase and the **reveal** phase. Participants must commit a sha3 hash of a random number of their choosing during the former phase, and then, after a designated time period, reveal the number during the latter phase.

When the user calls `commit`, they commit the hash of their secret random number, as well as send a deposit (0.01 ETH) and an additional 0.01 ETH for every lotto ticket they want to purchase for the round (up to a fixed maximum).

After the commitment phase period elapses, users are incentivized to call `reveal`, as it reimburses them a deposit (set to 0.01eth) which they made when they first called `commit`. If they don't reveal, their deposit gets left in the pool of winnings, and they aren't added to the pool of participants (so they have no way of actually winning).

Over the course of the reveal phase, the random number is seeded by all the secret numbers that are revealed.

Once the reveal phase has completed, the final random number determines the winner out of the array of participants. The winner may call `claim` to claim the winnings from the pool at any point in the future. Additionally, any user can start a new lottery round by calling `commit` again.

## Ideas for Future Updates
Some functionality that might be neat to add to this project in the future:
- Support for ERC20 tokens.
- Starting a new round after the commitment phase completes (instead of preventing another round from starting during reveal phase).
- Custom rounds with a different 'ante' or buy-in (as well as a custom deposit).
- Private rounds that all come from the same msg.sender, enabling an outside contract to use this one.
