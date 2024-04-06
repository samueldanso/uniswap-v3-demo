import { ethers } from "hardhat";
import {
    LiquidityContract,
    IERC20,
    INonfungiblePositionManager,
} from "../typechain-types";
import { expect } from "chai";

describe("LiquidityContract", () => {
    let liquidity: LiquidityContract,
        dai: IERC20,
        usdc: IERC20,
        user: string,
        positManager: INonfungiblePositionManager;

    let obj: [bigint, bigint, bigint, bigint] & {
        tokenId: bigint;
        liquidity: bigint;
        amount0Deposited: bigint;
        amount1Deposited: bigint;
    };

    const DAI_WHALE = "0xe5F8086DAc91E039b1400febF0aB33ba3487F29A";
    const DAI_TOKEN = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    const USDC_TOKEN = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const USDC_WHALE = "0xD6153F5af5679a75cC85D8974463545181f48772";
    const POSITION_MANAGER = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88";

    const USDC_AMOUNT = ethers.parseUnits("10", 6);
    const DAI_AMOUNT = ethers.parseUnits("10", 18);

    beforeEach(async () => {
        const daiSigner = await ethers.getImpersonatedSigner(DAI_WHALE);
        const usdcSigner = await ethers.getImpersonatedSigner(USDC_WHALE);
        const signers = await ethers.getSigners();

        await signers[0].sendTransaction({
            value: ethers.parseEther("5"),
            to: DAI_WHALE,
        });
        await signers[0].sendTransaction({
            value: ethers.parseEther("5"),
            to: USDC_WHALE,
        });

        dai = await ethers.getContractAt("IERC20", DAI_TOKEN);
        usdc = await ethers.getContractAt("IERC20", USDC_TOKEN);
        positManager = await ethers.getContractAt(
            "INonfungiblePositionManager",
            POSITION_MANAGER
        );

        // transfer tokens to our signer to make transactions
        user = signers[0].address;
        await dai.connect(daiSigner).transfer(user, DAI_AMOUNT * 5n);
        await usdc.connect(usdcSigner).transfer(user, USDC_AMOUNT * 5n);

        const s = await ethers.deployContract("LiquidityContract", [
            POSITION_MANAGER,
        ]);

        liquidity = await s.waitForDeployment();
    });

    it(".. test minting new position", async () => {
        await dai.approve(liquidity.target, DAI_AMOUNT);
        await usdc.approve(liquidity.target, USDC_AMOUNT);

        obj = await liquidity.mint.staticCall(DAI_AMOUNT, USDC_AMOUNT);
        await liquidity.mint(DAI_AMOUNT, USDC_AMOUNT);

        expect(await positManager.ownerOf(obj.tokenId)).to.equal(user);
    });

    it(".. test increasing liquidity", async () => {
        await dai.approve(liquidity.target, DAI_AMOUNT);
        await usdc.approve(liquidity.target, USDC_AMOUNT);

        const increased = await liquidity.increaseLiquidity.staticCall(
            obj.tokenId,
            DAI_AMOUNT,
            USDC_AMOUNT
        );
        await liquidity.increaseLiquidity(obj.tokenId, DAI_AMOUNT, USDC_AMOUNT);

        const res = await positManager.positions(obj.tokenId);
        expect(res.liquidity).to.equal(obj.liquidity + increased.liquidity);
    });

    it(".. test decreasing liquidity", async () => {
        await positManager.approve(liquidity, obj.tokenId);

        const beforePos = await positManager.positions(obj.tokenId);
        const res = await liquidity.decreaseLiquidity.staticCall(
            obj.tokenId,
            obj.liquidity
        );
        await liquidity.decreaseLiquidity(obj.tokenId, obj.liquidity);
        const afterPos = await positManager.positions(obj.tokenId);

        expect(afterPos.tokensOwed0 - beforePos.tokensOwed0).to.equal(
            res.amount0
        );
    });

    it(".. test collect fees", async () => {
        await positManager.approve(liquidity, obj.tokenId);
        const beforeDAI = await dai.balanceOf(user);

        const res = await liquidity.collect.staticCall(obj.tokenId);
        await liquidity.collect(obj.tokenId);

        const afterDAI = await dai.balanceOf(user);

        expect(ethers.formatEther(afterDAI - beforeDAI)).to.be.greaterThan(9);
    });
});
