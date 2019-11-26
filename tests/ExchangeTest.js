const { sendAndCall, str, bnEqual, futureTime } = require("./util/Helpers");

async function deployExchange() {
	const token1 = await deploy("FaucetToken", ["0", "token1", "18", "TK1"]);
	const token2 = await deploy("FaucetToken", ["0", "token2", "18", "TK2"]);
	const exchange = await deploy("ConstantProductExchange", [
		token1.address,
		token2.address,
		997,
		1000,
		"DINO"
	]);

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
	const token1ReserveAmt = str(5e18);
	const token2ReserveAmt = str(1e18);

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
		bnEqual(uniTokenSupply, token1ReserveAmt);
		const token2Bal = await call(token2.methods.balanceOf(accounts[0]));
		bnEqual(token2Bal, 0);
	}, 30000);

	it.only("do input trade", async () => {
		({ token1, token2, exchange } = await deployExchange(accounts[0]));

		await prep(exchange.address, token1ReserveAmt, token1, accounts[0]);
		await prep(exchange.address, token2ReserveAmt, token2, accounts[0]);
		console.log(typeof token1.address);
		await prep(exchange.address, str(2e18), token1, accounts[1]);
		console.log(await call(token1.methods.balanceOf(accounts[1])));

		// const uniTokenSupply = await sendAndCall(
		// 	exchange.methods.addLiquidity(
		// 		token1ReserveAmt,
		// 		token1ReserveAmt,
		// 		token2ReserveAmt,
		// 		futureTime
		// 	)
		// );

		// const swapAmt = str(1e18);

		// const tokensBought = await sendAndCall(
		// 	exchange.methods.tokenSwapInput(
		// 		token1.address,
		// 		token2.address,
		// 		swapAmt,
		// 		str(1),
		// 		futureTime,
		// 		accounts[2]
		// 	),
		// 	{ from: accounts[1] }
		// );

		// const bal1 = await call(token1.methods.balanceOf(accounts[1]));
		// const bal2 = await call(token2.methods.balanceOf(accounts[2]));
		// console.log(bal1, bal2);
	}, 30000);
});
