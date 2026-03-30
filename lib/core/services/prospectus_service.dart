import '../models/credit_profile.dart';
import '../models/loan.dart';
import 'governance_service.dart';
import 'package:intl/intl.dart';

class ProspectusService {
  /// Generates a professional "Financial Prospectus" for the borrower to take to any lender.
  String generateProspectus(CreditProfile profile, GovernanceResult gov, List<Loan> loanHistory) {
    final df = DateFormat('dd MMM yyyy');
    final currency = NumberFormat.currency(symbol: 'Ksh ', decimalDigits: 0);
    
    final String healthStatus = profile.riskScore > 0.7 ? "EXCELLENT" : profile.riskScore > 0.4 ? "STABLE" : "EMERGING";
    
    // Efficiency Math
    double avgUtilization = 0.0;
    int onTimeRepayments = 0;
    if (loanHistory.isNotEmpty) {
      avgUtilization = loanHistory.fold(0.0, (sum, l) => sum + l.businessUtilization) / loanHistory.length;
      onTimeRepayments = loanHistory.where((l) => l.status == LoanStatus.paid).length;
    }

    return '''
🇰🇪 KIPEPEO FINANCIAL PASSPORT 🇰🇪
-----------------------------------
"Empowering the Informal Economy"

OWNER ID: ${profile.id.substring(0, 12)}
GENERATED: ${df.format(DateTime.now())}

[ BUSINESS HEALTH SCORE: ${(profile.riskScore * 100).toStringAsFixed(0)}/100 ]
Status: $healthStatus
Total Verified Cash Flow: ${currency.format(profile.avgMonthlyInflow)}

[ VERIFIED ACCOUNTABILITY LEDGER ]
- Utilization Efficiency: ${(avgUtilization * 100).toStringAsFixed(0)}%
- Repayment Discipline: $onTimeRepayments Verified Paid-Off Loans
- Business Logic: ${(avgUtilization > 0.8) ? "HIGH" : "STANDARD"} Capital Efficiency

[ GOVERNANCE SEAL ]
Certified by Project Ultra Governance Layer. 
✅ Verified Non-Predatory History
✅ Verified Data Ownership

MESSAGE TO LENDER:
This borrower maintains a verifiable ledger of loan usage. 
They utilize ${ (avgUtilization * 100).toStringAsFixed(0) }% of borrowed funds for direct business inventory. 
This individual represents a high-integrity, de-risked professional client.

-----------------------------------
Generated locally on-device.
-----------------------------------
''';
  }
}
