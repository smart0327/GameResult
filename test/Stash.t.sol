// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Stash} from "src/token/Stash.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract StashTest is Test {
    address owner;
    Stash stashContract;

    function setUp() public {
        owner = makeAddr("owner");
    }

    function testDeployAndInitialize() public {
        vm.startPrank(owner);
        address implementation = address(new Stash());
        bytes memory data = abi.encodeCall(Stash.initialize, ());
        address proxy = address(new ERC1967Proxy(implementation, data));
        stashContract = Stash(proxy);        
        vm.stopPrank();

        assert(stashContract.balanceOf(owner) == 300_000_000 * 1e18);
    }
}