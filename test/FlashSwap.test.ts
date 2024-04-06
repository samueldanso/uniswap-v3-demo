import { ethers } from "hardhat";
import { FlashSwap, IERC20 } from "../typechain-types";

describe("FlashSwap", () => {
    let flash: FlashSwap, dai: IERC20, user: string;

    const DAI_WHALE = "0xe5F8086DAc91E039b1400febF0aB33ba3487F29A";
    const DAI_TOKEN = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

    const POOL = "0xa63b490aa077f541c9d64bfc1cc0db2a752157b5";

    const DAI_AMOUNT = ethers.parseUnits("0.03", 18);

    beforeEach(async () => {
        const daiSigner = await ethers.getImpersonatedSigner(DAI_WHALE);
        const signers = await ethers.getSigners();

        await signers[0].sendTransaction({
            value: ethers.parseEther("5"),
            to: DAI_WHALE,
        });

        dai = await ethers.getContractAt("IERC20", DAI_TOKEN);

        // transfer tokens to our signer to make transactions
        user = signers[0].address;
        await dai.connect(daiSigner).transfer(user, DAI_AMOUNT);

        const s = await ethers.deployContract("FlashSwap", [POOL]);
        flash = await s.waitForDeployment();
    });

    it(".. test flashswap", async () => {
        await dai.approve(flash.target, DAI_AMOUNT);
        console.log(
            "User - Before DAI balance: ",
            ethers.formatUnits(await dai.balanceOf(user), 18)
        );

        await flash.initFlash(ethers.parseEther("10"), 0);
        console.log(
            "User - After DAI balance: ",
            ethers.formatUnits(await dai.balanceOf(user), 18)
        );
    });
});
