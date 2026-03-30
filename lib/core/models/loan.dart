enum LoanStatus { active, paid, defaulted }

class LoanExpense {
  final String description;
  final double amount;
  final DateTime date;

  LoanExpense({required this.description, required this.amount, required this.date});

  Map<String, dynamic> toMap() => {
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory LoanExpense.fromMap(Map<String, dynamic> map) => LoanExpense(
    description: map['description'],
    amount: map['amount'],
    date: DateTime.parse(map['date']),
  );
}

class LoanRepayment {
  final double amount;
  final DateTime date;

  LoanRepayment({required this.amount, required this.date});

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory LoanRepayment.fromMap(Map<String, dynamic> map) => LoanRepayment(
    amount: map['amount'],
    date: DateTime.parse(map['date']),
  );
}

class Loan {
  final String id;
  final String profileId;
  final String lenderName; // Added for manual tracking
  final double principalAmount;
  final double interestRate; 
  final DateTime issuedDate;
  final DateTime dueDate;
  final List<LoanExpense> expenses; // How she used the money
  final List<LoanRepayment> repayments; // Her repayment track record
  LoanStatus status;

  Loan({
    required this.id,
    required this.profileId,
    required this.lenderName,
    required this.principalAmount,
    required this.interestRate,
    required this.issuedDate,
    required this.dueDate,
    this.expenses = const [],
    this.repayments = const [],
    this.status = LoanStatus.active,
  });

  double get totalInterest => principalAmount * interestRate;
  double get totalToRepay => principalAmount + totalInterest;
  double get totalPaid => repayments.fold(0.0, (sum, item) => sum + item.amount);
  double get balance => totalToRepay - totalPaid;
  double get progress => totalToRepay > 0 ? (totalPaid / totalToRepay) : 0.0;
  double get totalSpent => expenses.fold(0.0, (sum, item) => sum + item.amount);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'lenderName': lenderName,
      'principalAmount': principalAmount,
      'interestRate': interestRate,
      'issuedDate': issuedDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      // We will store these as JSON strings in the DB for simplicity in this prototype
    };
  }
}
