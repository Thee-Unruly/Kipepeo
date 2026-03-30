import 'dart:convert';

class CreditProfile {
  final String id; // Hashed identifier for privacy (e.g., SHA256 of phone number)
  final double riskScore;
  final DateTime lastUpdated;
  
  // Aggregated, non-PII features for the ML engine
  final double avgMonthlyInflow;
  final double avgMonthlyOutflow;
  final double repaymentRate; // 0.0 to 1.0
  final int transactionCount;
  
  // Vector embedding for similarity search (e.g., [0.1, -0.5, 0.8...])
  final List<double> embedding;

  CreditProfile({
    required this.id,
    required this.riskScore,
    required this.lastUpdated,
    required this.avgMonthlyInflow,
    required this.avgMonthlyOutflow,
    required this.repaymentRate,
    required this.transactionCount,
    required this.embedding,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'risk_score': riskScore,
      'last_updated': lastUpdated.toIso8601String(),
      'avg_monthly_inflow': avgMonthlyInflow,
      'avg_monthly_outflow': avgMonthlyOutflow,
      'repayment_rate': repaymentRate,
      'transaction_count': transactionCount,
      'embedding': jsonEncode(embedding), // Store as JSON string in SQLite
    };
  }

  factory CreditProfile.fromMap(Map<String, dynamic> map) {
    return CreditProfile(
      id: map['id'],
      riskScore: map['risk_score'],
      lastUpdated: DateTime.parse(map['last_updated']),
      avgMonthlyInflow: map['avg_monthly_inflow'],
      avgMonthlyOutflow: map['avg_monthly_outflow'],
      repaymentRate: map['repayment_rate'],
      transactionCount: map['transaction_count'],
      embedding: List<double>.from(jsonDecode(map['embedding'])),
    );
  }
}
