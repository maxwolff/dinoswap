pragma solidity ^0.5.12;

import "./StandardToken.sol";
import "./SafeMath.sol";

contract IFactory {
    function getExchange(address token1, address token2) external view returns (address);
}

contract UniforkExchange is StandardToken {
    using SafeMath for * ;

    IFactory public factory;
    ERC20 public token1; // prev eth
    ERC20 public token2;

    string public name = "UniforkExchange 1.0";
    string public symbol = "UNIFORK-V1";
    uint public decimals = 18;
    // uint public totalSupply_; // based off of token1 (prev eth)

    // 997 / 1000 => 0.997 => 0.3% fee
    uint public feeConstant = 997;
    uint public feePrecision = 1000;

    constructor(address token1_, address token2_) public {
        require(token1_ != token2_);
        token1 = ERC20(token1_);
        token2 = ERC20(token2_);
        factory = IFactory(msg.sender);
        // TODO: name / symbol decorations
    }
    /// XXX add harness
    function getBlockTimestamp() public view returns (uint) {
        return 0;
        // return block.timestamp;
    }

    function addLiquidity(
        uint token1_amount, 
        uint min_liquidity, 
        uint max_token2, 
        uint deadline
    ) 
        external 
        returns (uint) 
    {
        require(deadline > getBlockTimestamp());
        require(max_token2 > 0);
        uint total_liquidity = totalSupply_; // i think this assignment is unessecary, just a gas optimization
        if (total_liquidity > 0) {
            require(min_liquidity > 0);
            uint token1_reserve = token1.balanceOf(address(this));
            uint token2_reserve = token2.balanceOf(address(this));
            uint token2_amount = token1_amount.mul(token2_reserve).div(token1_reserve).add(1);
            uint liquidity_minted = token1_amount.mul(total_liquidity).div(token1_reserve);
            require(max_token2 > token2_amount);
            require(liquidity_minted >= min_liquidity);
            balances[msg.sender] = balances[msg.sender].add(liquidity_minted);
            totalSupply_ = total_liquidity.add(liquidity_minted);
            require(token1.transferFrom(msg.sender, address(this), token1_amount));
            require(token2.transferFrom(msg.sender, address(this), token2_amount));
            // todo events
            return liquidity_minted;
        } else {
            require(address(factory) != address(0) && address(token1) != address(0) && address(token2) != address(0));
            require(factory.getExchange(address(token1), address(token2)) == address(this) || factory.getExchange(address(token2), address(token1)) == address(this));
            uint token2_amount = max_token2;
            uint initial_liquidity = token1_amount; // unecessary assignment?
            totalSupply_ = initial_liquidity;
            balances[msg.sender] = initial_liquidity;
            require(token1.transferFrom(msg.sender, address(this), token1_amount));
            require(token2.transferFrom(msg.sender, address(this), token2_amount));
            // XXX do logs
            return initial_liquidity;
        }
    }

    function removeLiquidity(
        uint amount, 
        uint min_token1, 
        uint min_token2,
        uint deadline
    ) 
        external 
        returns (uint, uint) 
    {
        require(amount > 0);
        require(deadline > getBlockTimestamp());
        require(min_token1 > 0);
        require(min_token2 > 0);
        require(totalSupply_ > 0);
        uint total_liquidity = totalSupply_; // again, uneccesary for the sake of gas
        // amount / total liq is the portion of the pool you own.
        uint token1_amount = token1.balanceOf(address(this)) * amount / total_liquidity;
        uint token2_amount = token2.balanceOf(address(this)) * amount / total_liquidity;
        require(token1_amount > min_token1);
        require(token2_amount > min_token2);
        balances[msg.sender] -= amount;
        totalSupply_ = total_liquidity - amount;
        token1.transfer(msg.sender, token1_amount);
        token2.transfer(msg.sender, token2_amount);
        // XXX do logs
        return (token1_amount, token2_amount);
    }
    // XXX Add safemath
    function getInputPrice(uint input_amount, uint input_reserve, uint output_reserve) private view returns (uint) {
        require(input_reserve > 0);
        require(output_reserve > 0);
        // if (price model != 0), do pricemodel.getPrice()
        uint input_amount_with_fee = input_amount * feeConstant;
        uint numerator = input_amount_with_fee * output_reserve;
        uint denominator = (input_reserve * feePrecision) + input_amount_with_fee;
        return numerator / denominator;
    }


}

// # # @dev Pricing function for converting between ETH and Tokens.
// # # @param output_amount Amount of ETH or Tokens being bought.
// # # @param input_reserve Amount of ETH or Tokens (input type) in exchange reserves.
// # # @param output_reserve Amount of ETH or Tokens (output type) in exchange reserves.
// # # @return Amount of ETH or Tokens sold.
// # @private
// # @constant
// # def getOutputPrice(output_amount: uint256, input_reserve: uint256, output_reserve: uint256) -> uint256:
// #     assert input_reserve > 0 and output_reserve > 0
// #     numerator: uint256 = input_reserve * output_amount * 1000
// #     denominator: uint256 = (output_reserve - output_amount) * 997
// #     return numerator / denominator + 1

// # @private
// # def ethToTokenInput(eth_sold: uint256(wei), min_tokens: uint256, deadline: timestamp, buyer: address, recipient: address) -> uint256:
// #     assert deadline >= block.timestamp and (eth_sold > 0 and min_tokens > 0)
// #     token_reserve: uint256 = self.token.balanceOf(self)
// #     tokens_bought: uint256 = self.getInputPrice(as_unitless_number(eth_sold), as_unitless_number(self.balance - eth_sold), token_reserve)
// #     assert tokens_bought >= min_tokens
// #     assert_modifiable(self.token.transfer(recipient, tokens_bought))
// #     log.TokenPurchase(buyer, eth_sold, tokens_bought)
// #     return tokens_bought

// # # @notice Convert ETH to Tokens.
// # # @dev User specifies exact input (msg.value).
// # # @dev User cannot specify minimum output or deadline.
// # @public
// # @payable
// # def __default__():
// #     self.ethToTokenInput(msg.value, 1, block.timestamp, msg.sender, msg.sender)

// # # @notice Convert ETH to Tokens.
// # # @dev User specifies exact input (msg.value) and minimum output.
// # # @param min_tokens Minimum Tokens bought.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @return Amount of Tokens bought.
// # @public
// # @payable
// # def ethToTokenSwapInput(min_tokens: uint256, deadline: timestamp) -> uint256:
// #     return self.ethToTokenInput(msg.value, min_tokens, deadline, msg.sender, msg.sender)

// # # @notice Convert ETH to Tokens and transfers Tokens to recipient.
// # # @dev User specifies exact input (msg.value) and minimum output
// # # @param min_tokens Minimum Tokens bought.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @param recipient The address that receives output Tokens.
// # # @return Amount of Tokens bought.
// # @public
// # @payable
// # def ethToTokenTransferInput(min_tokens: uint256, deadline: timestamp, recipient: address) -> uint256:
// #     assert recipient != self and recipient != ZERO_ADDRESS
// #     return self.ethToTokenInput(msg.value, min_tokens, deadline, msg.sender, recipient)

// # @private
// # def ethToTokenOutput(tokens_bought: uint256, max_eth: uint256(wei), deadline: timestamp, buyer: address, recipient: address) -> uint256(wei):
// #     assert deadline >= block.timestamp and (tokens_bought > 0 and max_eth > 0)
// #     token_reserve: uint256 = self.token.balanceOf(self)
// #     eth_sold: uint256 = self.getOutputPrice(tokens_bought, as_unitless_number(self.balance - max_eth), token_reserve)
// #     # Throws if eth_sold > max_eth
// #     eth_refund: uint256(wei) = max_eth - as_wei_value(eth_sold, 'wei')
// #     if eth_refund > 0:
// #         send(buyer, eth_refund)
// #     assert_modifiable(self.token.transfer(recipient, tokens_bought))
// #     log.TokenPurchase(buyer, as_wei_value(eth_sold, 'wei'), tokens_bought)
// #     return as_wei_value(eth_sold, 'wei')

// # # @notice Convert ETH to Tokens.
// # # @dev User specifies maximum input (msg.value) and exact output.
// # # @param tokens_bought Amount of tokens bought.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @return Amount of ETH sold.
// # @public
// # @payable
// # def ethToTokenSwapOutput(tokens_bought: uint256, deadline: timestamp) -> uint256(wei):
// #     return self.ethToTokenOutput(tokens_bought, msg.value, deadline, msg.sender, msg.sender)

// # # @notice Convert ETH to Tokens and transfers Tokens to recipient.
// # # @dev User specifies maximum input (msg.value) and exact output.
// # # @param tokens_bought Amount of tokens bought.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @param recipient The address that receives output Tokens.
// # # @return Amount of ETH sold.
// # @public
// # @payable
// # def ethToTokenTransferOutput(tokens_bought: uint256, deadline: timestamp, recipient: address) -> uint256(wei):
// #     assert recipient != self and recipient != ZERO_ADDRESS
// #     return self.ethToTokenOutput(tokens_bought, msg.value, deadline, msg.sender, recipient)

// # @private
// # def tokenToEthInput(tokens_sold: uint256, min_eth: uint256(wei), deadline: timestamp, buyer: address, recipient: address) -> uint256(wei):
// #     assert deadline >= block.timestamp and (tokens_sold > 0 and min_eth > 0)
// #     token_reserve: uint256 = self.token.balanceOf(self)
// #     eth_bought: uint256 = self.getInputPrice(tokens_sold, token_reserve, as_unitless_number(self.balance))
// #     wei_bought: uint256(wei) = as_wei_value(eth_bought, 'wei')
// #     assert wei_bought >= min_eth
// #     send(recipient, wei_bought)
// #     assert_modifiable(self.token.transferFrom(buyer, self, tokens_sold))
// #     log.EthPurchase(buyer, tokens_sold, wei_bought)
// #     return wei_bought


// # # @notice Convert Tokens to ETH.
// # # @dev User specifies exact input and minimum output.
// # # @param tokens_sold Amount of Tokens sold.
// # # @param min_eth Minimum ETH purchased.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @return Amount of ETH bought.
// # @public
// # def tokenToEthSwapInput(tokens_sold: uint256, min_eth: uint256(wei), deadline: timestamp) -> uint256(wei):
// #     return self.tokenToEthInput(tokens_sold, min_eth, deadline, msg.sender, msg.sender)

// # # @notice Convert Tokens to ETH and transfers ETH to recipient.
// # # @dev User specifies exact input and minimum output.
// # # @param tokens_sold Amount of Tokens sold.
// # # @param min_eth Minimum ETH purchased.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @param recipient The address that receives output ETH.
// # # @return Amount of ETH bought.
// # @public
// # def tokenToEthTransferInput(tokens_sold: uint256, min_eth: uint256(wei), deadline: timestamp, recipient: address) -> uint256(wei):
// #     assert recipient != self and recipient != ZERO_ADDRESS
// #     return self.tokenToEthInput(tokens_sold, min_eth, deadline, msg.sender, recipient)

// # @private
// # def tokenToEthOutput(eth_bought: uint256(wei), max_tokens: uint256, deadline: timestamp, buyer: address, recipient: address) -> uint256:
// #     assert deadline >= block.timestamp and eth_bought > 0
// #     token_reserve: uint256 = self.token.balanceOf(self)
// #     tokens_sold: uint256 = self.getOutputPrice(as_unitless_number(eth_bought), token_reserve, as_unitless_number(self.balance))
// #     # tokens sold is always > 0
// #     assert max_tokens >= tokens_sold
// #     send(recipient, eth_bought)
// #     assert_modifiable(self.token.transferFrom(buyer, self, tokens_sold))
// #     log.EthPurchase(buyer, tokens_sold, eth_bought)
// #     return tokens_sold

// # # @notice Convert Tokens to ETH.
// # # @dev User specifies maximum input and exact output.
// # # @param eth_bought Amount of ETH purchased.
// # # @param max_tokens Maximum Tokens sold.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @return Amount of Tokens sold.
// # @public
// # def tokenToEthSwapOutput(eth_bought: uint256(wei), max_tokens: uint256, deadline: timestamp) -> uint256:
// #     return self.tokenToEthOutput(eth_bought, max_tokens, deadline, msg.sender, msg.sender)

// # # @notice Convert Tokens to ETH and transfers ETH to recipient.
// # # @dev User specifies maximum input and exact output.
// # # @param eth_bought Amount of ETH purchased.
// # # @param max_tokens Maximum Tokens sold.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @param recipient The address that receives output ETH.
// # # @return Amount of Tokens sold.
// # @public
// # def tokenToEthTransferOutput(eth_bought: uint256(wei), max_tokens: uint256, deadline: timestamp, recipient: address) -> uint256:
// #     assert recipient != self and recipient != ZERO_ADDRESS
// #     return self.tokenToEthOutput(eth_bought, max_tokens, deadline, msg.sender, recipient)

// # @private
// # def tokenToTokenInput(tokens_sold: uint256, min_tokens_bought: uint256, min_eth_bought: uint256(wei), deadline: timestamp, buyer: address, recipient: address, exchange_addr: address) -> uint256:
// #     assert (deadline >= block.timestamp and tokens_sold > 0) and (min_tokens_bought > 0 and min_eth_bought > 0)
// #     assert exchange_addr != self and exchange_addr != ZERO_ADDRESS
// #     token_reserve: uint256 = self.token.balanceOf(self)
// #     eth_bought: uint256 = self.getInputPrice(tokens_sold, token_reserve, as_unitless_number(self.balance))
// #     wei_bought: uint256(wei) = as_wei_value(eth_bought, 'wei')
// #     assert wei_bought >= min_eth_bought
// #     assert_modifiable(self.token.transferFrom(buyer, self, tokens_sold))
// #     tokens_bought: uint256 = Exchange(exchange_addr).ethToTokenTransferInput(min_tokens_bought, deadline, recipient, value=wei_bought)
// #     log.EthPurchase(buyer, tokens_sold, wei_bought)
// #     return tokens_bought

// # # @notice Convert Tokens (self.token) to Tokens (token_addr).
// # # @dev User specifies exact input and minimum output.
// # # @param tokens_sold Amount of Tokens sold.
// # # @param min_tokens_bought Minimum Tokens (token_addr) purchased.
// # # @param min_eth_bought Minimum ETH purchased as intermediary.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @param token_addr The address of the token being purchased.
// # # @return Amount of Tokens (token_addr) bought.
// # @public
// # def tokenToTokenSwapInput(tokens_sold: uint256, min_tokens_bought: uint256, min_eth_bought: uint256(wei), deadline: timestamp, token_addr: address) -> uint256:
// #     exchange_addr: address = self.factory.getExchange(token_addr)
// #     return self.tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, msg.sender, exchange_addr)

// # # @notice Convert Tokens (self.token) to Tokens (token_addr) and transfers
// # #         Tokens (token_addr) to recipient.
// # # @dev User specifies exact input and minimum output.
// # # @param tokens_sold Amount of Tokens sold.
// # # @param min_tokens_bought Minimum Tokens (token_addr) purchased.
// # # @param min_eth_bought Minimum ETH purchased as intermediary.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @param recipient The address that receives output ETH.
// # # @param token_addr The address of the token being purchased.
// # # @return Amount of Tokens (token_addr) bought.
// # @public
// # def tokenToTokenTransferInput(tokens_sold: uint256, min_tokens_bought: uint256, min_eth_bought: uint256(wei), deadline: timestamp, recipient: address, token_addr: address) -> uint256:
// #     exchange_addr: address = self.factory.getExchange(token_addr)
// #     return self.tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, recipient, exchange_addr)

// # @private
// # def tokenToTokenOutput(tokens_bought: uint256, max_tokens_sold: uint256, max_eth_sold: uint256(wei), deadline: timestamp, buyer: address, recipient: address, exchange_addr: address) -> uint256:
// #     assert deadline >= block.timestamp and (tokens_bought > 0 and max_eth_sold > 0)
// #     assert exchange_addr != self and exchange_addr != ZERO_ADDRESS
// #     eth_bought: uint256(wei) = Exchange(exchange_addr).getEthToTokenOutputPrice(tokens_bought)
// #     token_reserve: uint256 = self.token.balanceOf(self)
// #     tokens_sold: uint256 = self.getOutputPrice(as_unitless_number(eth_bought), token_reserve, as_unitless_number(self.balance))
// #     # tokens sold is always > 0
// #     assert max_tokens_sold >= tokens_sold and max_eth_sold >= eth_bought
// #     assert_modifiable(self.token.transferFrom(buyer, self, tokens_sold))
// #     eth_sold: uint256(wei) = Exchange(exchange_addr).ethToTokenTransferOutput(tokens_bought, deadline, recipient, value=eth_bought)
// #     log.EthPurchase(buyer, tokens_sold, eth_bought)
// #     return tokens_sold

// # # @notice Convert Tokens (self.token) to Tokens (token_addr).
// # # @dev User specifies maximum input and exact output.
// # # @param tokens_bought Amount of Tokens (token_addr) bought.
// # # @param max_tokens_sold Maximum Tokens (self.token) sold.
// # # @param max_eth_sold Maximum ETH purchased as intermediary.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @param token_addr The address of the token being purchased.
// # # @return Amount of Tokens (self.token) sold.
// # @public
// # def tokenToTokenSwapOutput(tokens_bought: uint256, max_tokens_sold: uint256, max_eth_sold: uint256(wei), deadline: timestamp, token_addr: address) -> uint256:
// #     exchange_addr: address = self.factory.getExchange(token_addr)
// #     return self.tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, msg.sender, exchange_addr)

// # # @notice Convert Tokens (self.token) to Tokens (token_addr) and transfers
// # #         Tokens (token_addr) to recipient.
// # # @dev User specifies maximum input and exact output.
// # # @param tokens_bought Amount of Tokens (token_addr) bought.
// # # @param max_tokens_sold Maximum Tokens (self.token) sold.
// # # @param max_eth_sold Maximum ETH purchased as intermediary.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @param recipient The address that receives output ETH.
// # # @param token_addr The address of the token being purchased.
// # # @return Amount of Tokens (self.token) sold.
// # @public
// # def tokenToTokenTransferOutput(tokens_bought: uint256, max_tokens_sold: uint256, max_eth_sold: uint256(wei), deadline: timestamp, recipient: address, token_addr: address) -> uint256:
// #     exchange_addr: address = self.factory.getExchange(token_addr)
// #     return self.tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, recipient, exchange_addr)

// # # @notice Convert Tokens (self.token) to Tokens (exchange_addr.token).
// # # @dev Allows trades through contracts that were not deployed from the same factory.
// # # @dev User specifies exact input and minimum output.
// # # @param tokens_sold Amount of Tokens sold.
// # # @param min_tokens_bought Minimum Tokens (token_addr) purchased.
// # # @param min_eth_bought Minimum ETH purchased as intermediary.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @param exchange_addr The address of the exchange for the token being purchased.
// # # @return Amount of Tokens (exchange_addr.token) bought.
// # @public
// # def tokenToExchangeSwapInput(tokens_sold: uint256, min_tokens_bought: uint256, min_eth_bought: uint256(wei), deadline: timestamp, exchange_addr: address) -> uint256:
// #     return self.tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, msg.sender, exchange_addr)

// # # @notice Convert Tokens (self.token) to Tokens (exchange_addr.token) and transfers
// # #         Tokens (exchange_addr.token) to recipient.
// # # @dev Allows trades through contracts that were not deployed from the same factory.
// # # @dev User specifies exact input and minimum output.
// # # @param tokens_sold Amount of Tokens sold.
// # # @param min_tokens_bought Minimum Tokens (token_addr) purchased.
// # # @param min_eth_bought Minimum ETH purchased as intermediary.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @param recipient The address that receives output ETH.
// # # @param exchange_addr The address of the exchange for the token being purchased.
// # # @return Amount of Tokens (exchange_addr.token) bought.
// # @public
// # def tokenToExchangeTransferInput(tokens_sold: uint256, min_tokens_bought: uint256, min_eth_bought: uint256(wei), deadline: timestamp, recipient: address, exchange_addr: address) -> uint256:
// #     assert recipient != self
// #     return self.tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, recipient, exchange_addr)

// # # @notice Convert Tokens (self.token) to Tokens (exchange_addr.token).
// # # @dev Allows trades through contracts that were not deployed from the same factory.
// # # @dev User specifies maximum input and exact output.
// # # @param tokens_bought Amount of Tokens (token_addr) bought.
// # # @param max_tokens_sold Maximum Tokens (self.token) sold.
// # # @param max_eth_sold Maximum ETH purchased as intermediary.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @param exchange_addr The address of the exchange for the token being purchased.
// # # @return Amount of Tokens (self.token) sold.
// # @public
// # def tokenToExchangeSwapOutput(tokens_bought: uint256, max_tokens_sold: uint256, max_eth_sold: uint256(wei), deadline: timestamp, exchange_addr: address) -> uint256:
// #     return self.tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, msg.sender, exchange_addr)

// # # @notice Convert Tokens (self.token) to Tokens (exchange_addr.token) and transfers
// # #         Tokens (exchange_addr.token) to recipient.
// # # @dev Allows trades through contracts that were not deployed from the same factory.
// # # @dev User specifies maximum input and exact output.
// # # @param tokens_bought Amount of Tokens (token_addr) bought.
// # # @param max_tokens_sold Maximum Tokens (self.token) sold.
// # # @param max_eth_sold Maximum ETH purchased as intermediary.
// # # @param deadline Time after which this transaction can no longer be executed.
// # # @param recipient The address that receives output ETH.
// # # @param token_addr The address of the token being purchased.
// # # @return Amount of Tokens (self.token) sold.
// # @public
// # def tokenToExchangeTransferOutput(tokens_bought: uint256, max_tokens_sold: uint256, max_eth_sold: uint256(wei), deadline: timestamp, recipient: address, exchange_addr: address) -> uint256:
// #     assert recipient != self
// #     return self.tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, recipient, exchange_addr)

// # # @notice Public price function for ETH to Token trades with an exact input.
// # # @param eth_sold Amount of ETH sold.
// # # @return Amount of Tokens that can be bought with input ETH.
// # @public
// # @constant
// # def getEthToTokenInputPrice(eth_sold: uint256(wei)) -> uint256:
// #     assert eth_sold > 0
// #     token_reserve: uint256 = self.token.balanceOf(self)
// #     return self.getInputPrice(as_unitless_number(eth_sold), as_unitless_number(self.balance), token_reserve)

// # # @notice Public price function for ETH to Token trades with an exact output.
// # # @param tokens_bought Amount of Tokens bought.
// # # @return Amount of ETH needed to buy output Tokens.
// # @public
// # @constant
// # def getEthToTokenOutputPrice(tokens_bought: uint256) -> uint256(wei):
// #     assert tokens_bought > 0
// #     token_reserve: uint256 = self.token.balanceOf(self)
// #     eth_sold: uint256 = self.getOutputPrice(tokens_bought, as_unitless_number(self.balance), token_reserve)
// #     return as_wei_value(eth_sold, 'wei')

// # # @notice Public price function for Token to ETH trades with an exact input.
// # # @param tokens_sold Amount of Tokens sold.
// # # @return Amount of ETH that can be bought with input Tokens.
// # @public
// # @constant
// # def getTokenToEthInputPrice(tokens_sold: uint256) -> uint256(wei):
// #     assert tokens_sold > 0
// #     token_reserve: uint256 = self.token.balanceOf(self)
// #     eth_bought: uint256 = self.getInputPrice(tokens_sold, token_reserve, as_unitless_number(self.balance))
// #     return as_wei_value(eth_bought, 'wei')

// # # @notice Public price function for Token to ETH trades with an exact output.
// # # @param eth_bought Amount of output ETH.
// # # @return Amount of Tokens needed to buy output ETH.
// # @public
// # @constant
// # def getTokenToEthOutputPrice(eth_bought: uint256(wei)) -> uint256:
// #     assert eth_bought > 0
// #     token_reserve: uint256 = self.token.balanceOf(self)
// #     return self.getOutputPrice(as_unitless_number(eth_bought), token_reserve, as_unitless_number(self.balance))

// # # @return Address of Token that is sold on this exchange.
// # @public
// # @constant
// # def tokenAddress() -> address:    s
// #     return self.token

// # @return Address of factory that created this exchange.
// @public
// @constant
// def factoryAddress() -> address(Factory):
//     return self.factory

// # # ERC20 compatibility for exchange liquidity modified from
// # # https://github.com/ethereum/vyper/blob/master/examples/tokens/ERC20.vy
// # @public
// # @constant
// # def balanceOf(_owner : address) -> uint256:
// #     return self.balances[_owner]

// # @public
// # def transfer(_to : address, _value : uint256) -> bool:
// #     self.balances[msg.sender] -= _value
// #     self.balances[_to] += _value
// #     log.Transfer(msg.sender, _to, _value)
// #     return True

// # @public
// # def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
// #     self.balances[_from] -= _value
// #     self.balances[_to] += _value
// #     self.allowances[_from][msg.sender] -= _value
// #     log.Transfer(_from, _to, _value)
// #     return True

// # @public
// # def approve(_spender : address, _value : uint256) -> bool:
// #     self.allowances[msg.sender][_spender] = _value
// #     log.Approval(msg.sender, _spender, _value)
// #     return True

// # @public
// # @constant
// # def allowance(_owner : address, _spender : address) -> uint256(wei):
// #     return self.allowances[_owner][_spender]
