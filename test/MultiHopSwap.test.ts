import { ethers } from "hardhat";
import { expect } from "chai";
import { MultiHopSwap, IERC20 } from "../typechain-types";

describe("MultiHopSwap", () => {
    let swap: MultiHopSwap, dai: IERC20, weth: IERC20, user: string;

    const DAI_WHALE = "0xe5F8086DAc91E039b1400febF0aB33ba3487F29A";
    const DAI_TOKEN = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    const ROUTER = "0xe592427a0aece92de3edee1f18e0157c05861564";

    const WETH_AMOUNT = ethers.parseUnits("0.0025", 18);
    const DAI_AMOUNT = ethers.parseUnits("10", 18);

    beforeEach(async () => {
        const daiSigner = await ethers.getImpersonatedSigner(DAI_WHALE);
        dai = await ethers.getContractAt("IERC20", DAI_TOKEN);
        weth = await ethers.getContractAt("IERC20", WETH);

        // transfer tokens to our signer to make transactions
        const signers = await ethers.getSigners();
        user = signers[0].address;
        await dai.connect(daiSigner).transfer(user, DAI_AMOUNT);

        const s = await ethers.deployContract("MultiHopSwap", [ROUTER]);

        swap = await s.waitForDeployment();
    });

    it(".. test swapExactInputMultihop function", async () => {
        console.log(
            "WETH after before: ",
            ethers.formatUnits(await weth.balanceOf(user), 18)
        );
        console.log(
            "DAI after before: ",
            ethers.formatUnits(await dai.balanceOf(user), 18)
        );
        await dai.approve(swap.target, DAI_AMOUNT);
        await expect(
            swap.swapExactInputMultihop(DAI_AMOUNT)
        ).to.changeTokenBalance(dai, user, -DAI_AMOUNT);

        console.log(
            "WETH after after: ",
            ethers.formatUnits(await weth.balanceOf(user), 18)
        );
        console.log(
            "DAI after after: ",
            ethers.formatUnits(await dai.balanceOf(user), 18)
        );
    });

    it(".. test swapExactOutputMultihop function", async () => {
        console.log(
            "WETH after before: ",
            ethers.formatUnits(await weth.balanceOf(user), 18)
        );
        console.log(
            "DAI after before: ",
            ethers.formatUnits(await dai.balanceOf(user), 18)
        );
        await dai.approve(swap.target, DAI_AMOUNT);
        await expect(
            swap.swapExactOutputMultihop(WETH_AMOUNT, DAI_AMOUNT)
        ).to.changeTokenBalance(weth, user, WETH_AMOUNT);

        console.log(
            "WETH after after: ",
            ethers.formatUnits(await weth.balanceOf(user), 18)
        );
        console.log(
            "DAI after after: ",
            ethers.formatUnits(await dai.balanceOf(user), 18)
        );
    });
});
