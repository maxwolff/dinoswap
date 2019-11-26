const BigNumber = require("bignumber.js");
const util = require("util");

const sendAndCall = async sendable => {
	const returnValue = await call(sendable);
	printEvents(await send(sendable));
	return returnValue;
};

// const printSend = async sendable => {};

const printEvents = tx => {
	Object.keys(tx.events).map(key =>
		console.log("EVENT ", key, "RETURNED: ", tx.events[key].returnValues)
	);
};

const str = num => {
	return new BigNumber(num).toString();
};

const bnEqual = (expected, actual) => {
	return expected.toString() === actual.toString();
};

const futureTime = str(1893492061); // 2030

module.exports = {
	sendAndCall,
	str,
	futureTime,
	bnEqual
};
