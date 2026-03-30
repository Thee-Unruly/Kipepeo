import '../models/transaction.dart';
import '../models/credit_profile.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class FeatureService {
  /// Converts a list of raw transactions into a structured CreditProfile.
  /// This is the "Feature Engineering" step of Phase 2.
  CreditProfile generateProfile(String phoneNumber, List<MobileTransaction> transactions) {
    if (transactions.isEmpty) {
      return _emptyProfile(phoneNumber);
    }

    double totalInflow = 0;
    double totalOutflow = 0;
    int creditCount = 0;
    int debitCount = 0;

    // Basic aggregation logic
    for (var tx in transactions) {
      if (tx.type == 'CREDIT') {
        totalInflow += tx.amount;
        creditCount++;
      } else {
        totalOutflow += tx.amount;
        debitCount++;
      }
    }

    // Calculate heuristic risk score (0.0 to 1.0)
    // In a real scenario, this would be the output of the TFLite model.
    double riskScore = _calculateHeuristicScore(totalInflow, totalOutflow, transactions.length);

    return CreditProfile(
      id: _hashId(phoneNumber),
      riskScore: riskScore,
      lastUpdated: DateTime.now(),
      avgMonthlyInflow: totalInflow / 12, // Simplified monthly average
      avgMonthlyOutflow: totalOutflow / 12,
      repaymentRate: creditCount / (creditCount + debitCount), 
      transactionCount: transactions.length,
      embedding: [
        riskScore,
        totalInflow / 100000, // Normalized features for vector search
        totalOutflow / 100000,
        (creditCount / transactions.length),
        (debitCount / transactions.length),
      ],
    );
  }

  double _calculateHeuristicScore(double inflow, double outflow, int count) {
    if (count == 0) return 0.0;
    
    // Simple logic: High inflow relative to outflow + high transaction volume = lower risk (higher score)
    double ratio = (inflow > 0) ? (outflow / inflow) : 1.0;
    double score = (1.0 - ratio).clamp(0.0, 1.0);
    
    // Boost score based on volume (experience/consistency)
    double volumeBonus = (count > 50) ? 0.2 : (count / 250);
    
    return (score + volumeBonus).clamp(0.0, 1.0);
  }

  String _hashId(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  CreditProfile _emptyProfile(String phoneNumber) {
    return CreditProfile(
      id: _hashId(phoneNumber),
      riskScore: 0.0,
      lastUpdated: DateTime.now(),
      avgMonthlyInflow: 0,
      avgMonthlyOutflow: 0,
      repaymentRate: 0,
      transactionCount: 0,
      embedding: List.filled(5, 0.0),
    );
  }
}
