// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol"; 

contract BaseTest is Test, Deployers {
    
    function deployArtifactsAndLabel() internal {
        deployFreshManagerAndRouters();
        vm.label(address(manager), "PoolManager");
        vm.label(address(swapRouter), "SwapRouter");
        vm.label(address(modifyLiquidityRouter), "ModifyLiquidityRouter");
    }

    // ✅ FIXED: Renamed function to avoid conflict with parent contract
    // Removed 'override' keyword
    function deployMintAndApprove2CurrenciesMock() internal returns (Currency, Currency) {
        MockERC20 token0 = new MockERC20("TestA", "A", 18);
        MockERC20 token1 = new MockERC20("TestB", "B", 18);
        
        token0.mint(address(this), 1000 ether);
        token1.mint(address(this), 1000 ether);

        (currency0, currency1) = SortTokens(address(token0), address(token1));

        vm.label(Currency.unwrap(currency0), "Currency0");
        vm.label(Currency.unwrap(currency1), "Currency1");
        
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency0)).approve(address(modifyLiquidityRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(modifyLiquidityRouter), type(uint256).max);

        return (currency0, currency1);
    }

    function SortTokens(address tokenA, address tokenB) internal pure returns (Currency, Currency) {
        if (tokenA < tokenB) {
            return (Currency.wrap(tokenA), Currency.wrap(tokenB));
        } else {
            return (Currency.wrap(tokenB), Currency.wrap(tokenA));
        }
    }
}