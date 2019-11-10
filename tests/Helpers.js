async function sendAndCall(sendable) {
	const returnValue = await call(sendable);
	await send(sendable);
	return returnValue;
}

module.exports = {
  sendAndCall
};