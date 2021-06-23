// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.1/contracts/token/ERC20/ERC20.sol";

contract Owned {
    address public owner;
    address public nominatedOwner;
    address public benefitial;
    constructor(address _owner) public {
        require(_owner != address(0), 'Owner address cannot be 0');
        owner = _owner;
        benefitial = _owner;
        emit OwnerChanged(address(0), _owner);
    }
    function nominateNewOwner(address _owner) external isOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }
    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, 'You must be nominated before you can accept ownership');
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }
    function transferBenefitial(address _benefitial) external isOwner {
        address oldBenefitial = benefitial;
        benefitial = _benefitial;
        emit BenefitialChanged(oldBenefitial, benefitial);
    }
    modifier isOwner() {
        require(owner == msg.sender, "You are not Owner");
        _;
    }
    
    event OwnerNominated(address indexed newOwner);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event BenefitialChanged(address indexed oldBenefitial, address indexed newBenefitial);
}

contract RCG is ERC20, Owned {
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string public constant tokenName = "Recharge";
  string public constant tokenSymbol = "RCG";
  uint256 _totalSupply = 0;
  uint256 public basePercent = 0;

  constructor(address _owner, uint256 amount) ERC20(tokenName, tokenSymbol) Owned(_owner) {
    _issue(msg.sender, amount);
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
    _balances[benefitial] = _balances[benefitial]+tokensToBurn;

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, benefitial, tokensToBurn);
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
    _balances[benefitial] = _balances[benefitial]+tokensToBurn;

    _allowed[from][msg.sender] = _allowed[from][msg.sender]-value;

    emit Approval(from, msg.sender, _allowed[from][msg.sender]);
    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, benefitial, tokensToBurn);

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
