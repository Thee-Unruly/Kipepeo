import 'dart:math';
import '../models/credit_profile.dart';

class DifferentialPrivacyService {
  final Random _random = Random();

  /// Adds Laplacian noise to a value to achieve ε-differential privacy.
  /// formula: x + Laplace(scale = sensitivity / epsilon)
  double _addLaplaceNoise(double value, double epsilon, double sensitivity) {
    if (epsilon <= 0) return value;
    
    double scale = sensitivity / epsilon;
    
    // Generate Laplace noise using two uniform distributions
    // Laplace(0, b) = b * (log(U1) - log(U2))
    double u1 = _random.nextDouble();
    double u2 = _random.nextDouble();
    
    // Ensure we don't take log(0)
    if (u1 == 0) u1 = 0.0001;
    if (u2 == 0) u2 = 0.0001;

    double noise = scale * (log(u1) - log(u2));
    return value + noise;
  }

  /// Generates a privacy-preserved version of the credit profile.
  /// epsilon: The privacy budget. Smaller means more privacy (more noise).
  CreditProfile anonymize(CreditProfile profile, {double epsilon = 1.0}) {
    // Sensitivities for Kenyan market features (estimated max change if 1 user is removed)
    const double scoreSensitivity = 0.1;
    const double inflowSensitivity = 10000.0; // Ksh 10k
    const double countSensitivity = 5.0;

    return CreditProfile(
      id: 'ANON_${profile.id.substring(0, 8)}', // Truncate ID for anonymity
      riskScore: _addLaplaceNoise(profile.riskScore, epsilon, scoreSensitivity).clamp(0.0, 1.0),
      lastUpdated: DateTime.now(),
      avgMonthlyInflow: _addLaplaceNoise(profile.avgMonthlyInflow, epsilon, inflowSensitivity).clamp(0.0, double.infinity),
      avgMonthlyOutflow: _addLaplaceNoise(profile.avgMonthlyOutflow, epsilon, inflowSensitivity).clamp(0.0, double.infinity),
      repaymentRate: profile.repaymentRate, // Categorical or bounded usually handled differently, keeping for now
      transactionCount: _addLaplaceNoise(profile.transactionCount.toDouble(), epsilon, countSensitivity).round().clamp(0, 10000),
      embedding: profile.embedding.map((e) => _addLaplaceNoise(e, epsilon, 1.0)).toList(),
    );
  }
}
