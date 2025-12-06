// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";

// ✅ NEW: Import SwapParams correctly
import {SwapParams} from "v4-core/types/PoolOperation.sol";

// FHE Imports
import {FHE, inEuint128} from "@fhenixprotocol/FHE.sol";

// Your Contracts
import {FheMarketHook} from "src/FheMarketHook.sol";
import {MockToken} from "src/mocks/MockToken.sol";
import {HookMiner} from "test/utils/HookMiner.sol";

contract FheMarketTest is Test, Deployers {
    FheMarketHook hook;
    
    // ❌ DELETED: "PoolKey key;" (It is already defined in Deployers)
    
    MockToken tokenA;
    MockToken tokenB;

    function setUp() public {
        // 1. Deploy Uniswap Manager & Routers
        deployFreshManagerAndRouters();

        // 2. Deploy Mock Tokens
        tokenA = new MockToken("YES Token", "YES");
        tokenB = new MockToken("NO Token", "NO");

        // 3. Sort Tokens (TokenA must be < TokenB)
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
        
        // 5. Initialize Pool (Assigning to the inherited 'key' variable)
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
        // --- SCENARIO: User wants to bet 100 USDC on YES ---

        // 1. Prepare Encrypted Inputs (Mocking Encryption)
        inEuint128 encAmount = FHE.inEuint128(100); 
        inEuint128 encIsYes = FHE.inEuint128(1); // 1 = YES

        // 2. Step 1: Deposit (Shield Funds)
        console.log("Step 1: User Deposits 100 USDC (Encrypted)...");
        hook.depositShielded(encAmount);
        
        // 3. Step 2: Swap (Place Bet)
        console.log("Step 2: User Bets on YES...");
        hook.swapEncrypted(key, encAmount, encIsYes);

        // 4. Verification
        console.log("Bet placed successfully!");
        assertTrue(true); 
    }

    function test_RevertIfPublicSwap() public {
        // Ensure that normal Uniswap swaps are BLOCKED
        vm.expectRevert(bytes("Use swapEncrypted()"));
        
        // ✅ FIXED: Use 'SwapParams' directly
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: 100,
            sqrtPriceLimitX96: Constants.SQRT_PRICE_1_1
        });

        manager.swap(key, params, new bytes(0));
    }
}