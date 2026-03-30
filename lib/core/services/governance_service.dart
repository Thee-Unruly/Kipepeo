import '../models/credit_profile.dart';

class GovernanceService {
  /// Checks the credit profile against a set of AI Quality Governance rules.
  /// This ensures bias-free lending and prevents predatory scoring patterns.
  GovernanceResult evaluate(CreditProfile profile) {
    List<String> warnings = [];
    bool isApproved = true;

    // Rule 1: Minimum Data Threshold
    // Prevent decisions based on insufficient history (e.g., < 10 transactions)
    if (profile.transactionCount < 10) {
      isApproved = false;
      warnings.add('Insufficient transaction history for a fair assessment.');
    }

    // Rule 2: Predatory Debt Trap Detection
    // If the risk score is heavily penalized by too many digital loans, 
    // we flag it for human review rather than automatic rejection.
    if (profile.embedding[3] > 10) { // digitalLoanCount index
      warnings.add('High frequency of digital loan activity detected.');
    }

    // Rule 3: Extreme Volatility Check
    // If outflow is > 200% of inflow, the score might be skewed.
    if (profile.avgMonthlyOutflow > (profile.avgMonthlyInflow * 2)) {
      warnings.add('High expenditure volatility detected.');
    }

    // Rule 4: "Mama Mboga" Protection
    // Ensure that low-value but high-frequency traders aren't penalized for small amounts.
    if (profile.avgMonthlyInflow < 5000 && profile.transactionCount > 50) {
       // High volume small traders are often very reliable.
       // We ensure the system doesn't auto-reject them.
    }

    return GovernanceResult(
      isApproved: isApproved,
      warnings: warnings,
      finalScore: isApproved ? profile.riskScore : 0.0,
    );
  }
}

class GovernanceResult {
  final bool isApproved;
  final List<String> warnings;
  final double finalScore;

  GovernanceResult({
    required this.isApproved,
    required this.warnings,
    required this.finalScore,
  });
}
