import '../models/transaction.dart';
import '../models/credit_profile.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class FeatureService {
  /// Analyzes transactions using Kenyan-specific micro-finance heuristics.
  CreditProfile generateProfile(String phoneNumber, List<MobileTransaction> transactions) {
    if (transactions.isEmpty) return _emptyProfile(phoneNumber);

    double totalInflow = 0;
    double totalOutflow = 0;
    int businessActivityCount = 0;
    int digitalLoanCount = 0;
    int utilityCount = 0;

    for (var tx in transactions) {
      final body = tx.rawBody.toLowerCase();
      
      if (tx.type == TransactionType.inflow) {
        totalInflow += tx.amount;
      } else {
        totalOutflow += tx.amount;
      }

      // Kenyan Market Heuristics:
      // 1. Business Activity (Frequent small payments to Till/Paybill)
      if (body.contains('paid to') || body.contains('till')) {
        businessActivityCount++;
      }
      
      // 2. Utility consistency (KPLC, Zuku, Nairobi Water)
      if (body.contains('kplc') || body.contains('token') || body.contains('water')) {
        utilityCount++;
      }

      // 3. Negative Signal: High-frequency digital loan apps (Tala, Branch, etc.)
      // These often send SMS with "loan", "repay", or "overdue"
      if (body.contains('loan') || body.contains('overdue') || body.contains('tala') || body.contains('branch')) {
        digitalLoanCount++;
      }
    }

    // Risk Calculation (Expert Rule Engine)
    double riskScore = _calculateKenyanRiskScore(
      totalInflow, 
      totalOutflow, 
      businessActivityCount, 
      utilityCount, 
      digitalLoanCount
    );

    return CreditProfile(
      id: _hashId(phoneNumber),
      riskScore: riskScore,
      lastUpdated: DateTime.now(),
      avgMonthlyInflow: totalInflow / 6, // Assuming 6-month lookback
      avgMonthlyOutflow: totalOutflow / 6,
      repaymentRate: (utilityCount > 0) ? 0.9 : 0.5, // Utility payers are higher quality
      transactionCount: transactions.length,
      embedding: [
        riskScore,
        businessActivityCount.toDouble(),
        utilityCount.toDouble(),
        digitalLoanCount.toDouble(),
        (totalInflow - totalOutflow), // Net position
      ],
    );
  }

  /// Generates a consistent, hashed ID for a given phone number.
  String generateProfileId(String phoneNumber) {
    return _hashId(phoneNumber);
  }

  double _calculateKenyanRiskScore(double inflow, double outflow, int business, int utility, int loans) {
    double score = 0.5; // Neutral starting point

    // Bonus for business activity (Mama Mboga logic)
    if (business > 20) score += 0.2;
    
    // Bonus for consistent utility payments
    if (utility > 2) score += 0.15;
    
    // Penalty for "Debt Traps" (Multiple digital loan hits)
    if (loans > 5) score -= 0.3;
    
    // Penalty for negative cashflow
    if (outflow > inflow) score -= 0.2;

    return score.clamp(0.0, 1.0);
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
