// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UnstoppableVault, IERC3156FlashBorrower} from "./UnstoppableVault.sol";
import {DamnValuableToken} from "./DamnValuableToken.sol";

contract UnstoppableMonitor {
    UnstoppableVault private vault;
    address public owner;
    bool public paused;
    
    error UnexpectedFlashLoan();
    
    event FlashLoanStatus(bool success);

    constructor(address _vault) {
        vault = UnstoppableVault(_vault);
        owner = msg.sender;
    }

    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata) external returns (bytes32) {
        if (initiator != address(this) || msg.sender != address(vault) || token != address(vault.asset()) || fee != 0) {
            revert UnexpectedFlashLoan();
        }
        DamnValuableToken(token).approve(address(vault), amount);
        return keccak256("IERC3156FlashBorrower.onFlashLoan");
    }

    function checkFlashLoan(uint256 amount) external {
        require(msg.sender == owner, "Only owner");
        require(amount > 0, "Amount must be > 0");
        
        address asset = address(vault.asset());
        
        try vault.flashLoan(this, asset, amount, bytes("")) {
            emit FlashLoanStatus(true);
        } catch {
            emit FlashLoanStatus(false);
            paused = true;
        }
    }
}