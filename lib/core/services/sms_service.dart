import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction.dart';
import 'sms_parser.dart';

class SmsService {
  /// Fetches real SMS messages and parses them into MobileTransaction objects.
  Future<List<MobileTransaction>> fetchInboxTransactions() async {
    // Request SMS permission
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      throw Exception('SMS permission not granted');
    }

    final SmsQuery query = SmsQuery();
    final List<SmsMessage> messages = await query.querySms(
      kinds: [SmsQueryKind.inbox],
      // You can filter by address if needed, e.g. address: 'MPESA'
    );

    // Parse messages using your existing parser
    final List<MobileTransaction> txs = [];
    for (final msg in messages) {
      final parsed = SmsParser.parseMpesa(msg.address ?? '', msg.body ?? '');
      if (parsed != null) {
        txs.add(parsed);
      }
    }
    return txs;
  }
}
