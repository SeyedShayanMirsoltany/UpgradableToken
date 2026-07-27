// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import { Test } from "../../lib/forge-std/src/test.sol";
import "../../src/token/CLToken2.sol";
import "../../src/staking/StakingRewards2.sol";
import "@utils/CustomRoles.sol";
import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

contract Staking is Test {
    address private tokenOwner;
    address private stakingOwner;
    address private user3;
    address private user4;
    address private tokenProxy;
    address private stakingProxy;
    uint duration = block.timestamp + 10000000;
    function setUp() public {
        tokenOwner = vm.addr(100);
        stakingOwner = vm.addr(200);
        user3 = vm.addr(300);
        user4 = vm.addr(400);

        vm.startPrank(tokenOwner);
        CLToken baseToken = new CLToken();
        bytes memory _data = abi.encodeCall(CLToken.initialize, ("Token", "tkn", 100 ether, 1 ether, tokenOwner));
        tokenProxy = address(new ERC1967Proxy(address(baseToken), _data));
        vm.stopPrank();

        vm.startPrank(stakingOwner);
        StakingRewards stakingReward = new StakingRewards();
        bytes memory _dataStaking = abi.encodeCall(StakingRewards.initialize, (tokenProxy, tokenProxy, stakingOwner, duration));
        stakingProxy = address(new ERC1967Proxy(address(stakingReward), _dataStaking));
        vm.stopPrank();
    }

    function test_AdminCanUpgradeTokenToV2() public {
        _upgradeToken();
        assertEq(CLToken(tokenProxy).version(), 2);
    }

    function test_AdminCanUpgradeStakingToV2() public {
        _upgradeStaking();
        assertEq(StakingRewards(stakingProxy).version(), 2);
    }

    function test_Initialize_SetsCorrectValues() public {
        vm.startPrank(stakingOwner);
        assertEq(StakingRewards(stakingProxy).getStakingTokenAddress(), tokenProxy);
        assertEq(StakingRewards(stakingProxy).getRewardTokenAddress(), tokenProxy);
        assertEq(StakingRewards(stakingProxy).getRewardForDuration(), duration);
        assertEq(StakingRewards(stakingProxy).owner(), stakingOwner);
        assertEq(StakingRewards(stakingProxy).hasRole(PAUSER_ROLE, stakingOwner), true);
        vm.stopPrank();
    }

    function _upgradeToken() internal {
        vm.startPrank(tokenOwner);
        CLToken2 baseToken = new CLToken2();
        bytes memory _data = abi.encodeCall(CLToken2.initialize2, (100 ether));
        CLToken(tokenProxy).upgradeToAndCall(address(baseToken), _data);
        vm.stopPrank();
    }

    function _upgradeStaking() internal {
        vm.startPrank(stakingOwner);
        StakingRewards2 stakingVersion2 = new StakingRewards2();
        bytes memory _data = abi.encodeCall(StakingRewards2.initialize, ());
        StakingRewards(stakingProxy).upgradeToAndCall(address(stakingVersion2), _data);
        vm.stopPrank();
    }
}
