// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract SingleHopSwap {
    using SafeERC20 for IERC20;

    ISwapRouter public immutable router;

    IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    uint24 public poolFee = 3000; // 3000 / 10000 = 0.3% fee

    constructor(ISwapRouter _router) {
        router = _router;
    }

    function swapExactInputSingle(
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        DAI.safeTransferFrom(msg.sender, address(this), amountIn);

        DAI.approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(DAI),
                tokenOut: address(USDC),
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }

    function swapExactOutputSingle(
        uint256 amountOut,
        uint256 amountInMaximum
    ) external returns (uint256 amountIn) {
        DAI.safeTransferFrom(msg.sender, address(this), amountInMaximum);

        DAI.approve(address(router), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: address(DAI),
                tokenOut: address(USDC),
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = router.exactOutputSingle(params);

        if (amountIn < amountInMaximum) {
            DAI.approve(address(router), 0);
            DAI.safeTransfer(msg.sender, amountInMaximum - amountIn);
        }
    }
}
