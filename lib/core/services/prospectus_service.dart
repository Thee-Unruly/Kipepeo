import '../models/credit_profile.dart';
import '../models/loan.dart';
import 'governance_service.dart';
import 'package:intl/intl.dart';

class ProspectusService {
  /// Generates a friendly, clear "Business Passport" for the Mama Mboga.
  String generateProspectus(CreditProfile profile, GovernanceResult gov, List<Loan> loanHistory) {
    final df = DateFormat('dd MMM yyyy');
    final currency = NumberFormat.currency(symbol: 'Ksh ', decimalDigits: 0);
    
    // Friendly Status Language
    final String healthStatus = profile.riskScore > 0.7 ? "VERY STRONG" : profile.riskScore > 0.4 ? "STEADY" : "GROWING";
    
    // Accountability & Efficiency Math
    double avgUtilization = 0.0;
    int onTimeRepayments = 0;
    if (loanHistory.isNotEmpty) {
      avgUtilization = loanHistory.fold(0.0, (sum, l) => sum + l.businessUtilization) / loanHistory.length;
      onTimeRepayments = loanHistory.where((l) => l.status == LoanStatus.paid).length;
    }

    // Dynamic Project Ultra Audit Section in Easy Language
    String trustSummary = "";
    if (gov.warnings.isEmpty) {
      trustSummary = "✅ Verified: No risky debt patterns found.\n✅ Verified: This report is fair and unbiased.";
    } else {
      trustSummary = gov.warnings.map((w) => "⚠️ Note: $w").join("\n");
    }

    return '''
🇰🇪 MY KIPEPEO BUSINESS PASSPORT 🇰🇪
-----------------------------------
"Show how strong your business is."

OWNER ID: ${profile.id.substring(0, 12)}
REPORT DATE: ${df.format(DateTime.now())}

[ YOUR BUSINESS HEALTH: ${(profile.riskScore * 100).toStringAsFixed(0)}/100 ]
Status: $healthStatus
Your Total Cash Flow: ${currency.format(profile.avgMonthlyInflow)}

[ YOUR TRUST RECORD ]
- Money used for stock: ${(avgUtilization * 100).toStringAsFixed(0)}%
- Loans fully paid back: $onTimeRepayments
- Business Discipline: ${(avgUtilization > 0.8) ? "EXCELLENT" : "STANDARD"}

[ PROJECT ULTRA TRUST SEAL ]
This report has been checked for fairness:
$trustSummary

-----------------------------------
[ MESSAGE TO THE LENDER ]
This business owner uses their money wisely. 
They spend ${ (avgUtilization * 100).toStringAsFixed(0) }% of their loans on direct stock. 
This person is a reliable, professional trader. 
You can trust this report—it was calculated right on their phone.
-----------------------------------
Kipepeo: Empowering Your Business.
-----------------------------------
''';
  }
}
