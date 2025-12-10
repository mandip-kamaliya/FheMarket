// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library HookMiner {
    // 0x3FFF covers all standard v4 flags
    uint160 constant FLAG_MASK = 0x3FFF; 

    function find(
        address deployer,
        uint160 flags,
        bytes memory creationCode,
        bytes memory constructorArgs
    ) internal pure returns (address, bytes32) {
        bytes32 creationCodeHash = keccak256(abi.encodePacked(creationCode, constructorArgs));

        for (uint256 i = 0; i < 5000000; i++) {
            bytes32 salt = bytes32(i);
            address hookAddress = computeAddress(deployer, salt, creationCodeHash);
            
            // Strict check
            if ((uint160(hookAddress) & FLAG_MASK) == flags) {
                return (hookAddress, salt);
            }
        }
        revert("HookMiner: could not find salt");
    }

    function computeAddress(address deployer, bytes32 salt, bytes32 creationCodeHash) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            deployer,
            salt,
            creationCodeHash
        )))));
    }
}