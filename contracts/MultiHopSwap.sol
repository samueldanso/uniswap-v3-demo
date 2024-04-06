// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract MultiHopSwap {
    using SafeERC20 for IERC20;

    ISwapRouter public immutable router;

    IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant WETH9 = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint24 public constant poolFee = 3000; // 3000 / 1000 = 0.3%

    constructor(ISwapRouter _router) {
        router = _router;
    }

    function swapExactInputMultihop(
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        DAI.safeTransferFrom(msg.sender, address(this), amountIn);
        DAI.approve(address(router), amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(DAI, poolFee, USDC, poolFee, WETH9),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        amountOut = router.exactInput(params);
    }

    function swapExactOutputMultihop(
        uint256 amountOut,
        uint256 amountInMaximum
    ) external returns (uint256 amountIn) {
        DAI.safeTransferFrom(msg.sender, address(this), amountInMaximum);
        DAI.approve(address(router), amountInMaximum);

        ISwapRouter.ExactOutputParams memory params = ISwapRouter
            .ExactOutputParams({
                path: abi.encodePacked(WETH9, poolFee, USDC, poolFee, DAI),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum
            });

        amountIn = router.exactOutput(params);

        if (amountIn < amountInMaximum) {
            DAI.safeTransfer(msg.sender, amountInMaximum - amountIn);
        }
    }
}
