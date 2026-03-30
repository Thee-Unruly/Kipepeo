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
        // Only parse if it looks like a transaction sender (e.g., "MPESA")
        // This is a heuristic, can be expanded for other providers
        final sender = message.address?.toUpperCase() ?? '';
        if (sender.contains('MPESA') || sender.contains('AIRTEL')) {
           final tx = SmsParser.parseMpesa(sender, message.body ?? '');
           if (tx != null) {
             // Use the message date if available
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
}
