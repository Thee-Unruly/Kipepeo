import '../models/loan.dart';
import 'database_service.dart';
import 'sms_service.dart';

class RepaymentTrackerService {
  final DatabaseService _db = DatabaseService();
  final SmsService _sms = SmsService();

  /// Scans for repayment-related M-Pesa SMS and updates corresponding active loans.
  /// This is the "Closed-Loop" offline repayment logic.
  Future<int> scanAndProcessRepayments(String profileId) async {
    final activeLoan = await _db.getActiveLoan(profileId);
    if (activeLoan == null) return 0;

    final txs = await _sms.fetchInboxTransactions();
    int updateCount = 0;

    for (var tx in txs) {
      final body = tx.rawBody.toLowerCase();
      
      // Heuristic: Check for repayment keywords to "KIPEPEO"
      if (body.contains('paid to kipepeo') || body.contains('kipepeo payment')) {
        
        // If the transaction is after issuance and not already logged
        if (tx.timestamp.isAfter(activeLoan.issuedDate)) {
          
          // Check if this specific payment is already in the loan repayment list
          final alreadyLogged = activeLoan.repayments.any((r) => 
            r.amount == tx.amount && r.date.difference(tx.timestamp).inMinutes.abs() < 1
          );

          if (!alreadyLogged) {
            activeLoan.repayments.add(LoanRepayment(
              amount: tx.amount, 
              date: tx.timestamp
            ));

            if (activeLoan.balance <= 0) {
              activeLoan.status = LoanStatus.paid;
            }

            await _db.saveLoan(activeLoan);
            updateCount++;
            
            if (activeLoan.status == LoanStatus.paid) break;
          }
        }
      }
    }

    return updateCount;
  }
}
