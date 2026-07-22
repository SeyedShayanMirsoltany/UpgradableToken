// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import { Test } from "../../lib/forge-std/src/test.sol";
import "../../src/token/CLToken.sol";
import "../../src/token/CLToken2.sol";
import "@utils/CustomRoles.sol";
import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
contract Staking is Test {
    address private tokenOwner;
    address private stakingOwner;
    address private user3;
    address private user4;
    address private proxy;
    function setUp() public {
        tokenOwner = vm.addr(100);
        stakingOwner = vm.addr(200);
        user3 = vm.addr(300);
        user4 = vm.addr(400);

        vm.startPrank(tokenOwner);
        CLToken baseToken = new CLToken();
        bytes memory _data = abi.encodeCall(CLToken.initialize, ("Token", "tkn", 100 ether, 1 ether, tokenOwner));
        proxy = address(new ERC1967Proxy(address(baseToken), _data));
        vm.stopPrank();
    }

    function testNothing() public pure {
        assertTrue(1 == 1);
    }

    function _upgradeToken() internal {
        vm.startPrank(tokenOwner);
        CLToken2 baseToken = new CLToken2();
        bytes memory _data = abi.encodeCall(CLToken2.initialize2, (100 ether));
        CLToken(proxy).upgradeToAndCall(address(baseToken), _data);
        vm.stopPrank();
    }

    function _upgradeStaking() internal {
        vm.startPrank(tokenOwner);
        CLToken2 baseToken = new CLToken2();
        bytes memory _data = abi.encodeCall(CLToken2.initialize2, (100 ether));
        CLToken(proxy).upgradeToAndCall(address(baseToken), _data);
        vm.stopPrank();
    }
}
