// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Stash} from "../src/token/Stash.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {stdJson} from "forge-std/Test.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address proxy = Upgrades.deployUUPSProxy(
            "Stash.sol",
            abi.encodeCall(Stash.initialize, ())
        );
        address implementation = Upgrades.getImplementationAddress(proxy);
        console.log("proxy address:", proxy);
        console.log("implementation address:", proxy);
        vm.stopBroadcast();
    }
}

// contract UpgradeScript is Script {
//     using stdJson for string;
//     function setUp() public {}

//     function run(string memory input) external {
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         string memory json = readInput(input);
//         address proxy = address(bytes20(bytes(json.readString("StashProxy"))));        
//         console.log("proxy address", proxy);
//         vm.startBroadcast(deployerPrivateKey);
//         Upgrades.upgradeProxy(proxy, "StashV2.sol", abi.encodeCall(StashV2.initialize, ()));
//         newImplementation = Upgrades.getImplementationAddress(proxy);
//         vm.stopBroadcast();
//     }

//     function readInput(string memory input) internal returns (string memory) {
//         string memory inputDir = string.concat(
//             vm.projectRoot(),
//             "/script/input/"
//         );
//         string memory chainDir = string.concat(vm.toString(block.chainid), "/");
//         string memory file = string.concat(input, ".json");
//         return vm.readFile(string.concat(inputDir, chainDir, file));
//     }
// }