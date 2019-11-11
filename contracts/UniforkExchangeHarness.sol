pragma solidity ^0.5.12;

import "./UniforkExchange.sol";

contract UniforkExchangeHarness is UniforkExchange {
	
	uint public time;

	constructor(address token1_, address token2_) 
		UniforkExchange(token1_, token2_)
		public {}

	function setBlockTimestamp(uint time_) public {
		time = time_;
	}
	function getBlockTimestamp() public view returns (uint) {
		return time;
	}
}