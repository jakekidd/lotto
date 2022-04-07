// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "../lib/ds-test/src/test.sol";
import "../lib/forge-std/src/stdlib.sol";
import "../lib/forge-std/src/Vm.sol";
import "../lib/forge-std/src/console.sol";

import "../src/Lotto.sol";

import "./utils/IUtils.sol";
import "./utils/Utils.sol";

contract LottoTest is IUtils,DSTest {
    using stdStorage for StdStorage;

    Vm public constant vm = Vm(HEVM_ADDRESS);

    StdStorage public stdstore;

    Utils utils;
    Lotto lotto;
    User alice;
    User bob;
    address payable internal owner;

    function setUp() public {
        utils = new Utils();
        owner = utils.createUserAddress();
        vm.prank(address(owner));
        lotto = new Lotto();
        alice = utils.createUser();
        bob = utils.createUser();
    }

    function testCommit() public {
        uint depositAmount = lotto.DEPOSIT_AMOUNT();

        // Round ID should start undefined.
        assert(lotto.roundId() == 0);
        vm.label(alice.addr, "Alice");
        uint aliceNumTickets = 5;
        // The first commit should start a new round.
        vm.prank(alice.addr);
        bytes32 roundId = lotto.commit{ value: depositAmount + aliceNumTickets * lotto.TICKET_PRICE() }(alice.numberHash);
        // The round ID should be defined.
        assert(roundId != 0);
        // The round ID should be reflected in contract state.
        assert(lotto.roundId() == roundId);
        // Make sure start timestamp is correct.
        (uint256 start,,,) = lotto.rounds(roundId);
        assert(start == block.timestamp);
        console.log(lotto.tickets(alice.addr));
        
        // assert(lotto.tickets(alice.addr) == aliceNumTickets);

        // The second should return the same round.
        vm.label(bob.addr, "Bob");
        uint bobNumTickets = 3;
        vm.prank(bob.addr);
        bytes32 bobRoundId = lotto.commit{ value: depositAmount + bobNumTickets * lotto.TICKET_PRICE() }(bob.numberHash);

        // Should be the same, shouldn't start a new round.
        assert(bobRoundId == roundId);
        // assert(lotto.tickets(bob.addr) == bobNumTickets);
        console.log(lotto.tickets(bob.addr));



        // Pay insufficient funds for deposit.

        // Pay insufficient funds for deposit + ticket payment.

        // Paying over the maximum number of tickets should cap it at the maximum.

        // Paying for a decimal number of tickets should round down.

        // You can overwrite a previous commit, but doing so is useless as it erases your previous tickets.
    }

}
