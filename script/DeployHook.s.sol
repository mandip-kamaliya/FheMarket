// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {HookMiner} from "test/utils/HookMiner.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {FheMarketHook} from "src/FheMarketHook.sol";

contract DeployHook is Script {
    function run() external {
        // 1. Setup
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        vm.startBroadcast(deployerPrivateKey);

        // 2. Mock a PoolManager (for simulation) or use existing one
        IPoolManager manager = new PoolManager(address(0));

        // 3. Mine the Salt (Proof of Work for Hook Address)
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG);
        (address hookAddr, bytes32 salt) = HookMiner.find(
            vm.addr(deployerPrivateKey),
            flags,
            type(FheMarketHook).creationCode,
            abi.encode(manager)
        );

        // 4. Deploy
        FheMarketHook hook = new FheMarketHook{salt: salt}(manager);
       // require(address(hook) == hookAddr, "Hook address mismatch");

        console.log("----------------------------------");
        console.log(" FheMarketHook Deployed");
        console.log("Address:", address(hook));
        console.log("Manager:", address(manager));
        console.log("Flags:  ", flags);
        console.log("----------------------------------");

        vm.stopBroadcast();
    }
}