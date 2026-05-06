import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction.dart';
import 'sms_parser.dart';

typedef OnNewTransaction = void Function(MobileTransaction tx);

class SmsListenerService {
  /// Fetches SMS messages from a specific start time (for real-time polling).
  /// Call this periodically (e.g., every minute) to get new messages.
  Future<List<MobileTransaction>> fetchNewTransactionsSince(
    DateTime since,
  ) async {
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      throw Exception('SMS permission not granted');
    }

    final SmsQuery query = SmsQuery();
    final List<SmsMessage> messages = await query.querySms(
      kinds: [SmsQueryKind.inbox],
    );

    // Filter messages that arrived after 'since'
    final newMessages = messages.where((msg) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        (msg.date as int?) ?? 0,
      );
      return timestamp.isAfter(since);
    }).toList();

    // Parse them
    final List<MobileTransaction> txs = [];
    for (final msg in newMessages) {
      final parsed = SmsParser.parseMpesa(msg.address ?? '', msg.body ?? '');
      if (parsed != null) {
        txs.add(parsed);
      }
    }

    return txs;
  }

  /// Fetches all SMS messages (for initial sync or bulk operations).
  Future<List<MobileTransaction>> fetchAllTransactions() async {
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      throw Exception('SMS permission not granted');
    }

    final SmsQuery query = SmsQuery();
    final List<SmsMessage> messages = await query.querySms(
      kinds: [SmsQueryKind.inbox],
    );

    final List<MobileTransaction> txs = [];
    for (final msg in messages) {
      final parsed = SmsParser.parseMpesa(msg.address ?? '', msg.body ?? '');
      if (parsed != null) {
        txs.add(parsed);
      }
    }

    return txs;
  }

  /// Fetches transactions from the last N days.
  Future<List<MobileTransaction>> fetchTransactionsFromLastNDays(
    int days,
  ) async {
    final since = DateTime.now().subtract(Duration(days: days));
    return fetchNewTransactionsSince(since);
  }

  /// Filters transactions by date (useful for daily aggregation).
  List<MobileTransaction> filterByDate(
    List<MobileTransaction> transactions,
    DateTime date,
  ) {
    return transactions.where((tx) {
      return tx.timestamp.year == date.year &&
          tx.timestamp.month == date.month &&
          tx.timestamp.day == date.day;
    }).toList();
  }
}
