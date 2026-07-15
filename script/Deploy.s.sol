// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "../lib/forge-std/src/Script.sol";
import "../src/token/CLToken.sol";
import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() public {
        address deployer = 0x38c30A38cbD6fD5333eb70eDA32078e51e7E3009;
        vm.startBroadcast(deployer);
        CLToken newToken = new CLToken();
        bytes memory _data = abi.encodeCall(CLToken.initialize, ("UpgradableToken", "UGT", 1000000 ether, 100 ether, deployer));
        address proxy = address(new ERC1967Proxy(address(newToken), _data));
        console.log("deployer : ", deployer);
        console.log("proxy : ", proxy);
        vm.stopBroadcast();
    }
}

// == Logs ==
//   proxy :  0x95511296fcb546d379e31C9FD8BA30ebcFCC2Ff6

// forge script script/Deploy.s.sol --rpc-url $env:RPC_SEPOLIA --private-key $env:PRIVATE_KEY --broadcast --verify
//Link Polygon // cast send 0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904 "transfer(address,uint256)" 0x6d20C71725068860fD0536E3e6101b6e4C4a5598 1000000000000000000 --rpc-url $env:RPC_POLYGON --private-key $env:PRIVATE_KEY
//Link Sepolia // cast send 0x779877A7B0D9E8603169DdbD7836e478b4624789 "transfer(address,uint256)" 0x9B2e17BFaa54E03a20e97b65E2f18810dc7E0826  2000000000000000000 --rpc-url $env:RPC_SEPOLIA --private-key $env:PRIVATE_KEY
//cast send 0xB3e71B5B930607e3E10c5c8A591bCC6D59b93CaF "mint(address,uint256)" 0x38c30a38cbd6fd5333eb70eda32078e51e7e3009 200000000000000000000000000 --rpc-url $env:RPC_SEPOLIA --private-key $env:PRIVATE_KEY
//cast call 0x95511296fcb546d379e31C9FD8BA30ebcFCC2Ff6 "balanceOf(address)" 0x38c30a38cbd6fd5333eb70eda32078e51e7e3009 --rpc-url $env:RPC_SEPOLIA
//cast call 0x95511296fcb546d379e31C9FD8BA30ebcFCC2Ff6 "version()" --rpc-url $env:RPC_SEPOLIA
