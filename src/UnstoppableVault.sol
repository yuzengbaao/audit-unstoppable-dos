// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DamnValuableToken} from "./DamnValuableToken.sol";

import {IERC3156FlashBorrower, IERC3156FlashLender} from "./IERC3156.sol";

contract UnstoppableVault is IERC3156FlashLender {
    DamnValuableToken public asset;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    uint256 public constant FEE_FACTOR = 0.05 ether;
    uint64 public constant GRACE_PERIOD = 30 days;
    uint64 public immutable end;
    address public feeRecipient;
    
    error InvalidAmount(uint256 amount);
    error InvalidBalance();
    error CallbackFailed();
    error UnsupportedCurrency();
    
    event FeeRecipientUpdated(address indexed newFeeRecipient);

    constructor(DamnValuableToken _token, address _feeRecipient) {
        asset = _token;
        feeRecipient = _feeRecipient;
        end = uint64(block.timestamp) + GRACE_PERIOD;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    function deposit(uint256 amount, address receiver) external returns (uint256 shares) {
        asset.transferFrom(msg.sender, address(this), amount);
        shares = amount;
        balanceOf[receiver] += shares;
        totalSupply += shares;
    }

    function maxFlashLoan(address _token) public view returns (uint256) {
        if (address(asset) != _token) return 0;
        return totalAssets();
    }

    function flashFee(address _token, uint256 _amount) public view returns (uint256 fee) {
        if (address(asset) != _token) revert UnsupportedCurrency();
        if (block.timestamp < end && _amount < maxFlashLoan(_token)) return 0;
        return _amount * FEE_FACTOR / 1e18;
    }

    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        if (totalSupply == 0) return assets;
        return assets * totalSupply / totalAssets();
    }

    function flashLoan(IERC3156FlashBorrower receiver, address _token, uint256 amount, bytes calldata data) external returns (bool) {
        if (amount == 0) revert InvalidAmount(0);
        if (address(asset) != _token) revert UnsupportedCurrency();
        
        uint256 balanceBefore = totalAssets();
        if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance();

        asset.transfer(address(receiver), amount);
        
        uint256 fee = flashFee(_token, amount);
        if (receiver.onFlashLoan(msg.sender, address(asset), amount, fee, data) != keccak256("IERC3156FlashBorrower.onFlashLoan")) {
            revert CallbackFailed();
        }

        asset.transferFrom(address(receiver), address(this), amount + fee);
        asset.transfer(feeRecipient, fee);

        return true;
    }
}