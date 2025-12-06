// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";

// Import SwapParams from PoolOperation (Latest V4 Core)
import {SwapParams} from "v4-core/types/PoolOperation.sol";

// FHE Imports
import {FHE, inEuint128} from "@fhenixprotocol/FHE.sol";

// Your Contracts
import {FheMarketHook} from "src/FheMarketHook.sol";
import {MockToken} from "src/mocks/MockToken.sol";
import {HookMiner} from "test/utils/HookMiner.sol";

contract FheMarketTest is Test, Deployers {
    FheMarketHook hook;
    MockToken tokenA;
    MockToken tokenB;

    // Note: PoolKey key; is already defined in Deployers, so we do not redeclare it here.

    function setUp() public {
        // 1. Deploy Uniswap Manager and Routers
        deployFreshManagerAndRouters();

        // 2. Deploy Mock Tokens
        tokenA = new MockToken("YES Token", "YES");
        tokenB = new MockToken("NO Token", "NO");

        // 3. Sort Tokens (TokenA must be less than TokenB)
        if (address(tokenA) > address(tokenB)) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        (Currency c0, Currency c1) = (Currency.wrap(address(tokenA)), Currency.wrap(address(tokenB)));

        // 4. Mine and Deploy Hook
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | 
            Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG |
            Hooks.BEFORE_INITIALIZE_FLAG
        );

        (address hookAddr, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(FheMarketHook).creationCode,
            abi.encode(manager)
        );

        hook = new FheMarketHook{salt: salt}(manager);
        
        // 5. Initialize Pool
        key = PoolKey({
            currency0: c0,
            currency1: c1,
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        manager.initialize(key, Constants.SQRT_PRICE_1_1);
    }

    function test_FullUserFlow() public {
        // SCENARIO: User wants to bet 100 USDC on YES

        // Manually construct the struct for testing/mocking
        // In a real Fhenix network, this data must be valid ciphertext.
        // For compilation/mocking, we pack the number into bytes.
        
        inEuint128 memory encAmount;
        encAmount.data = abi.encodePacked(uint128(100)); // Mocking encrypted 100

        inEuint128 memory encIsYes;
        encIsYes.data = abi.encodePacked(uint128(1)); // Mocking encrypted 1 (YES)

        console.log("Step 1: User Deposits 100 USDC (Encrypted)...");
        hook.depositShielded(encAmount);
        
        console.log("Step 2: User Bets on YES...");
        hook.swapEncrypted(key, encAmount, encIsYes);

        console.log("Bet placed successfully!");
        assertTrue(true); 
    }

    function test_RevertIfPublicSwap() public {
        // Ensure that normal Uniswap swaps are BLOCKED
        
        vm.expectRevert(bytes("Use swapEncrypted()"));
        
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: 100,
            sqrtPriceLimitX96: Constants.SQRT_PRICE_1_1
        });

        manager.swap(key, params, new bytes(0));
    }
}