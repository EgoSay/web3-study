// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract BaseERC20 {

    using SafeMath for uint256;

    string public name; 
    string public symbol; 
    uint8 public decimals; 

    uint256 public totalSupply; 

    mapping (address => uint256) balances; 

    mapping (address => mapping (address => uint256)) allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        // write your code here
        // set name,symbol,decimals,totalSupply
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000 * 10 ** decimals;
        balances[msg.sender] = totalSupply;  
    }

    // 允许任何人查看任何地址的 Token 余额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        // write your code here
        return balances[_owner];
    }

    // 允许 Token 的所有者将他们的 Token 发送给任何人（transfer）；
    // 转帐超出余额时抛出异常(require),并显示错误消息 “ERC20: transfer amount exceeds balance”
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(_value <= balances[msg.sender], "ERC20: transfer amount exceeds balance");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    // 允许被授权的地址消费他们被授权的 Token 数量（transferFrom）；
    // 转帐超出余额时抛出异常(require)，异常信息：“ERC20: transfer amount exceeds balance”
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(_value <= balances[_from], "ERC20: transfer amount exceeds balance");
        require(_value <= allowances[_from][msg.sender], "ERC20: transfer amount exceeds allowance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value); 
        return true; 
    }

    // 允许 Token 的所有者批准某个地址消费他们的一部分Token
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // write your code here
        require(_spender != address(0));
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    // 允许任何人查看一个地址可以从其它账户中转账的代币数量
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        // write your code here     
        return allowances[_owner][_spender];
    }
}