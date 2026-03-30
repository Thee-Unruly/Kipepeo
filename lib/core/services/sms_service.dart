import '../models/transaction.dart';

class SmsService {
  /// Simulates fetching SMS for the prototype. 
  /// In a real app, this uses the 'telephony' package to read inbox.
  Future<List<MobileTransaction>> fetchInboxTransactions() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Mocking common Kenyan business SMS formats
    return [
      MobileTransaction(
        id: 'TX1',
        sender: 'MPESA',
        amount: 1200.0,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.inflow,
        reference: 'RCL81293',
        rawBody: 'RCL81293 Confirmed. You have received Ksh1,200.00 from JOHN DOE 254711... in your Pochi la Biashara.',
      ),
      MobileTransaction(
        id: 'TX2',
        sender: 'MPESA',
        amount: 450.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: TransactionType.inflow,
        reference: 'RCL99212',
        rawBody: 'RCL99212 Confirmed. You have received Ksh450.00 from MARY W. for Till 123456.',
      ),
      MobileTransaction(
        id: 'TX3',
        sender: 'MPESA',
        amount: 5000.0,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: TransactionType.inflow,
        reference: 'RCK00123',
        rawBody: 'RCK00123 Confirmed. You have received Ksh5,000.00 from YOUR BROTHER (School Fees).',
      ),
    ];
  }
}
