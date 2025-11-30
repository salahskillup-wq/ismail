// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title BNB Payment Gateway
/// @notice Accepts BNB payments, logs them, and lets the owner withdraw.
contract BnbPaymentGateway {
    address public owner;

    struct Payment {
        address from;
        uint256 amount;
        uint256 timestamp;
        string reference; // e.g. order ID, user ID, product ID
    }

    Payment[] public payments;

    event PaymentReceived(
        address indexed from,
        uint256 amount,
        string reference,
        uint256 timestamp
    );

    event Withdraw(address indexed to, uint256 amount);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Make a payment in BNB
    /// @param reference Any string you want to store (order id, etc.)
    function pay(string calldata reference) external payable {
        require(msg.value > 0, "No BNB sent");

        payments.push(
            Payment({
                from: msg.sender,
                amount: msg.value,
                timestamp: block.timestamp,
                reference: reference
            })
        );

        emit PaymentReceived(msg.sender, msg.value, reference, block.timestamp);
    }

    /// @notice Fallback receive function (if someone sends BNB directly)
    receive() external payable {
        payments.push(
            Payment({
                from: msg.sender,
                amount: msg.value,
                timestamp: block.timestamp,
                reference: "DIRECT_TRANSFER"
            })
        );

        emit PaymentReceived(msg.sender, msg.value, "DIRECT_TRANSFER", block.timestamp);
    }

    /// @notice Withdraw specific amount of BNB to owner
    /// @param amount Amount in wei
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough balance");

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdraw failed");

        emit Withdraw(owner, amount);
    }

    /// @notice Withdraw all BNB to owner
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdraw failed");

        emit Withdraw(owner, balance);
    }

    /// @notice Change the owner of the contract
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Get total number of payment records
    function getPaymentsCount() external view returns (uint256) {
        return payments.length;
    }

    /// @notice Get a payment by index
    function getPayment(uint256 index)
        external
        view
        returns (address from, uint256 amount, uint256 timestamp, string memory reference)
    {
        require(index < payments.length, "Out of range");
        Payment storage p = payments[index];
        return (p.from, p.amount, p.timestamp, p.reference);
    }
}
