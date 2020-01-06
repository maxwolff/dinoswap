# Dinoswap

A stub of a Uniswap fork. Undeployed and missing test coverage.

* Swap ERC20s for ERC20s
* Flash borrowing
* Support for custom fees and price formulas

## Installation

* `yarn install` 
* install solc. protip: [build from source](https://solidity.readthedocs.io/en/latest/installing-solidity.html#building-from-source) and flag no cvc4
* `yarn test`
	* uses [eth-saddle](https://www.npmjs.com/package/eth-saddle) for testing
* `yarn t` to test without recompiling

## TODO

* Add contract for low-slippage [formula](https://devpost.com/software/squink) for stable pairs
* Consider adding CToken accounting to keep reserves equal in value
* Tests, events, etc

## Model 

[https://docs.google.com/spreadsheets/d/19EGFSBu0Kc3cNImVGjqDADcTuG3giVwyHNgfRKgBFOE/edit#gid=0](model)
