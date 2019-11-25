pragma solidity ^0.5.12;

import "./StandardToken.sol";
import "./SafeMath.sol";

// TODO: add events, revert messages
contract BaseExchange is StandardToken {
    using SafeMath for *;

    ERC20 public token1; // previously eth
    ERC20 public token2;

    uint public decimals = 18;

    event Test(uint a, uint b, uint c, uint d);

    constructor(address token1_, address token2_) public {
        require(token1_ != token2_);
        token1 = ERC20(token1_);
        token2 = ERC20(token2_);
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
        emit Test(token1_amount, min_liquidity, max_token2, deadline);
        // return 1;
        require(deadline > block.timestamp, "Timestamp");
        require(max_token2 > 0, "Max token 2 must be greater than 0");
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
        require(deadline > block.timestamp);
        require(min_token1 > 0);
        require(min_token2 > 0);
        require(totalSupply_ > 0);

        uint total_liquidity = totalSupply_; // again, uneccesary for the sake of gas?
        
        // amount / total liq is the portion of the pool you own.
        uint token1_amount = token1.balanceOf(address(this)).mul(amount).div(total_liquidity);
        uint token2_amount = token2.balanceOf(address(this)).mul(amount).div(total_liquidity);

        require(token1_amount > min_token1);
        require(token2_amount > min_token2);

        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply_ = total_liquidity.sub(amount);
        token1.transfer(msg.sender, token1_amount);
        token2.transfer(msg.sender, token2_amount);
        // XXX do events
        return (token1_amount, token2_amount);
    }

    function tokenSwapInput(
        ERC20 input_token,
        ERC20 output_token, 
        uint tokens_sold, 
        uint min_tokens_bought, 
        uint deadline, 
        address recipient
    )
        public returns (uint)
    {
        require(deadline >= block.timestamp);
        require(tokens_sold > 0);
        require(min_tokens_bought > 0);
        require(isExchange(input_token, output_token) == true, "BaseExchange:: Wrong exchange");

        uint input_token_reserve = input_token.balanceOf(address(this));
        uint output_token_reserve = output_token.balanceOf(address(this));
        uint tokens_bought = getInputPrice(tokens_sold, input_token_reserve, output_token_reserve);

        require(tokens_bought >= min_tokens_bought);

        input_token.transferFrom(msg.sender, address(this), tokens_sold);
        output_token.transfer(recipient, tokens_bought);

        return tokens_bought;
    }

    function tokenSwapOutput(
        ERC20 input_token, 
        ERC20 output_token, 
        uint tokens_bought, 
        uint min_tokens_bought,
        uint deadline, 
        address recipient
    ) 
        public returns (uint) 
    {
        require(deadline >= block.timestamp);
        require(tokens_bought > 0);
        require(min_tokens_bought > 0);
        require(isExchange(input_token, output_token) == true, "BaseExchange:: Wrong exchange");

        uint input_token_reserve = input_token.balanceOf(address(this));
        uint output_token_reserve = output_token.balanceOf(address(this));
        uint tokens_sold = getOutputPrice(tokens_bought, input_token_reserve, output_token_reserve);

        require(tokens_bought >= min_tokens_bought);

        input_token.transferFrom(msg.sender, address(this), tokens_sold);
        output_token.transfer(recipient, tokens_bought);

        return tokens_bought;
    }

    function getInputPrice(uint input_amount, ERC20 input_token, ERC20 output_token) public view returns (uint) {
        require(isExchange(input_token, output_token) == true, "BaseExchange:: Wrong exchange");
        
        uint input_token_reserve = input_token.balanceOf(address(this));
        uint output_token_reserve = output_token.balanceOf(address(this));
        return getInputPrice(input_amount, input_token_reserve, output_token_reserve);
    }

    function getOutputPrice(uint output_amount, ERC20 input_token, ERC20 output_token) public view returns (uint) {
        require(isExchange(input_token, output_token) == true, "BaseExchange:: Wrong exchange");
        
        uint input_token_reserve = input_token.balanceOf(address(this));
        uint output_token_reserve = output_token.balanceOf(address(this));
        return getOutputPrice(output_amount, input_token_reserve, output_token_reserve);
    }

    // TODO: add fee
    function flashBorrow(ERC20 borrow_token, uint borrow_amount, bytes memory data, address target) public {
        uint prev_balance = ERC20(borrow_token).balanceOf(address(this));
        ERC20(borrow_token).transfer(target, borrow_amount);
        target.call(data);
        require(borrow_token.balanceOf(address(this)) >= prev_balance);
    }

    function isExchange(ERC20 token1_, ERC20 token2_) public view returns (bool) {
        return (token1 == token1_ && token2 == token2_) || (token2 == token1_ && token1 == token2_);
    }

    function getInputPrice(uint input_amount, uint input_reserve, uint output_reserve) internal view returns (uint);

    function getOutputPrice(uint output_amount, uint input_reserve, uint output_reserve) internal view returns (uint);

}
