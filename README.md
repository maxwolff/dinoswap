unifork

## Installation

* `yarn install` 
* install solc. best is to build from source (https://solidity.readthedocs.io/en/latest/installing-solidity.html#building-from-source) and dont use cvc4
* `npx saddle compile && npx saddle test`
  * uses https://www.npmjs.com/package/eth-saddle for testing

## Todos

* consider adding open zeppelin module

## Docs

On boost borrowing:
    /*
    	1 DAI = 1 ETH for simplicity
        
    	supply 100 ETH.
    	boost borrow 100 ETH, and supply it (now 200 ETH supplied)
    	borrow 133 DAI (200 * 1/150%)
    	trade 133 DAI into 133 ETH (execute bytecode for this)
    	repay boost 100 ETH
    	supply the remaining 33 ETH
    	the user now has a 233 ETH supply, and 133 DAI outstanding borrow (and no cash)
    	leverage: 233/100 = 2.33x
    	collateral ratio: 200/133 = 175%
    	learn morehttps://ian.pw/posts/2018-01-25-maximum-leverage-on-maker.html

    Compare this to what can be achieved normally in iteration
    	100 ETH => 66 DAI borrow. Supply 66 ETH, now you have 166 ETH supplied.
    	leverage: 166/100 = 1.66x
    	collateral ratio: 166/66 = 250%

    The max you can go with this approach is 3x (@ 150% collateral ratio):
    supply 100 ETH.
    	boost borrow 200 ETH, and supply it (now 300 ETH supplied)
    	borrow 200 DAI (300 * 2/3)
    	trade 200 DAI into 200 ETH (execute bytecode for this)
    	repay boost 200 ETH
    	supply the remaining 0 ETH
    	end: user has a 300 ETH supply, and 200 DAI outstanding borrow (and no cash)
    	leverage: 300/100 = 3x
    	collateral ratio: 300/200 = 150%
    	learn morehttps://ian.pw/posts/2018-01-25-maximum-leverage-on-maker.html
    */