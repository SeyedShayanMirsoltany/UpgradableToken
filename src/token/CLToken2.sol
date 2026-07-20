// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./CLToken.sol";

contract CLToken2 is CLToken {
    error ZeroAddress();
    error SenderIsLock(address user);
    error ReceiverIsLock(address user);
    error InvalidMaxTransferAmount(uint256 maxTransferAmount);
    uint256 private _maxTransferAmount;

    mapping(address sender => bool isLocked) private _sendersIsBlocked;
    mapping(address receiver => bool isLocked) private _receiversIsBlocked;

    function initialize2(uint256 maxTransferAmount_) public onlyOwner reinitializer(2) {
        if (maxTransferAmount_ == 0) revert InvalidMaxTransferAmount(_maxTransferAmount);
        _maxTransferAmount = maxTransferAmount_;
    }

    function modifyMaxTransferAmount(uint256 maxTransferAmount_) public onlyOwner {
        if (maxTransferAmount_ == 0) revert InvalidMaxTransferAmount(maxTransferAmount_);
        _maxTransferAmount = maxTransferAmount_;
    }

    function getMaxTransferAmount() external view returns (uint256) {
        return _maxTransferAmount;
    }

    function modifySender(address sender, bool islocked) public onlyOwner {
        if (sender == address(0)) revert ZeroAddress();
        _sendersIsBlocked[sender] = islocked;
    }

    function modifyReceiver(address receiver, bool islocked) public onlyOwner {
        if (receiver == address(0)) revert ZeroAddress();
        _receiversIsBlocked[receiver] = islocked;
    }

    function getSenderLockStatus(address user) public view returns (bool) {
        return _sendersIsBlocked[user];
    }

    function getReceiverLockStatus(address user) public view returns (bool) {
        return _receiversIsBlocked[user];
    }

    function _mint(address account, uint256 amount) internal override checkReceiver(account) {
        if (account == address(0)) revert ZeroAddress();
        super._mint(account, amount);
    }

    function approve(address spender, uint256 amount) public override checkSender(msg.sender) returns (bool) {
        return super.approve(spender, amount);
    }

    function transfer(address to, uint256 amount) public override checkTransferAmount(amount) checkSender(msg.sender) checkReceiver(to) returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override checkTransferAmount(amount) checkSender(from) checkReceiver(to) returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    //region modifiers

    modifier checkTransferAmount(uint256 amount) {
        if (amount > _maxTransferAmount) revert InvalidMaxTransferAmount(_maxTransferAmount);
        _;
    }

    modifier checkSender(address owner) {
        if (_sendersIsBlocked[owner]) revert SenderIsLock(owner);
        _;
    }

    modifier checkReceiver(address receiver) {
        if (_receiversIsBlocked[receiver]) revert ReceiverIsLock(receiver);
        _;
    }

    //endregion

    function version() public view override returns (uint8) {
        return _getInitializedVersion();
    }
}
