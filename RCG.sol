// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract RCG is ERC20 {
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => mapping (uint256 => uint256)) private PullQ; // address, permission, timestamp

  string constant tokenName = "Recharge";
  string constant tokenSymbol = "RCG";
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
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /** @notice From address sends value to address.
              However, this function can only be performed by a spender 
              who is entitled to withdraw through the aprove function. 
  */
  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    require(to != address(0));

    _balances[from] = _balances[from]-value;

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value-tokensToBurn;

    _balances[to] = _balances[to]+tokensToTransfer;
    _balances[Benefitial] = _balances[Benefitial]+tokensToBurn;

    _allowed[from][msg.sender] = _allowed[from][msg.sender]-value;

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, Benefitial, tokensToBurn);

    return true;
  }

  /// @notice Add the value of the privilege granted through the allowance function
  function upAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender]+addedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /// @notice Subtract the value of the privilege granted through the allowance function
  function downAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender]-subtractedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /// @notice Issue token from 0x address
  function _issue(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account]+amount;
    emit Transfer(address(0), account, amount);
  }

  /// @notice Returns _destory function
  function destroy(uint256 amount) external {
    _destroy(msg.sender, amount);
  }

  /// @notice Destroy the token by transferring it to the 0x address.
  function _destroy(address account, uint256 amount) internal {
    require(amount != 0);
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
  }
    
}
