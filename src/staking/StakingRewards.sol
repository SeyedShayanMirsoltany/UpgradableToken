// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "../interfaces/IStakingRewards.sol";
import "@utils/CustomRoles.sol";
import "@openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract StakingRewards is IStakingRewards, UUPSUpgradeable, OwnableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
    event RewardsDurationUpdated(uint256 oldDuration, uint256 newDuration);

    error OperationIsPaused();
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
    bool private isPaused;
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
        __AccessControl_init();
        __ReentrancyGuard_init();
        _transferOwnership(admin_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(PAUSER_ROLE, admin_);
    }

    function stake(uint256 amount) external override checkIsPaused nonReentrant updateReward(msg.sender) {
        require(amount > 0, Staking__ZeroAmount());
        totalStaked += amount;
        balances[msg.sender] += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external override {
        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() external override {}

    function exit() external override {}

    function notifyRewardAmount(uint256 reward) external override {}

    function _lastTimeRewardApplicable() internal view returns (uint256) {
        return lastUpdateTime;
    }

    function _rewardPerToken() internal view returns (uint256) {}

    function _earned(address account) internal view returns (uint256) {}

    function getRewardForDuration() external view override returns (uint256) {}

    function setRewardsDuration(uint256 newDuration) external override {
        emit RewardsDurationUpdated(rewardsDuration, newDuration);
    }

    function lastTimeRewardApplicable() external view override returns (uint256) {
        return _lastTimeRewardApplicable();
    }

    function rewardPerToken() external view override returns (uint256) {
        return _rewardPerToken();
    }

    function earned(address account) external view override returns (uint256) {
        return _earned(account);
    }

    function getPauseStatus() external view override onlyRole(PAUSER_ROLE) returns (bool) {
        return isPaused;
    }

    function pause() external override onlyRole(PAUSER_ROLE) {
        isPaused = true;
    }

    function unpause() external override onlyRole(PAUSER_ROLE) {
        isPaused = false;
    }

    function _updateReward(address account) internal {}

    function _authorizeUpgrade(address newImplementation) internal override {}

    modifier checkIsPaused() {
        require(!isPaused, OperationIsPaused());
        _;
    }

    modifier updateReward(address account) {
        // 1. به‌روزرسانی حسابداری کل استخر
        rewardPerTokenStored = _rewardPerToken();
        lastUpdateTime = _lastTimeRewardApplicable();

        // 2. ذخیره پاداش کاربر تا همین لحظه
        if (account != address(0)) {
            rewards[account] = _earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
}
