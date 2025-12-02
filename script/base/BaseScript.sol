// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Deployers} from "../../test/utils/Deployers.sol"; // Use our local clean deployer

contract BaseScript is Script, Deployers {
    function setUp() public {
        // Deploy the Uniswap V4 PoolManager
        deployFreshManager(); 
    }
}