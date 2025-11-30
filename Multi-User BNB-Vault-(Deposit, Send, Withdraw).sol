// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Multi Wallet BNB Vault
/// @notice Accepts BNB from multiple users, tracks balances, allows send & withdraw
contract MultiWalletVault {
    /// @dev Balance of each user inside the vault
    mapping(address => uint256) public balances;

    /// @dev Simple reentrancy guard
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Sent(address indexed from, address indexed to, uint256 amount);

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrancy");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /// @notice Deposit BNB into your vault balance
    /// @dev msg.value will be added to msg.sender's internal balance
    function deposit() public payable {
        require(msg.value > 0, "No BNB sent");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Fallback for direct BNB transfers
    /// @dev Sending BNB directly to the contract also counts as deposit()
    receive() external payable {
        require(msg.value > 0, "No BNB sent");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraw a specific amount of your BNB from the vault
    /// @param amount Amount of BNB in wei to withdraw
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount = 0");
        uint256 bal = balances[msg.sender];
        require(bal >= amount, "Insufficient balance");

        balances[msg.sender] = bal - amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Withdraw your full balance
    function withdrawAll() external nonReentrant {
        uint256 bal = balances[msg.sender];
        require(bal > 0, "Nothing to withdraw");

        balances[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: bal}("");
        require(success, "Withdraw failed");

        emit Withdrawn(msg.sender, bal);
    }

    /// @notice Send BNB from your vault balance to another wallet
    /// @dev BNB is sent directly from contract to `to`, deducted from sender's balance
    /// @param to Recipient address
    /// @param amount Amount in wei to send
    function sendTo(address payable to, uint256 amount) external nonReentrant {
        require(to != address(0), "Zero address");
        require(amount > 0, "Amount = 0");
        uint256 bal = balances[msg.sender];
        require(bal >= amount, "Insufficient balance");

        balances[msg.sender] = bal - amount;

        (bool success, ) = to.call{value: amount}("");
        require(success, "Send failed");

        emit Sent(msg.sender, to, amount);
    }

    /// @notice View your current vault balance
    function myBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    /// @notice View vault balance of any user (public info)
    /// @param user Address to check
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    /// @notice Total BNB held by this contract (sum of all users)
    function totalVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
