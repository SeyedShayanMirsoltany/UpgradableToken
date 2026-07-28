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

        CLToken(tokenProxy).mint(stakingOwner, 5 ether);
        CLToken(tokenProxy).mint(user3, 5 ether);
        CLToken(tokenProxy).mint(user4, 5 ether);

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

    //#region test_Initialize

    function test_Initialize_SetsCorrectValues() public {
        vm.startPrank(stakingOwner);
        assertEq(StakingRewards(stakingProxy).getStakingTokenAddress(), tokenProxy);
        assertEq(StakingRewards(stakingProxy).getRewardTokenAddress(), tokenProxy);
        assertEq(StakingRewards(stakingProxy).getRewardForDuration(), duration);
        vm.stopPrank();
    }

    function test_Initialize_SetsOwnerAndRoles() public {
        vm.startPrank(stakingOwner);
        bytes32 DEFAULT_ADMIN_ROLE = 0x00;
        assertEq(StakingRewards(stakingProxy).owner(), stakingOwner);
        assertEq(StakingRewards(stakingProxy).hasRole(DEFAULT_ADMIN_ROLE, stakingOwner), true);
        assertEq(StakingRewards(stakingProxy).hasRole(PAUSER_ROLE, stakingOwner), true);
        vm.stopPrank();
    }

    function test_Initialize_RevertsForZeroAddress() public {
        vm.startPrank(stakingOwner);
        StakingRewards stakingReward = new StakingRewards();
        bytes memory _dataStaking = abi.encodeCall(StakingRewards.initialize, (address(0), tokenProxy, stakingOwner, duration));
        vm.expectRevert(StakingRewards.Staking__ZeroAddress.selector);
        address(new ERC1967Proxy(address(stakingReward), _dataStaking));

        _dataStaking = abi.encodeCall(StakingRewards.initialize, (tokenProxy, address(0), stakingOwner, duration));
        vm.expectRevert(StakingRewards.Staking__ZeroAddress.selector);
        address(new ERC1967Proxy(address(stakingReward), _dataStaking));

        _dataStaking = abi.encodeCall(StakingRewards.initialize, (tokenProxy, tokenProxy, address(0), duration));
        vm.expectRevert(StakingRewards.InitialOwnerIsZero.selector);
        address(new ERC1967Proxy(address(stakingReward), _dataStaking));

        _dataStaking = abi.encodeCall(StakingRewards.initialize, (tokenProxy, tokenProxy, stakingOwner, 0));
        vm.expectRevert(StakingRewards.Staking__ZeroAmount.selector);
        address(new ERC1967Proxy(address(stakingReward), _dataStaking));

        vm.stopPrank();
    }

    function test_Initialize_RevertsWhenCalledTwice() public {
        vm.startPrank(stakingOwner);
        vm.expectRevert();
        StakingRewards(stakingProxy).initialize(tokenProxy, tokenProxy, stakingOwner, duration);
        vm.stopPrank();
    }

    //#endregion test_Initialize

    //#region test_Stake_Functions

    function test_Stake_TransfersTokensAndUpdatesBalances() public {
        vm.startPrank(user3);
        CLToken(tokenProxy).approve(stakingProxy, 1 ether);
        StakingRewards(stakingProxy).stake(1 ether);
        assertEq(StakingRewards(stakingProxy).getStakeBalance(), 1 ether);
        assertEq(StakingRewards(stakingProxy).getTotalStaked(), 1 ether);
        assertEq(CLToken(tokenProxy).balanceOf(stakingProxy), 1 ether);
        vm.stopPrank();
    }

    function test_Stake_EmitsStakedEvent() public {
        vm.startPrank(user3);
        CLToken(tokenProxy).approve(stakingProxy, 1 ether);
        vm.expectEmit(true, false, false, true);
        emit StakingRewards.Staked(user3, 1 ether);
        StakingRewards(stakingProxy).stake(1 ether);
        vm.stopPrank();
    }

    function test_Stake_RevertsWhenAmountIsZero() public {
        vm.startPrank(user3);
        CLToken(tokenProxy).approve(stakingProxy, 1 ether);
        vm.expectRevert(StakingRewards.Staking__ZeroAmount.selector);
        StakingRewards(stakingProxy).stake(0 ether);
        vm.stopPrank();
    }

    function test_Stake_RevertsWithoutSufficientAllowance() public {
        vm.startPrank(user3);
        vm.expectRevert("ERC20: insufficient allowance");
        StakingRewards(stakingProxy).stake(1 ether);
        vm.stopPrank();
    }

    function test_Stake_RevertsWhenPaused() public {
        vm.startPrank(stakingOwner);
        StakingRewards(stakingProxy).pause();
        vm.stopPrank();

        vm.startPrank(user3);
        CLToken(tokenProxy).approve(stakingProxy, 1 ether);
        vm.expectRevert(StakingRewards.OperationIsPaused.selector);
        StakingRewards(stakingProxy).stake(1 ether);
        vm.stopPrank();
    }

    function test_Stake_DoesNotReceivePastRewards() public {
        vm.startPrank(user3);
        CLToken(tokenProxy).approve(stakingProxy, 1 ether);
        StakingRewards(stakingProxy).stake(1 ether);
        vm.stopPrank();
        vm.warp(block.timestamp + 5000000);
        vm.startPrank(user4);
        CLToken(tokenProxy).approve(stakingProxy, 1 ether);
        StakingRewards(stakingProxy).stake(1 ether);
        vm.stopPrank();

        uint256 user3Earned = StakingRewards(stakingProxy).earned(user3);
        uint256 user4Earned = StakingRewards(stakingProxy).earned(user4);

        vm.assertNotEq(user3Earned, user4Earned);
    }

    //#endregion

    //#region test_Withdraw_Functions

    // test_Withdraw_TransfersTokensAndUpdatesBalances
    // test_Withdraw_EmitsWithdrawnEvent
    // test_Withdraw_RevertsWhenAmountIsZero
    // test_Withdraw_RevertsWhenBalanceIsInsufficient
    // test_Withdraw_PreservesEarnedReward
    // test_Withdraw_WorksWhenPaused

    //#endregion

    //#region reward_period

    // test_NotifyRewardAmount_SetsRewardPeriodCorrectly
    // test_NotifyRewardAmount_TransfersRewardsToContract
    // test_NotifyRewardAmount_RevertsForUnauthorizedUser
    // test_NotifyRewardAmount_RevertsWhenRewardIsZero
    // test_NotifyRewardAmount_PreservesRemainingRewards

    //#endregion

    //#region reward_calc

    // test_Earned_ReturnsCorrectRewardForSingleStaker
    // test_Earned_DistributesRewardsProportionally
    // test_RewardPerToken_DoesNotIncreaseWithoutStakers
    // test_RewardStopsIncreasingAfterPeriodFinish
    // test_ClaimReward_TransfersAndResetsReward
    // test_ClaimReward_DoesNotPayTwice
    // test_Exit_WithdrawsStakeAndClaimsReward
    // test_Exit_WorksWhenPaused

    //#endregion

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
