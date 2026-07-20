// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import { Test } from "../../lib/forge-std/src/test.sol";
import "../../src/token/CLToken.sol";
import "../../src/token/CLToken2.sol";
import "../../src/token/CustomRoles.sol";
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

    function test_ApprovedSpenderCanTransferFrom() public {
        vm.startPrank(user1);
        uint256 user1Balance = CLToken(proxy).balanceOf(user1);
        CLToken(proxy).approve(user3, 1000 wei);
        vm.stopPrank();

        vm.startPrank(user3);
        CLToken(proxy).transferFrom(user1, user3, 1000 wei);
        vm.assertEq(CLToken(proxy).balanceOf(user3), 1000 wei);
        vm.assertEq(CLToken(proxy).balanceOf(user1), user1Balance - 1000 wei);
        vm.stopPrank();
    }

    function test_PauserCanPauseContract() public {
        vm.startPrank(user2);
        vm.expectRevert();
        CLToken(proxy).pause();
        vm.stopPrank();

        vm.startPrank(user1);
        CLToken(proxy).grantRole(PAUSER_ROLE, user2);
        vm.stopPrank();

        vm.startPrank(user2);
        CLToken(proxy).pause();
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert();
        CLToken(proxy).mint(user2, 1 ether);
        vm.stopPrank();
    }

    function test_RevertWhen_TransferWhilePaused() public {
        vm.startPrank(user1);
        CLToken(proxy).approve(user3, 1000 wei);
        CLToken(proxy).pause();
        vm.stopPrank();

        vm.startPrank(user3);
        vm.expectRevert();
        CLToken(proxy).transferFrom(user1, user3, 1000 wei);
        vm.stopPrank();
    }

    function testVersion() public {
        vm.startPrank(user1);
        vm.assertEq(CLToken(proxy).version(), 1);
        vm.stopPrank();
    }

    function testInitialOwnerIsZero() public {
        vm.startPrank(user2);
        CLToken baseToken2 = new CLToken();
        address proxy2;
        bytes memory _data = abi.encodeCall(CLToken.initialize, ("Token", "tkn", 10 ether, 1 ether, address(0)));
        vm.expectRevert(CLToken.InitialOwnerIsZero.selector);
        proxy2 = address(new ERC1967Proxy(address(baseToken2), _data));
        vm.stopPrank();
    }

    function test_Initialize_SetsInitialState() public {
        vm.startPrank(user1);
        vm.assertEq(CLToken(proxy).owner(), user1);
        vm.assertEq(CLToken(proxy).symbol(), "tkn");
        vm.assertEq(CLToken(proxy).totalSupply(), 1 ether);
        vm.assertEq(CLToken(proxy).name(), "Token");
        vm.assertEq(CLToken(proxy).cap(), 10 ether);
        vm.assertEq(CLToken(proxy).balanceOf(user1), 1 ether);
        vm.stopPrank();
    }

    function testInitialSupplyExceedsCap() public {
        vm.startPrank(user2);
        CLToken baseToken2 = new CLToken();
        address proxy2;
        bytes memory _data = abi.encodeCall(CLToken.initialize, ("Token", "tkn", 10 ether, 11 ether, user2));
        vm.expectRevert(CLToken.InitialSupplyExceedsCap.selector);

        proxy2 = address(new ERC1967Proxy(address(baseToken2), _data));
        vm.stopPrank();
    }

    function test_RevertWhen_InitializeCalledTwice() public {
        vm.startPrank(user2);
        CLToken baseToken2 = CLToken(proxy);
        vm.expectRevert();
        baseToken2.initialize("Token", "tkn", 10 ether, 11 ether, user2);
        vm.stopPrank();
    }

    function test_RevertWhen_ImplementationIsInitializedDirectly() public {}

    function test_UpgradePreservesExistingState() public {}

    function test_MinterCanMint() public {}

    function test_RevertWhen_NonAdminUpgrades() public {
        vm.startPrank(user2);
        CLToken2 baseToken = new CLToken2();
        bytes memory _data = abi.encodeCall(CLToken2.initialize2, (100 ether));
        vm.expectRevert();
        CLToken(proxy).upgradeToAndCall(address(baseToken), _data);
        vm.stopPrank();
    }
    function test_AdminCanUpgradeToV2() public {
        vm.startPrank(user1);
        CLToken2 baseToken = new CLToken2();
        bytes memory _data = abi.encodeCall(CLToken2.initialize2, (100 ether));
        CLToken(proxy).upgradeToAndCall(address(baseToken), _data);
        vm.assertEq(CLToken(proxy).version(), 2);
        vm.stopPrank();
    }
}
