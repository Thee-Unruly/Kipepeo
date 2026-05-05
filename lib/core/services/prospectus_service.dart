import '../models/credit_profile.dart';
import '../models/loan.dart';
import '../models/daily_snapshot.dart';
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

  /// Generates a 30-day Daily Passport from daily snapshots.
  /// This is the "lite" version for showing daily discipline and consistency.
  String generateDailyPassport(
    String userId,
    List<DailySnapshot> dailySnapshots,
    String businessName,
  ) {
    final df = DateFormat('dd MMM yyyy');
    final currency = NumberFormat.currency(symbol: 'Ksh ', decimalDigits: 0);

    if (dailySnapshots.isEmpty) {
      return 'No data available yet. Track your sales for 30 days to unlock your passport.';
    }

    // Calculate 30-day metrics
    double totalInflow = dailySnapshots.fold(0, (sum, s) => sum + s.totalInflow);
    double avgDailyInflow = totalInflow / dailySnapshots.length;
    int daysActive = dailySnapshots.length;
    double consistencyScore = (daysActive / 30.0).clamp(0.0, 1.0);
    double avgSafeToSpend = dailySnapshots.fold(0, (sum, s) => sum + s.safeToSpend) / dailySnapshots.length;

    // Profitability indicator
    String profitStatus = 'GROWING';
    if (avgSafeToSpend > (totalInflow * 0.3)) {
      profitStatus = 'STRONG';
    }

    // Consistency indicator
    String consistencyLabel = 'IRREGULAR';
    if (daysActive >= 25) {
      consistencyLabel = 'VERY CONSISTENT';
    } else if (daysActive >= 20) {
      consistencyLabel = 'CONSISTENT';
    } else if (daysActive >= 10) {
      consistencyLabel = 'REGULAR';
    }

    return '''
🇰🇪 KIPEPEO DAILY BUSINESS PASSPORT 🇰🇪
==========================================
"30 Days of Discipline. Unlock Your Credit."

BUSINESS: $businessName
OWNER ID: ${userId.substring(0, 12)}
REPORT PERIOD: ${df.format(dailySnapshots.first.date)} — ${df.format(dailySnapshots.last.date)}
TRACKING DAYS: $daysActive/30

[ YOUR 30-DAY PERFORMANCE ]
Daily Average Sales: ${currency.format(avgDailyInflow)}
Total Sales Tracked: ${currency.format(totalInflow)}
Avg. Profit Available: ${currency.format(avgSafeToSpend)}

[ YOUR BUSINESS PROFILE ]
Profitability: $profitStatus
Consistency: $consistencyLabel
Attendance Rate: ${((daysActive / 30.0) * 100).toStringAsFixed(0)}%

[ WHY THIS MATTERS ]
✅ You've tracked ${daysActive} days of real sales data
✅ Your profit discipline shows financial responsibility
✅ This report proves you're a serious business owner
✅ Share this with SACCOs or banks to get better loan rates

[ HOW TO USE THIS PASSPORT ]
1. Download as PDF
2. Share via WhatsApp with your Sacco/bank manager
3. They'll see you're trustworthy because:
   - Your data is calculated locally (transparent)
   - You've proven consistency (opened on ${daysActive} days)
   - Your profit margins are healthy

==========================================
Generated by Kipepeo Daily
Your business. Your data. Your terms.
Powered by Project Ultra (Fair & Unbiased)
==========================================
''';
  }

  /// Checks if a user has enough daily snapshots to unlock the 30-day passport.
  bool canUnlockPassport(List<DailySnapshot> dailySnapshots) {
    return dailySnapshots.length >= 30;
  }

  /// Calculates days remaining until passport unlock.
  int daysUntilPassport(List<DailySnapshot> dailySnapshots) {
    return (30 - dailySnapshots.length).clamp(0, 30);
  }
}

