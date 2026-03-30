import '../models/transaction.dart';

class SmsService {
  /// Scans the phone for all types of M-Pesa/Airtel transactions.
  /// Handles: Pochi la Biashara, Till Numbers, Paybills, and Personal transfers.
  Future<List<MobileTransaction>> fetchInboxTransactions() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real app, this would use a native bridge to read SMS.
    // Here we simulate the "Whole Dynamic" of Kenyan mobile money.
    return [
      MobileTransaction(
        id: 'TX_POCHI_1',
        sender: 'MPESA',
        amount: 1250.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: TransactionType.inflow,
        reference: 'RCL81293',
        rawBody: 'RCL81293 Confirmed. You have received Ksh1,250.00 from KEVIN OMONDI 254712... in your Pochi la Biashara.',
      ),
      MobileTransaction(
        id: 'TX_TILL_1',
        sender: 'MPESA',
        amount: 320.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: TransactionType.inflow,
        reference: 'RCL99212',
        rawBody: 'RCL99212 Confirmed. You have received Ksh320.00 from JANE DOE for Buy Goods Till 789123.',
      ),
      MobileTransaction(
        id: 'TX_PAYBILL_OUT',
        sender: 'MPESA',
        amount: 4500.0,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.outflow,
        reference: 'RCP44102',
        rawBody: 'RCP44102 Confirmed. Ksh4,500.00 paid to POTATO WHOLESALERS. Paybill 522522 Acc: INV-99.',
      ),
      MobileTransaction(
        id: 'TX_PERSONAL_1',
        sender: 'MPESA',
        amount: 2000.0,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        type: TransactionType.inflow,
        reference: 'RCM11234',
        rawBody: 'RCM11234 Confirmed. You have received Ksh2,000.00 from AUNTY JANE (Gift).',
      ),
      MobileTransaction(
        id: 'TX_PERSONAL_OUT',
        sender: 'MPESA',
        amount: 1500.0,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: TransactionType.outflow,
        reference: 'RCN55678',
        rawBody: 'RCN55678 Confirmed. Ksh1,500.00 sent to MAMA SCHOOL for Fees.',
      ),
    ];
  }
}
