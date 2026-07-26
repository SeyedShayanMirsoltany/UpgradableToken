// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "./StakingRewards.sol";
contract StakingRewards2 is StakingRewards {
    function initialize() public onlyOwner reinitializer(2) {}
}
