// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/utils/BaseHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
// Ensure this import matches what BaseHook expects (PoolOperation)
import {SwapParams} from "v4-core/types/PoolOperation.sol"; 
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";
import {FHE, euint128, inEuint128, ebool} from "@fhenixprotocol/FHE.sol";

contract FheMarketHook is BaseHook {
    
    // --- STATE ---
    mapping(address => euint128) internal _eUSDC;
    mapping(bytes32 => mapping(uint8 => mapping(address => euint128))) internal _outcomeBalances;

    euint128 internal eZERO;
    euint128 internal eONE;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
        eZERO = FHE.asEuint128(0);
        eONE = FHE.asEuint128(1);
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true, 
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: true,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // --- DEPOSIT ---
    function depositShielded(inEuint128 calldata encryptedAmount) public {
        euint128 amount = FHE.asEuint128(encryptedAmount);
        _eUSDC[msg.sender] = FHE.add(_eUSDC[msg.sender], amount);
    }

    // --- ENCRYPTED SWAP ---
    function swapEncrypted(
        PoolKey calldata key, 
        inEuint128 calldata encryptedAmount, 
        inEuint128 calldata encryptedIsYes
    ) external {
        euint128 amount = FHE.asEuint128(encryptedAmount);
        euint128 isYesUint = FHE.asEuint128(encryptedIsYes);
        ebool isYes = FHE.eq(isYesUint, eONE);

        bytes32 poolId = keccak256(abi.encode(key));

        ebool hasFunds = FHE.gte(_eUSDC[msg.sender], amount);
        euint128 validAmount = FHE.select(hasFunds, amount, eZERO);

        _eUSDC[msg.sender] = FHE.sub(_eUSDC[msg.sender], validAmount);

        euint128 totalLeverage = FHE.add(validAmount, validAmount); 
        euint128 finalYes = FHE.select(isYes, totalLeverage, eZERO);
        euint128 finalNo  = FHE.select(isYes, eZERO, totalLeverage);

        _outcomeBalances[poolId][0][msg.sender] = FHE.add(_outcomeBalances[poolId][0][msg.sender], finalYes);
        _outcomeBalances[poolId][1][msg.sender] = FHE.add(_outcomeBalances[poolId][1][msg.sender], finalNo);
    }

    // --- HOOKS ---
    
    // ✅ FIX 1: Removed 'override' (Because BaseHook likely doesn't have this virtual function)
    // Kept as 'external' to match the Interface requirement
    function beforeInitialize(address, PoolKey calldata, uint160 sqrtPriceX96, bytes calldata)
        external pure returns (bytes4)
    {
        require(sqrtPriceX96 == Constants.SQRT_PRICE_1_1, "Must start at 50%");
        return BaseHook.beforeInitialize.selector;
    }

    // ✅ FIX 2: Changed to '_beforeSwap' (Internal Override)
    // This hooks into the BaseHook wrapper correctly
    function _beforeSwap(address, PoolKey calldata, SwapParams calldata, bytes calldata)
        internal pure override returns (bytes4, BeforeSwapDelta, uint24)
    {
        revert("Use swapEncrypted()");
    }
}