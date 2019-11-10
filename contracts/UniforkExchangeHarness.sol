pragma solidity ^0.5.12;

import "./UniforkExchange.sol";

contract UniforkExchangeHarness is UniforkExchange {
	
	uint public block;

	constructor(address token1_, address token2_) 
		UniforkExchange(token1_, token2_)
		public {}

	function setBlockTimestamp(uint block_) {
		block = block_;
	}
	function getBlockTimestamp() {
		return block;
	}
}