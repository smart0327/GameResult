// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract Stash is UUPSUpgradeable, ERC20Upgradeable, OwnableUpgradeable  {
    function initialize() external initializer {
        __ERC20_init("Stash", "STH");
        __Ownable_init(msg.sender);
        _mint(msg.sender, 300_000_000 * 1e18);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}


