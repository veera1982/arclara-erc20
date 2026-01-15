// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ArclaraToken
 * @dev ERC20 Token for Arclara Blockchain
 * Total Supply: 1,000,000,000 ARC tokens
 * All tokens initially allocated to contract deployer
 */
contract ArclaraToken {
    string public constant name = "Arclara";
    string public constant symbol = "ARC";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // Staking for Proof of Stake
    mapping(address => uint256) public stakedBalance;
    mapping(address => bool) public isValidator;
    address[] public validators;
    
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        totalSupply = 1_000_000_000 * 10**uint256(decimals); // 1 billion tokens
        balanceOf[msg.sender] = totalSupply;
        
        // Owner is initial validator
        isValidator[msg.sender] = true;
        validators.push(msg.sender);
        
        emit Transfer(address(0), msg.sender, totalSupply);
        emit ValidatorAdded(msg.sender);
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        require(to != address(0), "Invalid address");
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        return true;
    }
    
    // Proof of Stake Functions
    function stake(uint256 amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Amount must be greater than 0");
        
        balanceOf[msg.sender] -= amount;
        stakedBalance[msg.sender] += amount;
        
        // Become validator if staking enough (e.g., 1000 ARC minimum)
        if (stakedBalance[msg.sender] >= 1000 * 10**uint256(decimals) && !isValidator[msg.sender]) {
            isValidator[msg.sender] = true;
            validators.push(msg.sender);
            emit ValidatorAdded(msg.sender);
        }
        
        emit Staked(msg.sender, amount);
        return true;
    }
    
    function unstake(uint256 amount) public returns (bool success) {
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance");
        require(amount > 0, "Amount must be greater than 0");
        
        stakedBalance[msg.sender] -= amount;
        balanceOf[msg.sender] += amount;
        
        // Remove validator status if stake falls below minimum
        if (stakedBalance[msg.sender] < 1000 * 10**uint256(decimals) && isValidator[msg.sender]) {
            isValidator[msg.sender] = false;
            removeValidatorFromArray(msg.sender);
            emit ValidatorRemoved(msg.sender);
        }
        
        emit Unstaked(msg.sender, amount);
        return true;
    }
    
    function removeValidatorFromArray(address validator) private {
        for (uint i = 0; i < validators.length; i++) {
            if (validators[i] == validator) {
                validators[i] = validators[validators.length - 1];
                validators.pop();
                break;
            }
        }
    }
    
    function getValidators() public view returns (address[] memory) {
        return validators;
    }
    
    function getValidatorCount() public view returns (uint256) {
        return validators.length;
    }
    
    function getTotalStaked() public view returns (uint256) {
        uint256 total = 0;
        for (uint i = 0; i < validators.length; i++) {
            total += stakedBalance[validators[i]];
        }
        return total;
    }
}
