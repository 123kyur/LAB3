// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMM{
    address public immutable  token0;
    address public immutable  token1;
    uint public total_token0;
    uint public total_token1;
    uint public immutable conversionRate;
    mapping(address => uint) public balance;
    mapping(address => uint) public total_balance;
    constructor(address _token0, address _token1, uint _rate) {
        require(_token0 != address(0), "Token0 address cannot be zero");
        require(_token1 != address(0), "Token1 address cannot be zero");
        token0 = _token0;
        token1 = _token1;
        total_token0=IERC20(token0).balanceOf(address(this));
        total_token1=IERC20(token1).balanceOf(address(this));
        conversionRate=_rate;
    }
    function trade(address tokenFrom, uint256 fromAmount)  public  {
        uint need_token;
        require( tokenFrom == address(token0) ||  tokenFrom == address(token1),"invalid token");
        require( fromAmount > 0, "amount in = 0");
        IERC20(tokenFrom).transferFrom(msg.sender,address(this),fromAmount);
        if (tokenFrom==token0) {      //換token1給user
            need_token=fromAmount*10000/conversionRate;
            require(total_token1 >= need_token,"contract don't have enough token" );
            IERC20(token1).transfer(msg.sender,need_token);
        }
        else {               //換token0給user
            need_token=fromAmount*conversionRate/10000;
            require( total_token0 >= need_token,"contract don't have enough token" );
            IERC20(token0).transfer(msg.sender,need_token);
        }
        _update_total();
        
    }
    function provideLiquidity(uint256 token0Amount, uint256 token1Amount)public{
        uint take_token;
        require(IERC20(token0).balanceOf(msg.sender)>=token0Amount &&IERC20(token1).balanceOf(msg.sender)>=token1Amount,"user doesn't have enough token");
            take_token=token0Amount*total_token1/total_token0;
            if (take_token<=token1Amount){
                IERC20(token0).transferFrom(msg.sender,address(this),token0Amount);
                IERC20(token1).transferFrom(msg.sender,address(this),take_token);
                balance[msg.sender]=balance[msg.sender]+token0Amount*10000/conversionRate+take_token;
            }
            else{
                take_token=token1Amount*total_token0/total_token1;
                IERC20(token0).transferFrom(msg.sender,address(this),take_token);
                IERC20(token1).transferFrom(msg.sender,address(this),token1Amount);
                balance[msg.sender]=balance[msg.sender]+token1Amount+take_token*10000/conversionRate;
            }
        _update_total();
        total_balance[msg.sender]=total_token0*10000/conversionRate+total_token1;
    }
    function withdrawLiquidity () public {
        uint get_token0 = total_token0*balance[msg.sender]/total_balance[msg.sender];
        uint get_token1 = total_token1*balance[msg.sender]/total_balance[msg.sender];
        IERC20(token0).transfer(msg.sender,get_token0);
        IERC20(token1).transfer(msg.sender,get_token1);
        balance[msg.sender]=0;
        _update_total();
    }
    function provide_initial () public
    {
        IERC20(token0).transferFrom(msg.sender,address(this),1000*(10**18));
        IERC20(token1).transferFrom(msg.sender,address(this),1000*(10**18));
        _update_total();
    }
    function _update_total() private{
        total_token0=IERC20(token0).balanceOf(address(this));
        total_token1=IERC20(token1).balanceOf(address(this));
    } 

}