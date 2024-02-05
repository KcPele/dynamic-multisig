//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//add ERC 20 to the smart contract
error MultiSig__OwnerMustBeGreaterThanOne();
error MultiSig__NotAddressZero();
error MultiSig__TransactionDoestNotExist();
error MultiSig__InvalidAddress();

contract MultiSig {
	address[] public owners;
	uint256 public numConfirmationRequired;

	struct Transaction {
		address to;
		uint256 amount;
		bool executed;
		address from;
	}
	IERC20 token;

	mapping(uint256 => mapping(address => bool)) isConfirmed;
	Transaction[] public transactions;

	event TransactionSubmitted(
		uint256 transactionsId,
		address sender,
		address receiver,
		uint256 amount
	);
	event TransactionConfirmed(uint256 transactionsId);
	event TransactionExecuted(uint256 transactionsId);

	modifier transactionExist(uint256 _transactionsId) {
		if (_transactionsId > transactions.length) {
			revert MultiSig__TransactionDoestNotExist();
		}
		_;
	}

	constructor(
		address[] memory _owners,
		uint256 _numComfirmationsRequired,
		address _token
	) {
		if (_owners.length < 1) {
			revert MultiSig__OwnerMustBeGreaterThanOne();
		}
		require(
			_numComfirmationsRequired > 0 &&
				numConfirmationRequired <= _owners.length,
			"Numof confirmations are not in signed with the number of owners"
		);
		for (uint256 i = 0; i < _owners.length; ) {
			if (_owners[i] == address(0)) {
				revert MultiSig__NotAddressZero();
			}
			owners.push(_owners[i]);
			unchecked {
				i++;
			}
		}
		numConfirmationRequired = _numComfirmationsRequired;
		token = IERC20(_token);
	}

	function submitTrasaction(address _to, uint256 _amount) public {
		if (_to == address(0)) {
			revert MultiSig__InvalidAddress();
		}
		require(_amount > 0, "Transfer amount must ne greater than 0");

		uint256 transactionsId = transactions.length;
		//approving the contract to have access to the token
		token.approve(address(this), _amount);
		transactions.push(
			Transaction({
				to: _to,
				amount: _amount,
				executed: false,
				from: msg.sender
			})
		);

		emit TransactionSubmitted(transactionsId, msg.sender, _to, _amount);
	}

	function confirmTransaction(
		uint256 _transactionsId
	) public transactionExist(_transactionsId) {
		//we need to check if msg.sender is part of owners
		require(
			!isConfirmed[_transactionsId][msg.sender],
			"transaction is already confrimed by the owner"
		);
		isConfirmed[_transactionsId][msg.sender] = true;
		emit TransactionConfirmed(_transactionsId);
		//pass
		if (isTransactionConfirmed(_transactionsId)) {
			executeTransaction(_transactionsId);
		}
	}

	function isTransactionConfirmed(
		uint256 _transactionsId
	) internal transactionExist(_transactionsId) returns (bool) {
		uint256 confirmationCount;
		for (uint256 i; i < owners.length; ) {
			if (isConfirmed[_transactionsId][owners[i]]) {
				confirmationCount++;
			}

			unchecked {
				i++;
			}
		}

		return confirmationCount >= numConfirmationRequired;
	}

	function executeTransaction(
		uint256 _transactionsId
	) public transactionExist(_transactionsId) {
		Transaction memory transaction = transactions[_transactionsId];
		require(!transaction.executed, "transaction already executed");
		token.transferFrom(address(this), transaction.to, transaction.amount);
		transactions[_transactionsId].executed = true;
		emit TransactionExecuted(_transactionsId);
	}

	function checkAllowance(
		uint256 _transactionsId
	) public view transactionExist(_transactionsId) returns (uint256) {
		return
			token.allowance(transactions[_transactionsId].from, address(this));
	}
}
