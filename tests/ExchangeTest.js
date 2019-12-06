const { sendCall, str, futureTime, prep } = require("./util/Helpers");

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

describe("Exchange", () => {

	let token1, token2, exchange;
	const token1ReserveAmt = str(5e18);
	const token2ReserveAmt = str(1e18);
	let uniTokensMinted;

	beforeEach(async ()=> {
		({ token1, token2, exchange } = await deployExchange(accounts[0]));
		await prep(exchange.address, token1ReserveAmt, token1, accounts[0]);
		await prep(exchange.address, token2ReserveAmt, token2, accounts[0]);
		uniTokensMinted = await sendCall(
			exchange.methods.addLiquidity(
				token1ReserveAmt,
				token1ReserveAmt,
				token2ReserveAmt,
				futureTime
			)
		);
	}, 30000)

	it("add liquidity", async () => {
		expect.numEquals(uniTokensMinted, token1ReserveAmt);
		const token2Bal = await call(token2.methods.balanceOf(accounts[0]));
		expect.numEquals(token2Bal, 0);
	},);

	describe("Test Trades", () => {
		it("do input trade", async () => {
			const swapAmt = str(1e18);
			await prep(exchange.address, str(1e18), token1, accounts[1]);
			const tokensBought = await sendCall(
				exchange.methods.tokenSwapInput(
					token1.address,
					token2.address,
					swapAmt,
					str(1),
					futureTime,
					accounts[2]
				),
				{ from: accounts[1] }
			);
			const bal1 = await call(token1.methods.balanceOf(accounts[1]));
			const bal2 = await call(token2.methods.balanceOf(accounts[2]));
			expect.numEquals(bal1, 0);
			expect.toAlmostEqual(tokensBought, 0.1662497916e18, 5);
		}, 30000);

		it("do output trade", async () => {
			const swapAmt = str(0.1662497916e18);
			await prep(exchange.address, str(1e18), token1, accounts[1]);
			const tokensSpent = await sendCall(
				exchange.methods.tokenSwapOutput(
					token1.address,
					token2.address,
					swapAmt,
					str(1),
					futureTime,
					accounts[2]
				),
				{ from: accounts[1] }
			);
			const bal1 = await call(token1.methods.balanceOf(accounts[1]));
			const bal2 = await call(token2.methods.balanceOf(accounts[2]));
			expect.numEquals(bal1, 0);
			expect.toAlmostEqual(tokensSpent, 1e18, 5);
		}, 30000);
	})

});
