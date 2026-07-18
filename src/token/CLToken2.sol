// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./CLToken.sol";

contract CLToken2 is CLToken {
    error SenderIsLock(address user);
    error ReceiverIsLock(address user);

    mapping(address sender => bool isLocked) private _sendersIsBlocked;
    mapping(address receiver => bool isLocked) private _receiversIsBlocked;
    function initialize2() public reinitializer(2) {}

    function modifySender(address sender, bool islocked) public onlyOwner {
        _sendersIsLocked[sender] = islocked;
    }

    function modifyReceiver(address receiver, bool islocked) public onlyOwner {
        _receiversIsLocked[receiver] = islocked;
    }

    function getSenderLockStatus(address user) public view returns (bool) {
        return _sendersIsLocked[user];
    }

    function getReceiverLockStatus(address user) public view returns (bool) {
        return _receiversIsLocked[user];
    }

    function _mint(address account, uint256 amount) internal override checkReceiver(account) {
        super._mint(account, amount);
    }

    function approve(address spender, uint256 amount) public override checkSender(msg.sender) checkReceiver(spender) returns (bool) {
        return super.approve(spender, amount);
    }

    function transfer(address to, uint256 amount) public override checkSender(msg.sender) checkReceiver(to) returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override checkSender(from) checkReceiver(to) returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    //region modifiers

    modifier checkSender(address owner) {
        owner = owner == address(0) ? msg.sender : owner;
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
