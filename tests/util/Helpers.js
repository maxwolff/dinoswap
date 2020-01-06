const BigNumber = require("bignumber.js");
const ethers = require("ethers");
const util = require("util");

const sendCall = async (sendable, opts = {}) => {
	const returnValue = await call(sendable, opts);
	const res = await send(sendable, opts);
	// const util = require('util')
	// console.log(util.inspect(res, false, null, true /* enable colors */))
	return returnValue;
};

// added because web3 was weird about passing big numbers
// https://github.com/ethereum/web3.js/issues/2077
const bn = num => {
	return ethers.utils.bigNumberify(new BigNumber(num).toFixed());
};

const futureTime = bn(1893492061); // 2030

const prep = async (spender, amount, token, who) => {
	await send(token.methods.allocateTo(who, amount));
	await send(token.methods.approve(spender, amount), { from: who });
};

module.exports = {
	bn,
	futureTime,
	sendCall,
	prep
};
