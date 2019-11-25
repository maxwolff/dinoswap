const BigNumber = require("bignumber.js");

const sendAndCall = async sendable => {
	const returnValue = await call(sendable);
	await send(sendable);
	return new BigNumber(returnValue).toString();
};

const bn = num => {
	const f = new BigNumber(num);
	return f.toString();
};
const futureTime = bn(1893492061); // 2030

module.exports = {
	sendAndCall,
	bn,
	futureTime
};
