const { sendAndCall, bn, futureTime } = require("./util/Helpers");

async function deployExchange() {
	console.log("here");
	const token1 = await deploy("FaucetToken", ["0", "token1", 18, "TK1"], {
		from: accounts[0]
	});
	console.log("here");

	const token2 = await deploy("FaucetToken", ["0", "token2", 18, "TK2"], {
		from: accounts[0]
	});
	console.log("here");

	const exchange = await deploy("ConstantProductExchange", [
		token1.address,
		token2.address,
		997,
		1000,
		"DINO"
	]);

	console.log("here");

	return {
		token1,
		token2,
		exchange
	};
}

const prep = async (spender, amount, token, who) => {
	await send(token.methods.allocateTo(who, amount));
	await send(token.methods.approve(spender, amount), { from: who });
};

describe("Exchange", () => {
	let token1, token2, exchange;
	const token1ReserveAmt = bn(5e18);
	const token2ReserveAmt = bn(1e18);

	it("add liquidity", async () => {
		({ token1, token2, exchange } = await deployExchange(accounts[0]));

		await prep(exchange.address, token1ReserveAmt, token1, accounts[0]);

		await prep(exchange.address, token2ReserveAmt, token2, accounts[0]);

		const uniTokenSupply = await sendAndCall(
			exchange.methods.addLiquidity(
				token1ReserveAmt,
				token1ReserveAmt,
				token2ReserveAmt,
				futureTime
			)
		);
		console.log(uniTokenSupply);
		expect(uniTokenSupply.toNumber()).toEqual(token1ReserveAmt);
		const token2Bal = await call(token2.methods.balanceOf(accounts[0]));
		expect(token2Bal.toNumber()).toEqual(0);
	}, 30000);

	// it('do input trade', async () => {
	// 	({token1, token2, exchange} = await deployExchange(token1ReserveAmt, token2ReserveAmt, accounts[0]));
	// 	await send(exchange.methods.addLiquidity(token1ReserveAmt, token1ReserveAmt, token2ReserveAmt, futureTime));
	// 	await send(token1.methods.allocateTo(account[1], 1e18));
	// 	await send(token1.methods.approve(exchange.address, 1e18));
	// 	await send(exchange.methods.tokenSwapInput(token1.address, token2.address, 1e18, 10e18, futureTime, accounts[2]), {from: accounts[1]});

	// 	const bal1 = call(token1.methods.balanceOf(accounts[1]));
	// 	const bal2 = call(token2.methods.balanceOf(accounts[2]));
	// 	console.log(bal1, bal2)

	// },30000);
});
