// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.5;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

contract FlashSwap is IUniswapV3FlashCallback {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeERC20 for IERC20;

    IUniswapV3Pool public pool;
    IERC20 public token0;
    IERC20 public token1;

    constructor(IUniswapV3Pool _pool) {
        pool = _pool;
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool), "not authorized");

        FlashCallbackData memory decoded = abi.decode(
            data,
            (FlashCallbackData)
        );

        // write custom code here in this block
        uint token0Bal = token0.balanceOf(address(this));
        console.log("Contract - Token 0 Balance: ", token0Bal / 1e18);
        uint token1Bal = token1.balanceOf(address(this));
        console.log("Contract - Token 1 Balance: ", token1Bal / 1e6);

        // payback to the pool
        uint256 amount0Owed = LowGasSafeMath.add(decoded.amount0, fee0);
        uint256 amount1Owed = LowGasSafeMath.add(decoded.amount1, fee1);

        // collect fee from the user
        if (fee0 > 0)
            token0.safeTransferFrom(decoded.payer, address(this), fee0);

        if (fee1 > 0)
            token1.safeTransferFrom(decoded.payer, address(this), fee1);

        if (amount0Owed > 0) token0.safeTransfer(address(pool), amount0Owed);
        if (amount1Owed > 0) token1.safeTransfer(address(pool), amount1Owed);
    }

    struct FlashCallbackData {
        uint256 amount0;
        uint256 amount1;
        address payer;
    }

    function initFlash(uint amount0, uint amount1) external {
        bytes memory data = abi.encode(
            FlashCallbackData({
                amount0: amount0,
                amount1: amount1,
                payer: msg.sender
            })
        );

        pool.flash(address(this), amount0, amount1, data);
    }
}
