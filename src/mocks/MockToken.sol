// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory _name , string memory _symbol) ERC20(_name,_symbol,18){
        _mint(msg.sender,1000000 * 1e18);
    }

    function mint(address _to , uint256 _amount) external{
        _mint(_to,_amount);
    }
}