enum LoanStatus { active, paid, defaulted }

class Loan {
  final String id;
  final String profileId;
  final double principalAmount;
  final double interestRate; // e.g., 0.1 for 10%
  final double totalToRepay;
  final double amountPaid;
  final DateTime issuedDate;
  final DateTime dueDate;
  final LoanStatus status;

  Loan({
    required this.id,
    required this.profileId,
    required this.principalAmount,
    required this.interestRate,
    required this.totalToRepay,
    this.amountPaid = 0.0,
    required this.issuedDate,
    required this.dueDate,
    this.status = LoanStatus.active,
  });

  double get remainingBalance => totalToRepay - amountPaid;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'principalAmount': principalAmount,
      'interestRate': interestRate,
      'totalToRepay': totalToRepay,
      'amountPaid': amountPaid,
      'issuedDate': issuedDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'],
      profileId: map['profileId'],
      principalAmount: map['principalAmount'],
      interestRate: map['interestRate'],
      totalToRepay: map['totalToRepay'],
      amountPaid: map['amountPaid'] ?? 0.0,
      issuedDate: DateTime.parse(map['issuedDate']),
      dueDate: DateTime.parse(map['dueDate']),
      status: LoanStatus.values.byName(map['status']),
    );
  }
}
