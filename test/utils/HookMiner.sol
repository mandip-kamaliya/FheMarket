// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Hooks} from "v4-core/libraries/Hooks.sol";

library HookMiner {
    function find(
        address deployer,
        uint160 flags,
        bytes memory creationCode,
        bytes memory constructorArgs
    ) internal pure returns (address, bytes32) {
        address hookAddress;
        bytes32 salt;

        for (uint256 i = 0; i < 20000; i++) {
            salt = bytes32(i);
            hookAddress = computeAddress(deployer, salt, creationCode, constructorArgs);
            
            if (uint160(hookAddress) & Hooks.ALL_HOOK_MASK == flags) {
                return (hookAddress, salt);
            }
        }
        revert("HookMiner: could not find salt");
    }

    function computeAddress(
        address deployer,
        bytes32 salt,
        bytes memory creationCode,
        bytes memory constructorArgs
    ) internal pure returns (address) {
        bytes32 bytecodeHash = keccak256(abi.encodePacked(creationCode, constructorArgs));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(hash)));
    }
}