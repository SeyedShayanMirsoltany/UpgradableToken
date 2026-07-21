// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IStakingRewards {
    function initialize(address stakingToken_, address rewardsToken_, address admin_, uint256 rewardsDuration_) external;
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function claimReward() external;
    function exit() external;
    function notifyRewardAmount(uint256 reward) external;
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getRewardForDuration() external view returns (uint256);
    function setRewardsDuration(uint256 newDuration) external;
    function pause() external;
    function unpause() external;
}
