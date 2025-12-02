// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// We inherit from the official v4-core deployers instead of Hookmate
import {Deployers as CoreDeployers} from "@uniswap/v4-core/test/utils/Deployers.sol";

contract Deployers is CoreDeployers {
    // This wrapper allows your scripts to use the standard "Deployers" name
    // while using the clean v4-core logic under the hood.
}