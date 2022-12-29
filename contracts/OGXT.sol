// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title OGXT token implementation
 * @dev ERC20 token
 **/
contract OGXT is Initializable, UUPSUpgradeable {

    /* ==========  Access control ========== */
    address public owner;
    address public newOwner;
    mapping(address => bool) admins;

    /* ==========  Token details ========== */
    string public constant name = "OGXT";
    string public constant symbol = "OGXT";
    string public constant version = "1";
    uint8 public constant decimals = 18;
    
    /* ==========  State variables ========== */
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    /* ========== Upgrade-related methods ========== */
    function initialize() public initializer {
        owner = msg.sender;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /* ========== Mint/burn ========== */
    function mint(address to, uint amount) external onlyMinter {
        require(to != address(0), "OGXT: ZERO_ADDRESS");

        balanceOf[to] = balanceOf[to] + amount;
        totalSupply = totalSupply + amount;

        emit Transfer(address(0), to, amount);
    }

    function burn(uint amount) external onlyMinter {
        _burn(msg.sender, amount);
    }

    /* ========== User actions ========== */
    function transfer(address to, uint amount) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount) public returns (bool) {
        require(to != address(0), "OGXT: ZERO_ADDRESS");
        require(balanceOf[from] >= amount, "OGXT: INSUFFICIENT_BALANCE");

        if (from != msg.sender) {
            require(allowance[from][msg.sender] >= amount, "OGXT: INSUFFICIENT_ALLOWANCE");
            _approve(from, msg.sender, allowance[from][msg.sender] - amount);
        }
        balanceOf[from] = balanceOf[from] - amount;
        balanceOf[to] = balanceOf[to] + amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] - subtractedValue);
        return true;
    }

    /* ========== Internal methods ========== */
    function _approve(address holder, address spender, uint amount) internal virtual {
        require(holder != address(0), "OGXT: approve from the zero address");
        require(spender != address(0), "OGXT: approve to the zero address");

        allowance[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }

    function _burn(address from, uint amount) internal virtual {
        balanceOf[from] -= amount;
        totalSupply -= amount;

        emit Transfer(from, address(0), amount);
    }

    /* ========== Access control methods ========== */
    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnerTransferRequested(owner, _newOwner);
        newOwner = _newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == newOwner, "Claim from wrong address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    function addAdmin(address user) public onlyOwner {
        emit AdminAdded(user);
        admins[user] = true;
    }

    function removeAdmin(address user) public onlyOwner {
        emit AdminRemoved(user);
        admins[user] = false;
    }

    /* ==========  Modifiers ========== */
    modifier onlyOwner() {
        require(msg.sender == owner, "OGXT: NOT_OWNER");
        _;
    }

    modifier onlyMinter() {
        require(admins[msg.sender], "OGXT: AUTH_FAILED");
        _;
    }

    /* ========== Events ========== */
    event OwnerTransferRequested(
        address indexed oldOwner, 
        address indexed newOwner
    );

    event OwnershipTransferred(
        address indexed oldOwner, 
        address indexed newOwner
    );

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}
