// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract LiquidityContract is IERC721Receiver {
    using SafeERC20 for IERC20;

    IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    uint24 public constant poolFee = 100; // 100 / 10000 = 0.01%

    INonfungiblePositionManager public immutable positionManager;

    constructor(INonfungiblePositionManager manager) {
        positionManager = manager;
    }

    function mint(
        uint amount0,
        uint amount1
    )
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0Deposited,
            uint256 amount1Deposited
        )
    {
        DAI.safeTransferFrom(msg.sender, address(this), amount0);
        USDC.safeTransferFrom(msg.sender, address(this), amount1);

        DAI.approve(address(positionManager), amount0);
        USDC.approve(address(positionManager), amount1);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: address(DAI),
                token1: address(USDC),
                fee: poolFee,
                tickLower: TickMath.MIN_TICK,
                tickUpper: TickMath.MAX_TICK,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: msg.sender,
                deadline: block.timestamp
            });

        (
            tokenId,
            liquidity,
            amount0Deposited,
            amount1Deposited
        ) = positionManager.mint(params);

        if (amount0Deposited < amount0) {
            uint256 refund0 = amount0 - amount0Deposited;
            DAI.safeTransfer(msg.sender, refund0);
        }

        if (amount1Deposited < amount1) {
            uint256 refund1 = amount1 - amount1Deposited;
            USDC.safeTransfer(msg.sender, refund1);
        }
    }

    function increaseLiquidity(
        uint256 tokenId,
        uint256 amountAdd0,
        uint256 amountAdd1
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        DAI.safeTransferFrom(msg.sender, address(this), amountAdd0);
        USDC.safeTransferFrom(msg.sender, address(this), amountAdd1);
        DAI.approve(address(positionManager), amountAdd0);
        USDC.approve(address(positionManager), amountAdd1);

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: tokenId,
                    amount0Desired: amountAdd0,
                    amount1Desired: amountAdd1,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });

        (liquidity, amount0, amount1) = positionManager.increaseLiquidity(
            params
        );
    }

    function decreaseLiquidity(
        uint256 tokenId,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1) {
        positionManager.safeTransferFrom(msg.sender, address(this), tokenId);

        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .DecreaseLiquidityParams({
                    tokenId: tokenId,
                    liquidity: amount,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });

        (amount0, amount1) = positionManager.decreaseLiquidity(params);

        positionManager.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function collect(
        uint256 tokenId
    ) external returns (uint256 amount0, uint256 amount1) {
        positionManager.safeTransferFrom(msg.sender, address(this), tokenId);

        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: msg.sender,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = positionManager.collect(params);
    }

    // customize this function according to project
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        // get position information
        return this.onERC721Received.selector;
    }
}
