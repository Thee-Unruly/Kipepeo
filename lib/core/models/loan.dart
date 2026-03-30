enum LoanStatus { active, paid, defaulted }

class LoanExpense {
  final String description;
  final String category; // e.g., 'Stock', 'Transport', 'Rent', 'Other'
  final double amount;
  final DateTime date;

  LoanExpense({
    required this.description, 
    required this.category, 
    required this.amount, 
    required this.date
  });

  Map<String, dynamic> toMap() => {
    'description': description,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory LoanExpense.fromMap(Map<String, dynamic> map) => LoanExpense(
    description: map['description'],
    category: map['category'] ?? 'Other',
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
  final String lenderName;
  final double principalAmount;
  final double interestRate; 
  final DateTime issuedDate;
  final DateTime dueDate;
  final List<LoanExpense> expenses;
  final List<LoanRepayment> repayments;
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
  
  // Utilization Efficiency: % of principal spent on business (Stock/Transport)
  double get businessUtilization {
    if (principalAmount <= 0) return 0.0;
    final bizSpent = expenses
        .where((e) => e.category == 'Stock' || e.category == 'Transport')
        .fold(0.0, (sum, item) => sum + item.amount);
    return (bizSpent / principalAmount).clamp(0.0, 1.0);
  }

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
    };
  }
}
