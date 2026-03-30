import '../models/loan.dart';
import '../models/transaction.dart';
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
      
      // Heuristic: Check for repayment keywords and potential amount matches
      // In a real app, "KIPEPEO" would be the Paybill/Till Name in the SMS
      if (body.contains('paid to kipepeo') || body.contains('kipepeo payment')) {
        
        // If the transaction hasn't been applied to this loan yet
        // For prototype, we check if the transaction date is after the loan issuance
        if (tx.timestamp.isAfter(activeLoan.issuedDate)) {
          
          final updatedLoan = Loan(
            id: activeLoan.id,
            profileId: activeLoan.profileId,
            principalAmount: activeLoan.principalAmount,
            interestRate: activeLoan.interestRate,
            totalToRepay: activeLoan.totalToRepay,
            amountPaid: activeLoan.amountPaid + tx.amount,
            issuedDate: activeLoan.issuedDate,
            dueDate: activeLoan.dueDate,
            status: (activeLoan.amountPaid + tx.amount >= activeLoan.totalToRepay) 
                ? LoanStatus.paid 
                : LoanStatus.active,
          );

          await _db.saveLoan(updatedLoan);
          updateCount++;
          
          // If the loan is fully paid, stop processing for this profile
          if (updatedLoan.status == LoanStatus.paid) break;
        }
      }
    }

    return updateCount;
  }
}
