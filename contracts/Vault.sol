// pragma solidity ^0.5.9;

// import "./SafeMath.sol";

// // TODO: add support for tokens
// contract Vault {
// 	using SafeMath for uint;

// 	mapping (address => uint) public balances;

// 	function deposit(uint _amount) public payable {
// 		balances[msg.sender] = balances[msg.sender].add(msg.value);
// 	}

// 	function withdraw(uint _amount) public {
// 		uint amount = _amount == uint(-1) ? balances[msg.sender] : _amount;
// 		require(balances[msg.sender] >= amount, "Insufficient liquidity");
// 		msg.sender.send(amount);
// 		balances[msg.sender] = balances[msg.sender].sub(amount);
// 	}

// 	function borrow(uint amount, bytes memory data, address target) public {
// 		uint prevBalance = address(this).balance;
// 		target.call.value(amount)(data);
// 		require(address(this).balance >= prevBalance);
// 	}

// }