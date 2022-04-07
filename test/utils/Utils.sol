// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../../lib/ds-test/src/test.sol";
import "../../lib/forge-std/src/Vm.sol";

import "./IUtils.sol";

contract Utils is IUtils,DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    uint i = 0;

    // I used a random number generator to generate this number, therefore they are very random.
    uint256[] public randomNumbers = [
        10618275348263491499524870515570751408955109907629141527069,
        618275826349149952487051557075140551099076291427069
    ];

    function getNextUserAddress() internal returns (address payable) {
        //bytes32 to address conversion
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    function getNextRandomNumber() internal returns (uint256) {
        uint256 number = randomNumbers[i];
        i = (i + 1) % randomNumbers.length;
        return number;
    }

    function createUserAddress() public returns (address payable) {
        address payable user = getNextUserAddress();
        vm.deal(user, 100 ether);
        return user;
    }

    // Create user with random number, 100 ether balance
    function createUser()
        external
        returns (User memory)
    {
        uint number = getNextRandomNumber();
        return User({
            addr: address(createUserAddress()),
            secretNumber: number,
            numberHash: keccak256(abi.encodePacked(number))
        });
    }

    // Move block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) external {
        uint256 targetBlock = block.number + numBlocks;
        vm.roll(targetBlock);
    }
}
