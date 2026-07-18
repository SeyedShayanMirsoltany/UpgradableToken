// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "../../lib/forge-std/src/test.sol";
import "../../src/token/CLToken.sol";
import "../../src/token/CLToken2.sol";
import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
contract CLTokenUUPS is Test {
    address private user1;
    address private user2;
    address private user3;
    address private user4;
    address private proxy;
    function setUp() public {}

    constructor() {
        user1 = vm.addr(100);
        user2 = vm.addr(200);
        user3 = vm.addr(300);
        user4 = vm.addr(400);

        vm.startPrank(user1);
        CLToken baseToken = new CLToken();
        bytes memory _data = abi.encodeCall(CLToken.initialize, ("Token", "tkn", 10 ether, 1 ether, user1));
        proxy = address(new ERC1967Proxy(address(baseToken), _data));
        vm.stopPrank();
    }

    function testInitialOwnerNotZero() public {
        vm.startPrank(user2);
        CLToken baseToken2 = new CLToken();
        address proxy2;
        bytes memory _data = abi.encodeCall(CLToken.initialize, ("Token", "tkn", 10 ether, 1 ether, address(0)));
        vm.expectRevert(CLToken.InitialOwnerNotZero.selector);
        proxy2 = address(new ERC1967Proxy(address(baseToken2), _data));
        vm.stopPrank();
    }

    function testInitialOwner() public {
        vm.startPrank(user1);
        address owner = CLToken(proxy).owner();
        vm.assertEq(owner, user1);
        vm.stopPrank();
    }

    function testNothing() public {
        vm.startPrank(user1);
        uint256 balance = CLToken(proxy).balanceOf(user1);
        vm.assertEq(balance, 1 ether);
        vm.stopPrank();
    }

    function testInitialSupplyLessThanCap() public {
        vm.startPrank(user2);
        CLToken baseToken2 = new CLToken();
        address proxy2;
        bytes memory _data = abi.encodeCall(CLToken.initialize, ("Token", "tkn", 10 ether, 11 ether, user2));
        vm.expectRevert(CLToken.InitialSupplyLessThanCap.selector);
        proxy2 = address(new ERC1967Proxy(address(baseToken2), _data));
        vm.stopPrank();
    }

    function testVersion() public {
        vm.startPrank(user1);
        vm.assertEq(CLToken(proxy).version(), 1);
        vm.stopPrank();
    }

    function testVersion2() public {
        vm.startPrank(user1);
        CLToken2 baseToken = new CLToken2();
        bytes memory _data = abi.encodeCall(CLToken2.initialize2, ());
        CLToken(proxy).upgradeToAndCall(address(baseToken), _data);
        vm.assertEq(CLToken(proxy).version(), 2);
        vm.stopPrank();
    }
}
