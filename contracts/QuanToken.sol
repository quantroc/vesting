pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract QuanToken is ERC20 {
    constructor() ERC20("QuanToken","QTK") public {
        _mint(msg.sender, 1000000 * (10 ** decimals()));
    }
}