# 🦕 DINOSWAP 🦕

A minimal Uniswap fork.

* Swap ERC20s for ERC20s
* Flash borrowing
* Custom fees and price formulas

## TODO

* Improve test coverage
* Add contract for low-slippage [formula](https://devpost.com/software/squink) for stable pairs
* Consider adding CToken accounting to keep reserves equal in value
* Tests, events, etc

## Installation

* `yarn install` 
* install solc. protip: [build from source](https://solidity.readthedocs.io/en/latest/installing-solidity.html#building-from-source) and flag no cvc4
* `yarn test`
	* uses [eth-saddle](https://www.npmjs.com/package/eth-saddle) for testing
* `yarn t` to test without recompiling

## Model 

[https://docs.google.com/spreadsheets/d/19EGFSBu0Kc3cNImVGjqDADcTuG3giVwyHNgfRKgBFOE/edit#gid=0](model)