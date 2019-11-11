const exchangeABI = require("../.build/contracts.json").contracts["contracts/UniforkExchange.sol:UniforkExchange"].abi;

const {
  sendAndCall
} = require('./util/Helpers');

const user1 = accounts[0];
const user2 = accounts[1];


async function deployExchange() {
	const [token1, token2, factory] = await Promise.all([
		deploy("FaucetToken", ["100", "token1", 18, "TK1"]), // faucet to user 1
		deploy("FaucetToken", ["100", "token2", 18, "TK2"]), 
		deploy("UniforkFactory", [])
	]);	
	const exchangeAddress = await sendAndCall(factory.methods.createExchange(token1.address, token2.address));
	const exchange = new web3.eth.Contract(
		JSON.parse(exchangeABI),
		exchangeAddress
	);
	return {
		token1: token1,
		token2: token2,
		factory: factory,
		exchange: exchange
	};
}

describe("Tests", () => {

	it('deploy factory', async () => {
		const {token1, token2, factory, exchange} = await deployExchange();
		expect(await call(exchange.methods.token1)).toEqual(token1.address);
		expect(await call(factory.methods.getExchange(token1.address, token2.address))).toEqual(exchange.address);
	});

	it('add liquidity', async () => {
		const {token1, token2, factory, exchange} = await deployExchange();
		await send(token1.methods.approve(exchange.address, 20));
		await send(token2.methods.approve(exchange.address, 20));
		const uniTokenSupply = await sendAndCall(exchange.methods.addLiquidity(10, 10, 10, 10));
		expect(uniTokenSupply.toNumber()).toEqual(10);
		const token2Bal = await call(token2.methods.balanceOf(user1)); 
		expect(token2Bal.toNumber()).toEqual(90);
	},30000);
});

