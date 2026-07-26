// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "../interfaces/IStakingRewards.sol";
import "@utils/CustomRoles.sol";
import "@openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract StakingRewards is IStakingRewards, UUPSUpgradeable, OwnableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
    event RewardsDurationUpdated(uint256 oldDuration, uint256 newDuration);
    event Paused(address indexed user);
    event Unpaused(address indexed account);

    error OperationIsPaused();
    error InitialOwnerIsZero();
    error Staking__ZeroAddress();
    error Staking__ZeroAmount();
    error Staking__InsufficientStakedBalance();
    error Staking__InsufficientRewardBalance();
    error Staking__RewardPeriodNotFinished();
    error Staking__NoRewardAvailable();

    IERC20 private stakingToken;
    IERC20 private rewardsToken;

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
    uint256 private constant PRECISION = 1e18;

    function initialize(address stakingToken_, address rewardsToken_, address admin_, uint256 rewardsDuration_) external override initializer {
        if (admin_ == address(0)) revert InitialOwnerIsZero();
        if (stakingToken_ == address(0)) revert Staking__ZeroAddress();
        if (rewardsToken_ == address(0)) revert Staking__ZeroAddress();
        if (rewardsDuration_ <= 0) revert Staking__ZeroAmount();

        rewardsDuration = rewardsDuration_;
        stakingToken = IERC20(stakingToken_);
        rewardsToken = IERC20(rewardsToken_);
        __Ownable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        _transferOwnership(admin_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(PAUSER_ROLE, admin_);
    }

    constructor() {
        _disableInitializers();
    }

    function stake(uint256 amount) external override checkIsPaused nonReentrant updateReward(msg.sender) {
        if (amount > 0) revert Staking__ZeroAmount();
        totalStaked += amount;
        balances[msg.sender] += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external override {
        _withdraw(amount);
    }

    function _withdraw(uint256 amount) internal nonReentrant updateReward(msg.sender) {
        if (amount <= 0) revert Staking__ZeroAmount();
        if (balances[msg.sender] < amount) revert Staking__InsufficientStakedBalance();
        totalStaked -= amount;
        balances[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() external override {
        _claimReward();
    }

    function _claimReward() internal nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward <= 0) revert Staking__NoRewardAvailable();
        rewards[msg.sender] = 0;
        rewardsToken.safeTransfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function exit() external override {
        uint256 amount = balances[msg.sender];
        if (amount > 0) _withdraw(amount);
        if (_earned(msg.sender) > 0) _claimReward();
    }

    function notifyRewardAmount(uint256 reward) external override checkIsPaused onlyOwner updateReward(address(0)) {
        if (reward == 0) revert Staking__ZeroAmount();

        rewardsToken.safeTransferFrom(msg.sender, address(this), reward);

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remainingTime = periodFinish - block.timestamp;
            uint256 leftoverReward = remainingTime * rewardRate;

            rewardRate = (reward + leftoverReward) / rewardsDuration;
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        emit RewardAdded(reward);
    }

    function _lastTimeRewardApplicable() internal view returns (uint256) {
        if (block.timestamp >= periodFinish) return periodFinish;
        return block.timestamp;
    }

    function _rewardPerToken() internal view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;
        uint256 elapsedTime = _lastTimeRewardApplicable() - lastUpdateTime;
        return rewardPerTokenStored + ((elapsedTime * rewardRate * PRECISION) / totalStaked);
    }

    function _earned(address account) internal view returns (uint256) {
        return (balances[account] * (_rewardPerToken() - userRewardPerTokenPaid[account])) / PRECISION + rewards[account];
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    function setRewardsDuration(uint256 newDuration) external override onlyOwner {
        if (newDuration == 0) revert Staking__ZeroAmount();
        if (block.timestamp >= periodFinish) revert Staking__RewardPeriodNotFinished();

        uint256 oldDuration = rewardsDuration;
        rewardsDuration = newDuration;
        emit RewardsDurationUpdated(oldDuration, newDuration);
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

    function getPauseStatus() external view override returns (bool) {
        return isPaused;
    }

    function pause() external override onlyRole(PAUSER_ROLE) {
        if (isPaused) revert OperationIsPaused();
        isPaused = true;
        emit Paused(msg.sender);
    }

    function unpause() external override onlyRole(PAUSER_ROLE) {
        if (!isPaused) revert OperationIsPaused();
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier checkIsPaused() {
        if (!isPaused) revert OperationIsPaused();
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

    function version() public view returns (uint8) {
        return _getInitializedVersion();
    }
}
// slither . --include-paths "src/" --exclude-low --exclude-informational --exclude-optimization
