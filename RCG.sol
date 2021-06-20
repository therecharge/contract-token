// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.1/contracts/token/ERC20/ERC20.sol";

contract RCG is ERC20 {
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => mapping (uint256 => uint256)) private PullQ; // address, permission, timestamp

  string public constant tokenName = "Recharge";
  string public constant tokenSymbol = "RCG";
  uint256 _totalSupply = 0;
  uint256 public basePercent = 0;
  address public Owner = address(0);
  address public Benefitial = address(0);

  constructor(uint256 amount) ERC20(tokenName, tokenSymbol) {
    _issue(msg.sender, amount);
    Owner = msg.sender;
    Benefitial = msg.sender;
  }

    modifier isOwner() {
        require(Owner == msg.sender, "You are not Owner");
        _;
    }
    
    function transferPermission(address To, uint256 perm) isOwner public {
        PullQ[To][perm] = block.timestamp;
    }
    
    function pullOwner() public {
        require(PullQ[msg.sender][0] > PullQ[Owner][0], "You cannot be Owner");
        Owner = msg.sender;
    }
    function pullBeneficial() public {
        require(PullQ[msg.sender][1] > PullQ[Owner][1], "You cannot be Owner");
        Benefitial = msg.sender;
    }
    
  function changeBurnRate(uint256 rate) public isOwner returns (bool){
    basePercent = rate;
    return true;
  }
  
  /// @notice Returns total token supply
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /// @notice Returns user balance
  function balanceOf(address owner) public view override returns (uint256) {
    return _balances[owner];
  }

  /// @notice Returns number of tokens that the owner has allowed the spender to withdraw
  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowed[owner][spender];
  }

  /// @notice Returns value of calculate the quantity to destory during transfer
  function cut(uint256 value) public view returns (uint256)  {
    if(basePercent==0) return 0;
    uint256 c = value+basePercent;
    uint256 d = c-1;
    uint256 roundValue = d/basePercent*basePercent;
    uint256 cutValue = roundValue*basePercent/10000;
    return cutValue;
  }

  /// @notice From owner address sends value to address.
  function transfer(address to, uint256 value) public override returns (bool) {
    require(to != address(0), "Address cannot be 0x0");
      
    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value-tokensToBurn;

    _balances[msg.sender] = _balances[msg.sender]-value;
    _balances[to] = _balances[to]+tokensToTransfer;
    _balances[Benefitial] = _balances[Benefitial]+tokensToBurn;

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, Benefitial, tokensToBurn);
    return true;
  }

  /// @notice Give Spender the right to withdraw as much tokens as value
  function approve(address spender, uint256 value) public override returns (bool) {
    require(spender != address(0), "Address cannot be 0x0");
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /** @notice From address sends value to address.
              However, this function can only be performed by a spender 
              who is entitled to withdraw through the aprove function. 
  */
  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    require(to != address(0), "Address cannot be 0x0");

    _balances[from] = _balances[from]-value;

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value-tokensToBurn;

    _balances[to] = _balances[to]+tokensToTransfer;
    _balances[Benefitial] = _balances[Benefitial]+tokensToBurn;

    _allowed[from][msg.sender] = _allowed[from][msg.sender]-value;

    emit Approval(from, msg.sender, _allowed[from][msg.sender]);
    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, Benefitial, tokensToBurn);

    return true;
  }

  /// @notice Add the value of the privilege granted through the allowance function
  function upAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0), "Address cannot be 0x0");
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender]+addedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /// @notice Subtract the value of the privilege granted through the allowance function
  function downAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0), "Address cannot be 0x0");
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender]-subtractedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /// @notice Issue token from 0x address
  function _issue(address account, uint256 amount) internal {
    require(amount != 0, "Amount cannot be 0");
    _balances[account] = _balances[account]+amount;
    emit Transfer(address(0), account, amount);
  }

  /// @notice Returns _destory function
  function destroy(uint256 amount) external {
    _destroy(msg.sender, amount);
  }

  /// @notice Destroy the token by transferring it to the 0x address.
  function _destroy(address account, uint256 amount) internal {
    require(amount != 0, "Amount Cannot be 0");
    _balances[account] = _balances[account]-amount;
    _totalSupply = _totalSupply-amount;
    emit Transfer(account, address(0), amount);
  }

  /** @notice From address sends value 0x address.
              However, this function can only be performed by a spender 
              who is entitled to withdraw through the aprove function. 
  */
  function destroyFrom(address account, uint256 amount) external {
    _allowed[account][msg.sender] = _allowed[account][msg.sender]-amount;
    _destroy(account, amount);

    emit Approval(account, msg.sender, _allowed[account][msg.sender]);
  }
    
}
