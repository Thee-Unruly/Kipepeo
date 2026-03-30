import 'dart:math';
import '../models/credit_profile.dart';
import '../models/loan.dart';

class LoanCalculatorService {
  /// Proposes loan terms based on the CreditProfile and Risk Score.
  /// This is an offline-first "Loan Factory".
  Loan calculateProposedLoan(CreditProfile profile, double requestedAmount) {
    final score = profile.riskScore;
    
    double interestRate;
    int durationDays;

    // Expert Business Logic for Interest Tiers (Kenyan Market)
    if (score >= 0.8) {
      interestRate = 0.05; // 5% Interest (Premium Tier)
      durationDays = 30;
    } else if (score >= 0.6) {
      interestRate = 0.08; // 8% Interest (Standard Tier)
      durationDays = 21;
    } else if (score >= 0.4) {
      interestRate = 0.12; // 12% Interest (Recovery Tier)
      durationDays = 14;
    } else {
      interestRate = 0.20; // 20% Interest (High Risk)
      durationDays = 7;
    }

    final now = DateTime.now();

    return Loan(
      id: 'LN_${Random().nextInt(999999)}',
      profileId: profile.id,
      lenderName: 'KIPEPEO ENGINE', // Default lender name for auto-generated loans
      principalAmount: requestedAmount,
      interestRate: interestRate,
      issuedDate: now,
      dueDate: now.add(Duration(days: durationDays)),
      status: LoanStatus.active,
      expenses: [],
      repayments: [],
    );
  }

  /// Estimates the maximum loan amount based on average monthly inflow.
  double estimateMaxLimit(CreditProfile profile) {
    double netPosition = profile.avgMonthlyInflow - profile.avgMonthlyOutflow;
    if (netPosition <= 0) return 500.0;
    return (netPosition * 0.30).clamp(500.0, 50000.0);
  }
}
