import '../models/transaction.dart';

TransactionType transactionTypeFromString(String value) {
  return TransactionType.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => TransactionType.outflow, // Default fallback
  );
}

class SmsParser {
  /// Parses M-Pesa style SMS.
  /// Example: "KXX9876543 Confirmed. Ksh2,000.00 paid to MAMA MBOGA. on 12/5/24 at 10:00 AM New M-Pesa balance is Ksh5,400.00."
  static MobileTransaction? parseMpesa(String address, String body) {
    try {
      final bodyLower = body.toLowerCase();
      if (bodyLower.contains('fuliza')) return null;
      if (!body.contains('Confirmed') && !bodyLower.contains('received')) {
        return null;
      }

      // Extract Reference
      final refMatch = RegExp(r'^([A-Z0-9]+)\s+Confirmed').firstMatch(body);
      final fallbackRef = 'TX${DateTime.now().millisecondsSinceEpoch}';
      final reference = refMatch?.group(1) ?? fallbackRef;

      // Extract Amount
      final amountMatch = RegExp(r'Ksh\s?([\d,]+\.\d{2})').firstMatch(body);
      final amountStr = amountMatch?.group(1)?.replaceAll(',', '') ?? '0.0';
      final amount = double.tryParse(amountStr) ?? 0.0;

      // Determine Type (Debit/Credit)
      String typeStr = 'outflow';
      String name = 'M-Pesa Transaction';

      if (bodyLower.contains('received')) {
        typeStr = 'inflow';
        // "received Ksh 1,000.00 from JOHN DOE"
        final nameMatch = RegExp(r'from\s+([\w\s.\-]+?)(?:\s+on|$)').firstMatch(body);
        name = nameMatch?.group(1)?.trim() ?? 'Pochi/Money Received';
      } else if (body.contains('paid to') || body.contains('sent to')) {
        typeStr = 'outflow';
        // "paid to MAMA MBOGA" or "sent to 0711... - JANE DOE"
        final nameMatch = RegExp(r'(?:paid to|sent to)\s+([\w\s.\-]+?)(?:\s+on| - |$)').firstMatch(body);
        name = nameMatch?.group(1)?.trim() ?? 'Business Expense';
      }

      // Categorization heuristics
      String category = 'General';
      if (typeStr == 'inflow') {
        category = 'Income/Sale';
      } else if (bodyLower.contains('token') || bodyLower.contains('kplc') || bodyLower.contains('water')) {
        category = 'Utility';
      } else if (bodyLower.contains('till') || bodyLower.contains('paybill')) {
        category = 'Merchant';
      } else if (bodyLower.contains('sent to')) {
        category = 'Transfer';
      } else if (bodyLower.contains('paid to')) {
        category = 'Payment';
      }

      return MobileTransaction(
        id: 'SMS_$reference',
        sender: name,
        amount: amount,
        timestamp: DateTime.now(),
        type: transactionTypeFromString(typeStr),
        reference: reference,
        category: category,
        rawBody: body,
      );
    } catch (e) {
      return null;
    }
  }
}
