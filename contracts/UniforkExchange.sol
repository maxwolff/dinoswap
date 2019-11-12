pragma solidity ^0.5.12;

import "./StandardToken.sol";
import "./SafeMath.sol";

contract IFactory {
    function getExchange(address token1, address token2) external view returns (address);
}

// TODOS:
// * use safemath, check overflows, add requires
// * add events, add helpers
contract UniforkExchange is StandardToken {
    using SafeMath for *;

    IFactory public factory; // dont need getter i think
    ERC20 public token1; // prev eth
    ERC20 public token2;

    string public name = "UniforkExchange 1.0";
    string public symbol = "UNIFORK-V1";
    uint public decimals = 18;
    // uint public totalSupply_; // based off of token1 (prev eth)

    // 997 / 1000 => 0.997 => 0.3% fee
    // todo add to constructor
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
    // XXX use private? 
    function getInputPrice(uint input_amount, uint input_reserve, uint output_reserve) internal view returns (uint) {
        // uncessecary checks?
        require(input_reserve > 0);
        require(output_reserve > 0);

        // if (price model != 0), do pricemodel.getPrice()
        uint input_amount_with_fee = input_amount * feeConstant;
        uint numerator = input_amount_with_fee * output_reserve;
        uint denominator = (input_reserve * feePrecision) + input_amount_with_fee;

        return numerator / denominator;
    }

    function getOutputPrice(uint output_amount, uint input_reserve, uint output_reserve) internal view returns (uint) {
        // uncessecary checks?    
        require(input_reserve > 0);
        require(output_reserve > 0);

        // if (price model != 0), do pricemodel.getPrice()
        uint numerator = input_reserve * output_reserve * feePrecision;
        uint denominator = (output_reserve - output_amount) * feeConstant;

        return numerator / denominator + 1;
    }

    function tokenSwapInput(
        address buy_token, 
        address sell_token,
        uint tokens_sold, 
        uint min_tokens_bought, 
        uint deadline, 
        address recipient
    )
        public returns (uint)
    {
        require(deadline >= getBlockTimestamp());
        require(tokens_sold > 0);
        require(min_tokens_bought > 0);

        uint buy_token_reserve = ERC20(buy_token).balanceOf(address(this));
        uint sell_token_reserve = ERC20(sell_token).balanceOf(address(this));
        uint tokens_bought = getInputPrice(tokens_sold, sell_token_reserve, buy_token_reserve);

        require(tokens_bought >= min_tokens_bought);

        ERC20(sell_token).transferFrom(msg.sender, address(this), tokens_sold);
        ERC20(buy_token).transfer(recipient, tokens_bought);

        return tokens_bought;
    }

    function tokenSwapOutput(
        address buy_token, 
        address sell_token, 
        uint tokens_bought, 
        uint min_tokens_bought,
        uint deadline, 
        address recipient
    ) 
        public returns (uint) 
    {
        require(deadline >= getBlockTimestamp());
        require(tokens_bought > 0);
        require(min_tokens_bought > 0);

        uint buy_token_reserve = ERC20(buy_token).balanceOf(address(this));
        uint sell_token_reserve = ERC20(sell_token).balanceOf(address(this));
        uint tokens_sold = getOutputPrice(tokens_bought, sell_token_reserve, buy_token_reserve);

        require(tokens_bought >= min_tokens_bought);

        ERC20(sell_token).transferFrom(msg.sender, address(this), tokens_sold);
        ERC20(buy_token).transfer(recipient, tokens_bought);

        return tokens_bought;
    }

    // TODO: add fee
    function flashBorrow(address borrow_token, uint amount, bytes memory data, address target) public {
        uint prevBalance = ERC20(borrow_token).balanceOf(address(this));
        ERC20(borrow_token).transfer(target, amount);
        target.call(data);
        require(ERC20(borrow_token).balanceOf(address(this)) >= prevBalance);
    }

}
