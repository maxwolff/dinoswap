// pragma solidity ^0.5.12;

// import "./SafeMath.sol";
// import "./CTokeInterfaces.sol";

// contract BoostWallet {
// 	using SafeMath for uint;

// 	ICETH public ceth;
// 	// eg USDC or DAI
// 	ICERC20 public borrowCERC20;
// 	address public owner;

// 	constructor (
// 		address ceth_,
// 		address borrowToken_,
// 		address owner_
// 	) 
// 		public payable
// 	{
// 		ceth = ICETH(ceth_);
// 		borrowCERC20 = ICERC20(borrowToken_); 
// 		owner = owner_;
// 	}

// 	function init (
// 		uint boostAmount, 
// 		address tradeTarget,
// 		bytes memory tradeData, 
// 		uint compoundBorrowAmount
// 	)
// 		public 
// 		payable
// 	{
// 		ceth.mint.value(address(this).balance)();
// 		borrowCERC20.borrow(compoundBorrowAmount);
// 		tradeTarget.call(tradeData);
// 		borrowCERC20.mint(address(this).balance - boostAmount);
// 		// repay loan
// 		msg.sender.send(boostAmount);
// 	}

// 	/*
// 		TODO: add compound wallet funcs:
// 			* supply more
// 			* borrow more
// 			* repay
// 			* withdraw
// 			* change owner
// 	*/ 

// }