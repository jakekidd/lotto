// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "../lib/ds-test/src/test.sol";
import "../lib/forge-std/src/stdlib.sol";
import "../lib/forge-std/src/Vm.sol";

import "../src/interfaces/ILotto.sol";
import "../src/Lotto.sol";

import "./utils/Utils.sol";

contract LottoTest is ILotto,DSTest {
    using stdStorage for StdStorage;

    Vm public constant vm = Vm(HEVM_ADDRESS);

    StdStorage public stdstore;

    Utils utils;
    Lotto lotto;
    address payable[] internal users;
    address payable internal owner;

    function setUp() public {
        utils = new Utils();
        owner = utils.createUser();
        vm.prank(address(owner));
        lotto = new Lotto();
        users = utils.createUsers(10);
    }

    function testCommit() public {
        uint depositAmount = lotto.DEPOSIT_AMOUNT();

        // Round ID should start undefined.
        assert(lotto.roundId() == 0);
        address alice = address(users[0]);
        vm.label(alice, "Alice");
        // I used a random number generator to generate this number, so it's very random.
        uint aliceNumber = 10618275348263491499524870515570751408955109907629141527069;
        bytes32 aliceHash = lotto.shaCommit(aliceNumber);
        uint aliceNumTickets = 5;
        uint aliceTicketPayment = aliceNumTickets * lotto.TICKET_PRICE();
        // The first commit should start a new round.
        vm.prank(alice);
        bytes32 roundId = lotto.commit{ value: depositAmount + aliceTicketPayment }(aliceHash);
        assert(roundId != 0);
        assert(lotto.roundId() == roundId);
        // assert(Round(lotto.rounds(roundId)).startTimestamp == block.timestamp);


        // The second should return the same round.
        // address bob = address(users[1]);
        // vm.label(bob, "Bob");
        // uint bobNumber = 618275826349149952487051557075140551099076291427069;
        // bytes32 bobHash = lotto.shaCommit(bobNumber);
        // uint bobNumTickets = 3;



        // Pay insufficient funds for deposit.

        // Pay insufficient funds for deposit + ticket payment.

        // Paying over the maximum number of tickets should cap it at the maximum.

        // Paying for a decimal number of tickets should round down.

        // You can overwrite a previous commit, but doing so is useless as it erases your previous tickets.
    }
}
