pragma solidity ^0.5.12;

interface ICERC20 {
	function mint(uint mintAmount) external returns (uint);
	function redeem(uint redeemTokens) external returns (uint);
	function repayBorrow(uint repayAmount) external returns (uint);
	function borrow(uint borrowAmount) external returns (uint);
}