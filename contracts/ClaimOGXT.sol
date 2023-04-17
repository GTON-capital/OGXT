// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title OGXT token distribution contract
 * @dev Claims contract
 **/
contract ClaimOGXT is ReentrancyGuard {

    /* ==========  Access control ========== */
    address public owner;
    address public newOwner;

    /* ==========  State variables ========== */
    IERC20 public ogxt;
    mapping(address => uint) public allowance;
    
    /* ========== Constructor ========== */
    constructor(
        IERC20 ogxt_
    ) {
        owner = msg.sender;
        ogxt = ogxt_;
    }

    /* ========== User actions ========== */
    function claimOGXT() external nonReentrant {
        uint amount = allowance[msg.sender];
        require(amount > 0, "ClaimOGXT: No allowance");

        allowance[msg.sender] = 0;
        require(ogxt.transfer(msg.sender, amount), "ClaimOGXT: transfer failed");
        emit Withdraw(msg.sender, amount);
    }

    /* ========== Restricted methods ========== */
    function withdrawToken(
        IERC20 tokenToWithdraw, 
        address to, 
        uint amount
    ) external onlyOwner {
        require(tokenToWithdraw.transfer(to, amount));
    }

    function setUserInfo(
        address user, 
        uint amount
    ) external onlyOwner {
        allowance[user] = amount;
        emit UserClaimAdded(user, amount);
    }

    /* ========== Access control methods ========== */
    function transferOwnership(address _newOwner) external onlyOwner {
        emit OwnerTransferRequested(owner, _newOwner);
        newOwner = _newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == newOwner, "Claim from wrong address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    /* ==========  Modifiers ========== */
    modifier onlyOwner() {
        require(msg.sender == owner, "OGXT: NOT_OWNER");
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

    event UserClaimAdded(address indexed user, uint indexed amount);
    event Withdraw(address indexed user, uint indexed amount);
}
