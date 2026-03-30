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
      if (!body.contains('Confirmed') && !body.contains('received')) {
        return null;
      }

      // Extract Reference
      final refMatch = RegExp(r'^([A-Z0-9]+)\s+Confirmed').firstMatch(body);
      final reference = refMatch?.group(1) ?? 'UNKNOWN';

      // Extract Amount
      final amountMatch = RegExp(r'Ksh([\d,]+\.\d{2})').firstMatch(body);
      final amountStr = amountMatch?.group(1)?.replaceAll(',', '') ?? '0.0';
      final amount = double.tryParse(amountStr) ?? 0.0;

      // Determine Type (Debit/Credit)
      // Very simple heuristic: "paid to" vs "received from"
      String typeStr = 'outflow';
      if (body.toLowerCase().contains('received')) {
        typeStr = 'inflow';
      }

      // In a real app, we'd parse the date from the SMS string.
      // For this MVP, we might use the SMS timestamp if available from the provider.

      return MobileTransaction(
        id: 'SMS_$reference',
        sender: address,
        amount: amount,
        timestamp: DateTime.now(), // Fallback
        type: transactionTypeFromString(typeStr),
        reference: reference,
        rawBody: body,
      );
    } catch (e) {
      return null;
    }
  }
}
