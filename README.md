# Uniswap V3 Demo

This project demonstrates how to integrate Uniswap v3 into our Solidity smart contracts. We are deploying contracts on a forked Ethereum mainnet and performing test cases on them.

Please note that the contracts are not production-ready. Modify them according to your project requirements.

The contracts covers topics on

- How to make a token swap:
  - Using SingleHop method
  - Using Multihop method
- How to do a flash swap
- How to manage liquidity

Technogies

- Hardhat
- Typescript

To setup

```sh
    git clone https://github.com/samuedanso/uniswap-v3-demo.git
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
