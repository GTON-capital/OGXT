// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title OGXT token distribution contract
 * @dev Claims contract
 **/
contract ClaimOGXT is ReentrancyGuard {

    /* ==========  State variables ========== */
    IERC20 public ogxt;
    mapping(address => uint) public allowance;
    mapping(address => bool) public didSignTheDisclaimer;

    /* ==========  Constants ========== */
    string public constant disclaimerAutoSignedByAllClaimers = 
        "By using this contract you certify that you are not a US citizen, resident or tax resident. "
        "By interacting with any smart contract on the GTON Capital protocol (including purchases via "
        "bonding, staking, withdrawals, approvals, interactions with any assets on chain), you expressly "
        "and unconditionally affirm that you are not a resident of the US and do not violate any local "
        "regulations if based in any other jurisdiction";

    /* ==========  Access control ========== */
    address public owner;
    address public newOwner;

    /* ========== Constructor ========== */
    constructor(
        IERC20 ogxt_
    ) {
        owner = msg.sender;
        ogxt = ogxt_;
    }

    /* ========== User actions ========== */
    function signLiabilityWaiverAndClaimOGXT() external nonReentrant {
        uint amount = allowance[msg.sender];
        require(amount > 0, "ClaimOGXT: No allowance");

        allowance[msg.sender] = 0;
        didSignTheDisclaimer[msg.sender] = true;
        require(ogxt.transfer(msg.sender, amount), "ClaimOGXT: transfer failed");
        emit Withdraw(msg.sender, amount);
    }

    /* ========== Views ========== */
    function canUserClaim(address user) external view returns (bool) {
        return allowance[user] > 0;
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
        require(msg.sender == newOwner, "ClaimOGXT: Claim from the wrong address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    /* ==========  Modifiers ========== */
    modifier onlyOwner() {
        require(msg.sender == owner, "ClaimOGXT: NOT_OWNER");
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
