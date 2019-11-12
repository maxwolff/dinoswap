// pragma solidity ^0.5.12;

// import "./BoostWallet.sol";
// import "./ICETH.sol";

// interface IFlashBorrow {
// 	flashBorrow(address borrow_token, uint amount, bytes memory data, address target);
// }

// // Send this contract ETH, creates a boost wallet, and sends funds there for further steps
// contract BoostFactory {

// 	Vault public vault;
// 	address public ceth;
	
// 	constructor(address vault_, address ceth_) public {
// 		vault = Vault(vault_);
// 		ceth = ceth_;
// 	}
	
// 	function startBoost
// 	(
// 		uint boostAmount, 
// 		bytes memory tradeData, 
// 		address tradeTarget, 
// 		uint compoundBorrowAmount,
// 		address compoundBorrowToken,
// 		address owner
// 	) 
// 		public payable
// 	{
// 		address boostWallet = (new BoostWallet).value(address(this).balance)(ceth, compoundBorrowToken, owner);
// 		bytes memory callback = abi.encodeWithSignature(
// 			"init(uint, address, bytes, uint)", 
// 			boostAmount, 
// 			tradeTarget, 
// 			tradeData, 
// 			compoundBorrowAmount
// 		);
// 		// calls init on boost wallet
// 		vault.borrow(boostAmount, callback, boostWallet);
// 	}


// }