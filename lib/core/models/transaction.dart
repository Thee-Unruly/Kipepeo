class MobileTransaction {
  final String? id;
  final String sender;
  final double amount;
  final DateTime timestamp;
  final String type; // 'DEBIT' or 'CREDIT'
  final String reference;
  final String rawBody;

  MobileTransaction({
    this.id,
    required this.sender,
    required this.amount,
    required this.timestamp,
    required this.type,
    required this.reference,
    required this.rawBody,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'reference': reference,
      'rawBody': rawBody,
    };
  }

  factory MobileTransaction.fromMap(Map<String, dynamic> map) {
    return MobileTransaction(
      id: map['id'],
      sender: map['sender'],
      amount: map['amount'],
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      reference: map['reference'],
      rawBody: map['rawBody'],
    );
  }
}
