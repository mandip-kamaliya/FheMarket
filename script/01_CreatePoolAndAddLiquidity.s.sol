// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";

import {MockToken} from "src/mocks/MockToken.sol";
import {FheMarketHook} from "src/FheMarketHook.sol";
import {HookMiner} from "test/utils/HookMiner.sol";

contract CreatePoolAndAddLiquidity is Script, Deployers {
    function run() external {
        vm.startBroadcast();

        deployFreshManagerAndRouters();
        console.log("PoolManager Deployed at:", address(manager));

        MockToken tokenA = new MockToken("YES Token", "YES");
        MockToken tokenB = new MockToken("NO Token", "NO");

        (Currency currency0, Currency currency1) = address(tokenA) < address(tokenB)
            ? (Currency.wrap(address(tokenA)), Currency.wrap(address(tokenB)))
            : (Currency.wrap(address(tokenB)), Currency.wrap(address(tokenA)));

        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | 
            Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG |
            Hooks.BEFORE_INITIALIZE_FLAG
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(FheMarketHook).creationCode,
            abi.encode(manager)
        );
        console.log("Mined Hook Address:", hookAddress);

        FheMarketHook hook = new FheMarketHook{salt: salt}(manager);
        console.log("Hook Deployed at:", address(hook));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        // ✅ FIXED: Removed the 3rd argument (hookData)
        manager.initialize(key, Constants.SQRT_PRICE_1_1);
        console.log("Pool Initialized successfully!");

        vm.stopBroadcast();
    }
}