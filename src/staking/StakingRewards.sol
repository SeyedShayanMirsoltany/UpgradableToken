// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "../interfaces/IStakingRewards.sol";
import "@utils/CustomRoles.sol";
import "@openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract StakingRewards is IStakingRewards, UUPSUpgradeable, OwnableUpgradeable {
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
    event RewardsDurationUpdated(uint256 oldDuration, uint256 newDuration);

    error InitialOwnerIsZero();
    error Staking__ZeroAddress();
    error Staking__ZeroAmount();
    error Staking__InsufficientStakedBalance();
    error Staking__InsufficientRewardBalance();
    error Staking__RewardPeriodNotFinished();
    error Staking__NoRewardAvailable();

    IERC20Upgradeable private stakingToken;
    IERC20Upgradeable private rewardsToken;

    uint256 private totalStaked;
    mapping(address => uint256) private balances;

    uint256 private rewardsDuration;
    uint256 private periodFinish;
    uint256 private rewardRate;
    uint256 private lastUpdateTime;
    uint256 private rewardPerTokenStored;

    mapping(address => uint256) private userRewardPerTokenPaid;
    mapping(address => uint256) private rewards;

    function initialize(address stakingToken_, address rewardsToken_, address admin_, uint256 rewardsDuration_) external override {
        if (admin_ == address(0)) revert InitialOwnerIsZero();
        if (stakingToken_ == address(0)) revert Staking__ZeroAddress();
        if (rewardsToken_ == address(0)) revert Staking__ZeroAddress();
        if (rewardsDuration_ <= 0) revert Staking__ZeroAmount();

        rewardsDuration = rewardsDuration_;
        stakingToken = IERC20Upgradeable(stakingToken_);
        rewardsToken = IERC20Upgradeable(rewardsToken_);
        __Ownable_init();
        _transferOwnership(admin_);
    }

    function stake(uint256 amount) external override {
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external override {
        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() external override {}

    function exit() external override {}

    function notifyRewardAmount(uint256 reward) external override {}

    function lastTimeRewardApplicable() external view override returns (uint256) {}

    function rewardPerToken() external view override returns (uint256) {}

    function earned(address account) external view override returns (uint256) {}

    function getRewardForDuration() external view override returns (uint256) {}

    function setRewardsDuration(uint256 newDuration) external override {
        emit RewardsDurationUpdated(rewardsDuration, newDuration);
    }

    function pause() external override {}

    function unpause() external override {}

    function _updateReward(address account) internal {}

    function _authorizeUpgrade(address newImplementation) internal override {}
}
