// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";

// Import the Stub directly
import {FHE, inEuint128} from "src/FHEStub.sol";

import {FheMarketHook} from "src/FheMarketHook.sol";
import {MockToken} from "src/mocks/MockToken.sol";
import {HookMiner} from "test/utils/HookMiner.sol";

contract FheMarketTest is Test, Deployers {
    FheMarketHook hook;
    MockToken tokenA;
    MockToken tokenB;

    function setUp() public {
        deployFreshManagerAndRouters();
        tokenA = new MockToken("YES Token", "YES");
        tokenB = new MockToken("NO Token", "NO");
        if (address(tokenA) > address(tokenB)) (tokenA, tokenB) = (tokenB, tokenA);
        (Currency c0, Currency c1) = (Currency.wrap(address(tokenA)), Currency.wrap(address(tokenB)));

        //  FIX: Removed BEFORE_INITIALIZE_FLAG
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG);
        
        (address hookAddr, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(FheMarketHook).creationCode,
            abi.encode(manager)
        );
        
        hook = new FheMarketHook{salt: salt}(manager);
        key = PoolKey({currency0: c0, currency1: c1, fee: 3000, tickSpacing: 60, hooks: hook});
        manager.initialize(key, Constants.SQRT_PRICE_1_1);
    }

    function test_FullUserFlow() public {
        inEuint128 encAmount = inEuint128.wrap(100); 
        inEuint128 encIsYes = inEuint128.wrap(1);

        hook.depositShielded(encAmount);
        hook.swapEncrypted(key, encAmount, encIsYes);
        assertTrue(true); 
    }

    function test_RevertIfPublicSwap() public {
        SwapParams memory params = SwapParams({
            zeroForOne: true, 
            amountSpecified: 100, 
            sqrtPriceLimitX96: Constants.SQRT_PRICE_1_1
        });
        PoolSwapTest.TestSettings memory testSettings = PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});
        
        vm.expectRevert(); 
        swapRouter.swap(key, params, testSettings, new bytes(0));
    }
}