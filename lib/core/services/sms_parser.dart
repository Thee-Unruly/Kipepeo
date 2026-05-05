import '../models/transaction.dart';

TransactionType transactionTypeFromString(String value) {
  return TransactionType.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => TransactionType.outflow, // Default fallback
  );
}

/// Enum for M-Pesa message subtypes
enum MpesaMessageType {
  pochiIncome, // Received via Pochi la Biashara
  tillIncome, // Received via Till/Buy Goods
  paybillIncome, // Received via Paybill (C2B)
  sentExpense, // Sent to another account (EXCLUDE)
  airtime, // Airtime purchase
  withdrawal, // ATM/withdrawal
  unknown,
}

class SmsParser {
  /// Detects the M-Pesa message type to ensure we only capture business income.
  static MpesaMessageType _detectMpesaType(String body) {
    final bodyLower = body.toLowerCase();

    // Revenue-generating messages (INCLUDE THESE)
    if (bodyLower.contains('received') &&
        bodyLower.contains('pochi la biashara')) {
      return MpesaMessageType.pochiIncome;
    }
    if (bodyLower.contains('received') && bodyLower.contains('till number')) {
      return MpesaMessageType.tillIncome;
    }
    if (bodyLower.contains('received') &&
        (bodyLower.contains('account') || bodyLower.contains('paybill'))) {
      return MpesaMessageType.paybillIncome;
    }

    // Simple received = any incoming transaction
    if (bodyLower.contains('received')) {
      return MpesaMessageType
          .pochiIncome; // Default to business income if we can't determine type
    }

    // Expense messages (EXPLICITLY EXCLUDE THESE)
    if (bodyLower.contains('sent to') || bodyLower.contains('paid to')) {
      return MpesaMessageType.sentExpense;
    }
    if (bodyLower.contains('airtime purchased')) {
      return MpesaMessageType.airtime;
    }
    if (bodyLower.contains('withdrawal') || bodyLower.contains('atm')) {
      return MpesaMessageType.withdrawal;
    }

    return MpesaMessageType.unknown;
  }

  /// Parses M-Pesa SMS with revenue filter applied.
  /// Only captures INCOMING business transactions (Pochi, Till, Paybill).
  /// EXCLUDES personal expenses (airtime, withdrawals, transfers).
  static MobileTransaction? parseMpesa(String address, String body) {
    try {
      final bodyLower = body.toLowerCase();

      // Ignore non-M-Pesa messages
      if (!body.contains('Confirmed') && !bodyLower.contains('received')) {
        return null;
      }

      // Ignore Fuliza and other non-business
      if (bodyLower.contains('fuliza')) return null;

      // --- REVENUE FILTER: Detect message type ---
      final msgType = _detectMpesaType(body);

      // ONLY accept income types; REJECT expense types
      if (msgType == MpesaMessageType.sentExpense ||
          msgType == MpesaMessageType.airtime ||
          msgType == MpesaMessageType.withdrawal) {
        return null; // Skip personal expenses
      }

      if (msgType == MpesaMessageType.unknown) {
        return null; // Skip unrecognized messages
      }

      // --- EXTRACTION: Parse transaction details ---

      // Extract Reference ID
      final refMatch = RegExp(r'^([A-Z0-9]+)\s+Confirmed').firstMatch(body);
      final fallbackRef = 'TX${DateTime.now().millisecondsSinceEpoch}';
      final reference = refMatch?.group(1) ?? fallbackRef;

      // Extract Amount (handles both "Ksh 2,000.00" and "Ksh2,000.00")
      final amountMatch = RegExp(r'Ksh\s?([\d,]+\.?\d{0,2})').firstMatch(body);
      final amountStr = amountMatch?.group(1)?.replaceAll(',', '') ?? '0.0';
      final amount = double.tryParse(amountStr) ?? 0.0;

      if (amount <= 0) return null; // Reject zero-value transactions

      // Extract Customer Name
      String name = 'Sale';
      final nameMatch = RegExp(
        r'from\s+([\w\s.\-]+?)(?:\s+on|$)',
      ).firstMatch(body);
      if (nameMatch != null) {
        name = nameMatch.group(1)?.trim() ?? 'Sale';
      }

      // --- CATEGORIZATION: Tag by message type ---
      String category = 'General';
      switch (msgType) {
        case MpesaMessageType.pochiIncome:
          category = 'Pochi Income';
          break;
        case MpesaMessageType.tillIncome:
          category = 'Till Income';
          break;
        case MpesaMessageType.paybillIncome:
          category = 'Paybill Income';
          break;
        default:
          category = 'Income';
      }

      return MobileTransaction(
        id: 'SMS_$reference',
        sender: name,
        amount: amount,
        timestamp: DateTime.now(),
        type: TransactionType
            .inflow, // All parsed messages are inflow (revenue filter applied)
        reference: reference,
        category: category,
        rawBody: body,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parses a manual expense entry (for non-M-Pesa expenses like cash, transport, etc.)
  static MobileTransaction createManualExpense({
    required String description,
    required double amount,
    required String
    category, // 'Transport', 'Stock', 'Repairs', 'Meals', 'Other'
  }) {
    return MobileTransaction(
      id: 'MANUAL_${DateTime.now().millisecondsSinceEpoch}',
      sender: description,
      amount: amount,
      timestamp: DateTime.now(),
      type: TransactionType.outflow,
      reference: 'MANUAL',
      category: category,
      rawBody: 'Manual expense: $description ($category)',
    );
  }
}
