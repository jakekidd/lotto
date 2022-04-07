// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../../lib/ds-test/src/test.sol";
import "../../lib/forge-std/src/Vm.sol";

contract Utils is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function getNextUserAddress() external returns (address payable) {
        //bytes32 to address conversion
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    function createUser() public returns (address payable) {
        address payable user = this.getNextUserAddress();
        vm.deal(user, 100 ether);
        return user;
    }

    //create users with 100 ether balance
    function createUsers(uint256 userNum)
        external
        returns (address payable[] memory)
    {
        address payable[] memory users = new address payable[](userNum);
        for (uint256 i = 0; i < userNum; i++) {
            users[i] = createUser();
        }
        return users;
    }

    //move block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) external {
        uint256 targetBlock = block.number + numBlocks;
        vm.roll(targetBlock);
    }
}
