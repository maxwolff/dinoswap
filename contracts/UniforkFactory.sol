pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;

import "./UniforkExchange.sol";
import "./SafeMath.sol";

contract IExchange {
    address public token1;
}

contract UniforkFactory {
    using SafeMath for *;
    
    struct TokenPair {
        address token1;
        address token2;
    }

    uint public tokenCount;

    mapping (address => mapping (address => address)) public token_to_exchange;
    mapping (address => TokenPair) public exchange_to_tokenPair;
    mapping (uint => TokenPair) public id_to_token;

    function createExchange(address token1, address token2) external returns (address) {
        require(token1 != address(0) && token2 != address(0));
        require(token1 != token2);

        require(token_to_exchange[token1][token2] == address(0));
        require(token_to_exchange[token2][token1] == address(0));

        UniforkExchange exchange = new UniforkExchange(token1, token2);
        token_to_exchange[token1][token2] = address(exchange);
        tokenCount ++;
        exchange_to_tokenPair[address(exchange)] = TokenPair(token1, token2);
        id_to_token[tokenCount] = TokenPair(token1, token2);
        return address(exchange);
    }

    function getExchange(address token1, address token2) external view returns (address) {
        return token_to_exchange[token1][token2];
    }

    function getTokenPair(address exchange) external view returns (TokenPair memory) {
        return exchange_to_tokenPair[exchange];
    }

    function getTokenPairWithId(uint token_id) external view returns (TokenPair memory) {
        return id_to_token[token_id];
    }
}
