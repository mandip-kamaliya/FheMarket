// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/utils/BaseHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol"; // Latest Import Path
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {BeforeSwapDelta} from "v4-core/types/BeforeSwapDelta.sol";
import {FHE, euint128, inEuint128, ebool} from "@fhenixprotocol/FHE.sol";

contract FheMarketHook is BaseHook {
    
    // --- STATE VARIABLES ---
    mapping(address => euint128) internal _eUSDC;
    mapping(bytes32 => mapping(uint8 => mapping(address => euint128))) internal _outcomeBalances;

    euint128 internal eZERO;
    euint128 internal eONE;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
        eZERO = FHE.asEuint128(0);
        eONE = FHE.asEuint128(1);
        
        // ✅ FIXED: "allowThis" -> "allow(val, address(this))"
        FHE.allow(eZERO, address(this));
        FHE.allow(eONE, address(this));
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
        
        // ✅ FIXED: Use standard allow
        FHE.allow(_eUSDC[msg.sender], address(this));
        FHE.allow(_eUSDC[msg.sender], msg.sender);
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

        // 1. Check Balance
        ebool hasFunds = FHE.gte(_eUSDC[msg.sender], amount);
        euint128 validAmount = FHE.select(hasFunds, amount, eZERO);

        // 2. Deduct USDC
        _eUSDC[msg.sender] = FHE.sub(_eUSDC[msg.sender], validAmount);

        // 3. Mint & Swap Logic
        euint128 totalLeverage = FHE.add(validAmount, validAmount); 
        euint128 finalYes = FHE.select(isYes, totalLeverage, eZERO);
        euint128 finalNo  = FHE.select(isYes, eZERO, totalLeverage);

        // 4. Update Balances
        _outcomeBalances[poolId][0][msg.sender] = FHE.add(_outcomeBalances[poolId][0][msg.sender], finalYes);
        _outcomeBalances[poolId][1][msg.sender] = FHE.add(_outcomeBalances[poolId][1][msg.sender], finalNo);

        // 5. Permissions
        FHE.allow(_eUSDC[msg.sender], address(this));
        FHE.allow(_eUSDC[msg.sender], msg.sender);
        
        // Grant permissions for YES outcome
        FHE.allow(_outcomeBalances[poolId][0][msg.sender], address(this));
        FHE.allow(_outcomeBalances[poolId][0][msg.sender], msg.sender);
        
        // Grant permissions for NO outcome
        FHE.allow(_outcomeBalances[poolId][1][msg.sender], address(this));
        FHE.allow(_outcomeBalances[poolId][1][msg.sender], msg.sender);
    }

    function beforeInitialize(address, PoolKey calldata, uint160 sqrtPriceX96, bytes calldata)
        external override returns (bytes4)
    {
        require(sqrtPriceX96 == Constants.SQRT_PRICE_1_1, "Must start at 50%");
        return BaseHook.beforeInitialize.selector;
    }

    // ✅ FIXED: Correct Return Signature (bytes4, BeforeSwapDelta, uint24)
    function beforeSwap(address, PoolKey calldata, SwapParams calldata, bytes calldata)
        external override returns (bytes4, BeforeSwapDelta, uint24)
    {
        revert("Use swapEncrypted()");
    }
}