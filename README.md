# 🦕 DINOSWAP 🦕

A Uniswap fork.

* Swap ERC20s for ERC20s
* Flash borrowing
* Custom fees and price formulas

## TODO

* Add contract for low-slippage (formula)[https://devpost.com/software/squink] for stable pairs
* Consider adding CToken accounting (to keep reserves equal in value in terms of underlying, not just CToken amount)
* Tests, events, etc

## Installation

* `yarn install` 
* install solc. protip: (build from source)[https://solidity.readthedocs.io/en/latest/installing-solidity.html#building-from-source] and flag no cvc4
* `yarn test`
	* uses (eth-saddle)[https://www.npmjs.com/package/eth-saddle] for testing
