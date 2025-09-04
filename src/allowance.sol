// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Allowance {
    address public parent;
    address public realChild;
    uint256 public dailyAllowanceLimit;
    mapping(address => mapping(uint256 => uint256)) public dailyWithdrawals; // child => day => amount
    uint256 public constant SECONDS_PER_DAY = 86400;

    event allowanceWithdrawn(
        address indexed child,
        uint256 amount,
        uint256 timestamp
    );

    constructor(uint256 _dailyAllowance) {
        parent = msg.sender;
        dailyAllowanceLimit = _dailyAllowance;
    }

    function depositAllowance() public payable {
        require(msg.sender == parent, "Only parent can deposit allowance");
        require(msg.value > 0, "Allowance must be greater than 0");
    }

    modifier onlyChild() {
        require(msg.sender == realChild, "Only child is allowed to withdraw");
        _;
    }

    modifier onlyParent() {
        require(msg.sender == parent, "Only parent can perform this action");
        _;
    }

    function setRealChild(address _child) public onlyParent {
        require(_child != address(0), "Invalid child address");
        realChild = _child;
    }

    function getCurrentDay() public view returns (uint256) {
        return block.timestamp / SECONDS_PER_DAY;
    }

    function getTodayWithdrawal() public view returns (uint256) {
        return dailyWithdrawals[realChild][getCurrentDay()];
    }

    function withdrawAllowance(uint256 _amount) public onlyChild {
        uint256 currentDay = getCurrentDay();
        uint256 todayWithdrawn = dailyWithdrawals[realChild][currentDay];

        require(
            todayWithdrawn + _amount <= dailyAllowanceLimit,
            "Daily limit exceeded"
        );
        require(_amount <= address(this).balance, "Insufficient balance");

        // Send ETH to child
        (bool success, ) = realChild.call{value: _amount}("");
        require(success, "Transfer failed");

        dailyWithdrawals[realChild][currentDay] += _amount;

        emit allowanceWithdrawn(realChild, _amount, block.timestamp);
    }

    function getTotalAllowance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalWithdrawnAmount() public view returns (uint256) {
        uint256 total = 0;
        uint256 currentDay = getCurrentDay();

        for (uint256 i = 0; i <= currentDay; i++) {
            total += dailyWithdrawals[realChild][i];
        }
        return total;
    }
}
