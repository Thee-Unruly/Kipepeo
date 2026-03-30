enum TransactionType { inflow, outflow }

// Base class for any financial transaction
abstract class FinancialTransaction {
  String get id;
  double get amount;
  DateTime get timestamp;
  TransactionType get type;
}

// Represents a mobile money transaction parsed from SMS
class MobileTransaction implements FinancialTransaction {
  final String id;
  final String sender;
  final double amount;
  final DateTime timestamp;
  final TransactionType type;
  final String reference;
  final String category;
  final String rawBody;

  MobileTransaction({
    required this.id,
    required this.sender,
    required this.amount,
    required this.timestamp,
    required this.type,
    required this.reference,
    required this.category,
    required this.rawBody,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'sender': sender,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'reference': reference,
    'category': category,
    'rawBody': rawBody,
  };

  factory MobileTransaction.fromMap(Map<String, dynamic> map) => MobileTransaction(
    id: map['id'],
    sender: map['sender'],
    amount: map['amount'],
    timestamp: DateTime.parse(map['timestamp']),
    type: TransactionType.values.byName(map['type']),
    reference: map['reference'],
    category: map['category'] ?? 'General',
    rawBody: map['rawBody'],
  );
}

// Represents a manually entered cash transaction
class CashTransaction implements FinancialTransaction {
  final String id;
  final String description;
  final double amount;
  final DateTime timestamp;
  final TransactionType type;
  final String? category; // e.g., 'Sales', 'Stock Purchase', 'Rent', 'Other'

  CashTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.timestamp,
    required this.type,
    this.category,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'category': category,
  };

  factory CashTransaction.fromMap(Map<String, dynamic> map) => CashTransaction(
    id: map['id'],
    description: map['description'],
    amount: map['amount'],
    timestamp: DateTime.parse(map['timestamp']),
    type: TransactionType.values.byName(map['type']),
    category: map['category'],
  );
}
