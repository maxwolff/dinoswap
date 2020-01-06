const { bn, futureTime, prep, sendCall } = require("./util/Helpers");

const deployExchange = async () => {
	const token1 = await deploy("FaucetToken", ["0", "token1", "18", "TK1"]);
	const token2 = await deploy("FaucetToken", ["0", "token2", "18", "TK2"]);
	const exchange = await deploy("ConstantProductExchange", [
		token1._address,
		token2._address,
		997,
		1000,
		"DINO"
	]);

	return {
		token1,
		token2,
		exchange
	};
};

describe("Exchange", () => {
	let token1, token2, exchange;
	const token1ReserveAmt = bn(5e18);
	const token2ReserveAmt = bn(1e18);
	let uniTokensMinted;
	const lp = accounts[0];
	const trader = accounts[1];
	const recipient = accounts[2];

	beforeEach(async () => {
		({ token1, token2, exchange } = await deployExchange(lp));
		await prep(exchange._address, token1ReserveAmt, token1, lp);
		await prep(exchange._address, token2ReserveAmt, token2, lp);
		uniTokensMinted = await sendCall(
			exchange.methods.addLiquidity(
				token1ReserveAmt,
				token1ReserveAmt,
				token2ReserveAmt,
				futureTime
			)
		);
	});

	it("add liquidity", async () => {
		expect.toEqual(uniTokensMinted, token1ReserveAmt);
		const bal1 = await call(token1.methods.balanceOf(lp));
		expect(bal1).toEqual(0);

		const bal2 = await call(token2.methods.balanceOf(lp));
		expect(bal2).toEqual(0);
	});

	it("do input trade", async () => {
		const swapAmt = bn(1e18);
		await prep(exchange._address, swapAmt, token1, trader);
		const tokensBought = await sendCall(
			exchange.methods.tokenSwapInput(
				token1._address,
				token2._address,
				swapAmt,
				bn(1),
				futureTime,
				recipient
			),
			{ from: trader }
		);
		const bal1 = await call(token1.methods.balanceOf(trader));
		const bal2 = await call(token2.methods.balanceOf(recipient));
		expect(bal1).toEqual(0);
		expect(tokensBought).toAlmostEqual(0.166249791562448e18, 10);
	}, 300000);

	it("do output trade", async () => {
		const swapAmt = bn(0.166249791562448e18);
		await prep(exchange._address, bn(1.1e18), token1, trader);
		const tokensSpent = await sendCall(
			exchange.methods.tokenSwapOutput(
				token1._address,
				token2._address,
				swapAmt,
				bn(1e20),
				futureTime,
				recipient
			),
			{ from: trader }
		);
		const bal1 = await call(token1.methods.balanceOf(trader));
		const bal2 = await call(token2.methods.balanceOf(recipient));
		expect(bal1).toAlmostEqual(0.1e18, 10);
		expect(tokensSpent).toAlmostEqual(1e18, 10);
	}, 300000);
});
