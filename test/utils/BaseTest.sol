// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol"; 

contract BaseTest is Test, Deployers {
    // Helper to label addresses for easier debugging in Foundry logs
    function deployArtifactsAndLabel() internal {
        // 1. Deploy the Manager and Routers using the official helper
        deployFreshManagerAndRouters();

        // 2. Label the addresses so logs show "PoolManager" instead of "0x123..."
        vm.label(address(manager), "PoolManager");
        vm.label(address(swapRouter), "SwapRouter");
        vm.label(address(modifyLiquidityRouter), "ModifyLiquidityRouter");
    }

    // Override the currency deployment to use our Solmate MockERC20
    // (The official Deployers might use a different MockToken, but this ensures compatibility)
    function deployMintAndApprove2Currencies() internal override returns (Currency, Currency) {
        MockERC20 token0 = new MockERC20("TestA", "A", 18);
        MockERC20 token1 = new MockERC20("TestB", "B", 18);
        
        // Mint tokens to the test contract (address(this))
        token0.mint(address(this), 1000 ether);
        token1.mint(address(this), 1000 ether);

        // Sort them to satisfy Uniswap requirement (Token0 < Token1)
        (currency0, currency1) = SortTokens(address(token0), address(token1));

        // Label them
        vm.label(Currency.unwrap(currency0), "Currency0");
        vm.label(Currency.unwrap(currency1), "Currency1");
        
        // Approve the router to spend them
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency0)).approve(address(modifyLiquidityRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(modifyLiquidityRouter), type(uint256).max);

        return (currency0, currency1);
    }

    // Helper to sort tokens by address
    function SortTokens(address tokenA, address tokenB) internal pure returns (Currency, Currency) {
        if (tokenA < tokenB) {
            return (Currency.wrap(tokenA), Currency.wrap(tokenB));
        } else {
            return (Currency.wrap(tokenB), Currency.wrap(tokenA));
        }
    }
}