// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DACXI is ERC20 {
    constructor() ERC20("DACXI", "DACXI") {
        _mint(msg.sender, 10e9 * 1e18);
    }
}
