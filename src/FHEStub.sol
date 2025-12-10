// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

type euint128 is uint256;
type inEuint128 is uint256;
type ebool is bool;

library FHE {
    // 1. Casts
    function asEuint128(uint256 value) internal pure returns (euint128) { return euint128.wrap(value); }
    function asEuint128(inEuint128 value) internal pure returns (euint128) { return euint128.wrap(inEuint128.unwrap(value)); }

    // 2. Math
    function add(euint128 a, euint128 b) internal pure returns (euint128) { return euint128.wrap(euint128.unwrap(a) + euint128.unwrap(b)); }
    function sub(euint128 a, euint128 b) internal pure returns (euint128) { return euint128.wrap(euint128.unwrap(a) - euint128.unwrap(b)); }
    
    // 3. Logic (Added 'eq' here)
    function gte(euint128 a, euint128 b) internal pure returns (ebool) { return ebool.wrap(euint128.unwrap(a) >= euint128.unwrap(b)); }
    function eq(euint128 a, euint128 b) internal pure returns (ebool) { return ebool.wrap(euint128.unwrap(a) == euint128.unwrap(b)); }
    
    function select(ebool condition, euint128 ifTrue, euint128 ifFalse) internal pure returns (euint128) { return ebool.unwrap(condition) ? ifTrue : ifFalse; }

    // 4. Decrypt (For assertions)
    function decrypt(ebool value) internal pure returns (bool) { return ebool.unwrap(value); }
}