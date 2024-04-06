import { ethers } from "hardhat";
import { SingleHopSwap, IERC20 } from "../typechain-types";
import { expect } from "chai";

describe("SingleHopSwap", () => {
    let swap: SingleHopSwap, dai: IERC20, usdc: IERC20, user: string;

    const DAI_WHALE = "0xe5F8086DAc91E039b1400febF0aB33ba3487F29A";
    const DAI_TOKEN = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const ROUTER = "0xe592427a0aece92de3edee1f18e0157c05861564";

    const USDC_AMOUNT = ethers.parseUnits("5", 6);
    const DAI_AMOUNT = ethers.parseUnits("10", 18);

    beforeEach(async () => {
        const daiSigner = await ethers.getImpersonatedSigner(DAI_WHALE);
        dai = await ethers.getContractAt("IERC20", DAI_TOKEN);
        usdc = await ethers.getContractAt("IERC20", USDC);

        // transfer tokens to our signer to make transactions
        const signers = await ethers.getSigners();
        user = signers[0].address;
        await dai.connect(daiSigner).transfer(user, DAI_AMOUNT);

        const s = await ethers.deployContract("SingleHopSwap", [ROUTER]);

        swap = await s.waitForDeployment();
    });

    it(".. test swapExactInputSingle function", async () => {
        console.log(
            "USDC after before: ",
            ethers.formatUnits(await usdc.balanceOf(user), 6)
        );
        console.log(
            "DAI after before: ",
            ethers.formatUnits(await dai.balanceOf(user), 18)
        );
        await dai.approve(swap.target, DAI_AMOUNT);
        await expect(
            swap.swapExactInputSingle(DAI_AMOUNT)
        ).to.changeTokenBalance(dai, user, -DAI_AMOUNT);

        console.log(
            "USDC after after: ",
            ethers.formatUnits(await usdc.balanceOf(user), 6)
        );
        console.log(
            "DAI after after: ",
            ethers.formatUnits(await dai.balanceOf(user), 18)
        );
    });

    it(".. test swapExactOutputSingle function", async () => {
        console.log(
            "USDC after before: ",
            ethers.formatUnits(await usdc.balanceOf(user), 6)
        );
        console.log(
            "DAI after before: ",
            ethers.formatUnits(await dai.balanceOf(user), 18)
        );
        await dai.approve(swap.target, DAI_AMOUNT);
        await expect(
            swap.swapExactOutputSingle(USDC_AMOUNT, DAI_AMOUNT)
        ).to.changeTokenBalance(usdc, user, USDC_AMOUNT);

        console.log(
            "USDC after after: ",
            ethers.formatUnits(await usdc.balanceOf(user), 6)
        );
        console.log(
            "DAI after after: ",
            ethers.formatUnits(await dai.balanceOf(user), 18)
        );
    });
});
