# Uniswap V3 Demo

This project demonstrates on how to integrate uniswap v3 into our solidity smart contracts. We are deploying contracts on forked ethereum mainnet and performing test cases on them.

Please be noted that the contracts are not production ready. Modify them according to your project requirements.

The contracts covers topics on

-   how to make a token swap
    -   Using SingleHop method
    -   Using Multihop method
-   how to do a flash swap
-   how to manage liquidity.

Technology used

-   hardhat
-   typescript

To setup

```sh
    git clone https://github.com/jveer634/uniswap-v3-demo.git
    cd uniswap-v3-demo
    npm i
```

To compile

```sh
    npx hardhat compile
```

To test

```sh
    npx hardhat test
```
