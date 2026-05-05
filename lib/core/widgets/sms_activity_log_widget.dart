import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

/// Displays a log of all parsed SMS transactions for transparency.
/// Lets the user verify that the app only read business messages.
class SmsActivityLogWidget extends StatelessWidget {
  final List<MobileTransaction> parsedTransactions;
  final String dateLabel; // e.g., "Today", "This Week"

  const SmsActivityLogWidget({
    super.key,
    required this.parsedTransactions,
    this.dateLabel = 'Today',
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);

    if (parsedTransactions.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No transactions parsed $dateLabel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📋 SMS Activity Log',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${parsedTransactions.length} messages',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),

            const Divider(margin: EdgeInsets.symmetric(vertical: 12)),

            // Transparency notice
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '🔒 Your phone, your data. These are all the SMS messages we parsed. We never store or share your private texts.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

            const SizedBox(height: 12),

            // Transaction list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: parsedTransactions.length,
              itemBuilder: (context, index) {
                final tx = parsedTransactions[index];
                final isInflow = tx.type == TransactionType.inflow;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isInflow ? Colors.green[50] : Colors.red[50],
                      border: Border.all(
                        color: isInflow ? Colors.green[200]! : Colors.red[200]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Transaction type and sender
                              Row(
                                children: [
                                  Text(
                                    isInflow ? '📥' : '📤',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.category,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                        Text(
                                          tx.sender,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Timestamp
                              Text(
                                DateFormat('HH:mm').format(tx.timestamp),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Amount
                        Text(
                          currency.format(tx.amount),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isInflow ? Colors.green : Colors.red,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
