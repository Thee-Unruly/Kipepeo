import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'sms_parser.dart';
import '../models/transaction.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();

  Future<List<MobileTransaction>> fetchInboxTransactions() async {
    var permission = await Permission.sms.status;
    if (permission.isDenied) {
      permission = await Permission.sms.request();
    }

    if (permission.isGranted) {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
      );

      List<MobileTransaction> transactions = [];
      for (var message in messages) {
        final sender = message.address?.toUpperCase() ?? '';
        if (sender.contains('MPESA') || sender.contains('AIRTEL')) {
           final tx = SmsParser.parseMpesa(sender, message.body ?? '');
           if (tx != null) {
             transactions.add(MobileTransaction(
               sender: tx.sender,
               amount: tx.amount,
               timestamp: message.date ?? DateTime.now(),
               type: tx.type,
               reference: tx.reference,
               rawBody: tx.rawBody,
             ));
           }
        }
      }
      return transactions;
    } else {
      throw Exception('SMS permission denied');
    }
  }

  /// Simulates M-Pesa SMS for testing and development
  List<MobileTransaction> getMockTransactions() {
    final mockSms = [
      "KXX9876543 Confirmed. Ksh2,500.00 paid to MAMA MBOGA. on 12/5/24 at 10:00 AM New M-Pesa balance is Ksh5,400.00.",
      "LZY1234567 Confirmed. Ksh1,200.00 received from JOHN DOE. on 13/5/24 at 11:30 AM New M-Pesa balance is Ksh6,600.00.",
      "MOP5556667 Confirmed. Ksh500.00 paid to KPLC. on 14/5/24 at 09:15 AM New M-Pesa balance is Ksh6,100.00.",
    ];

    return mockSms.map((body) => SmsParser.parseMpesa('MPESA', body)!).toList();
  }
}
