import '../models/transaction.dart';

class SmsService {
  /// Scans for BOTH money coming in and money going out for stock.
  Future<List<MobileTransaction>> fetchInboxTransactions() async {
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      // EARNINGS (Income)
      MobileTransaction(
        id: 'TX_IN_1',
        sender: 'MPESA',
        amount: 2000.0,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.inflow,
        reference: 'RCL81293',
        rawBody: 'RCL81293 Confirmed. You have received Ksh2,000.00 in your Pochi la Biashara.',
      ),
      // BUYING STOCK (Expense)
      MobileTransaction(
        id: 'TX_OUT_1',
        sender: 'MPESA',
        amount: 1400.0,
        timestamp: DateTime.now(),
        type: TransactionType.outflow,
        reference: 'RCP44102',
        rawBody: 'RCP44102 Confirmed. Ksh1,400.00 sent to ONION WHOLESALER LTD for stock.',
      ),
      // PERSONAL (Ignore this)
      MobileTransaction(
        id: 'TX_PERS_1',
        sender: 'MPESA',
        amount: 300.0,
        timestamp: DateTime.now(),
        type: TransactionType.outflow,
        reference: 'RCQ77211',
        rawBody: 'RCQ77211 Confirmed. Ksh300.00 sent to DAUGHTER for lunch.',
      ),
    ];
  }
}
