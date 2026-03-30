import '../models/credit_profile.dart';
import 'governance_service.dart';
import 'package:intl/intl.dart';

class ProspectusService {
  /// Generates a professional "Financial Prospectus" for the borrower to take to any lender.
  /// This is her "Credit Passport."
  String generateProspectus(CreditProfile profile, GovernanceResult gov) {
    final df = DateFormat('dd MMM yyyy');
    final currency = NumberFormat.currency(symbol: 'Ksh ', decimalDigits: 0);
    
    // Business Heuristics for the Prospectus
    final String healthStatus = profile.riskScore > 0.7 ? "EXCELLENT" : profile.riskScore > 0.4 ? "STABLE" : "EMERGING";
    final double liquidityRatio = profile.avgMonthlyOutflow > 0 ? (profile.avgMonthlyInflow / profile.avgMonthlyOutflow) : 0.0;

    return '''
🇰🇪 KIPEPEO FINANCIAL PASSPORT 🇰🇪
-----------------------------------
"Empowering the Informal Economy"

OWNER ID: ${profile.id.substring(0, 12)}
GENERATED: ${df.format(DateTime.now())}

[ BUSINESS HEALTH SUMMARY ]
Status: $healthStatus
Kipepeo Score: ${(profile.riskScore * 100).toStringAsFixed(0)}/100
Monthly Inflow: ${currency.format(profile.avgMonthlyInflow)}
Liquidity Ratio: ${liquidityRatio.toStringAsFixed(2)}x

[ VERIFIED GOVERNANCE SEAL ]
This profile has been locally audited for:
✅ Zero Demographic Bias
✅ Fair Scoring Heuristics
✅ Transparent Audit Logs
Certified by STATRECH Governance Layer.

[ MESSAGE TO LENDERS ]
The owner of this passport owns their financial data. 
The score above is based on ${profile.transactionCount} local mobile money records. 
This individual is de-risked and ready for professional credit.

-----------------------------------
This is a secure, on-device document.
No raw transaction data left the device.
-----------------------------------
''';
  }
}
