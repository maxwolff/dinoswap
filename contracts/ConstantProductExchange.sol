pragma solidity ^0.5.12;

import "./BaseExchange.sol";

contract ConstantProductExchange is BaseExchange {

	// eg: 997 / 1000 => 0.3% fee
    uint public fee;
    uint public feePrecision;
    string public symbol;

    // TODO: name
    constructor(address token1_, address token2_, uint fee_, uint feePrecision_, string memory symbol_) 
    	public BaseExchange (token1_, token2_) 
    {
        require(token1_ != token2_);
        token1 = IERC20(token1_);
        token2 = IERC20(token2_);
        fee = fee_;
        feePrecision = feePrecision_;
        symbol = symbol_;
    }

	function getOutputPrice(
		uint output_amount,
		uint input_reserve,
		uint output_reserve
	) 
		internal view returns (uint)
	{
        // uncessecary checks?    
        require(input_reserve > 0);
        require(output_reserve > 0);

        uint numerator = input_reserve.mul(output_reserve).mul(feePrecision);
        uint denominator = output_reserve.sub(output_amount).mul(fee);

        return numerator.div(denominator).add(1);
    }

    function getInputPrice(
    	uint input_amount, 
    	uint input_reserve, 
    	uint output_reserve
    ) 
    	internal view returns (uint)
    {
        // uncessecary checks?
        require(input_reserve > 0);
        require(output_reserve > 0);

        uint input_amount_with_fee = input_amount.mul(fee);
        uint numerator = input_amount_with_fee.mul(output_reserve);
        uint denominator = input_reserve.mul(feePrecision).add(input_amount_with_fee);

        return numerator.div(denominator);
    }
}