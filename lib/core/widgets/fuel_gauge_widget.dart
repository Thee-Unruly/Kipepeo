import 'package:flutter/material.dart';
import '../models/daily_snapshot.dart';
import 'package:intl/intl.dart';

class FuelGaugeWidget extends StatelessWidget {
  final DailySnapshot snapshot;
  final VoidCallback? onAddExpense;
  final VoidCallback? onViewDetails;
  final Function(String category)? onQuickAdd; // Callback for quick-add buttons

  const FuelGaugeWidget({
    super.key,
    required this.snapshot,
    this.onAddExpense,
    this.onViewDetails,
    this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: Today's Sales ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Sales',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    Text(
                      currency.format(snapshot.totalInflow),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onViewDetails,
                  child: Icon(Icons.info_outline, color: Colors.teal),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- Fuel Gauge Slider ---
            Text(
              'Your Fuel Gauge',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _buildFuelGaugeSlider(context, currency),

            const SizedBox(height: 20),

            // --- Zone Legend ---
            Row(
              children: [
                Expanded(
                  child: _buildZoneLegend(
                    '🔴 Red Zone\n(Capital)',
                    snapshot.redZone,
                    currency,
                    Colors.red[100]!,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildZoneLegend(
                    '🟢 Green Zone\n(Safe to Spend)',
                    snapshot.safeToSpend,
                    currency,
                    Colors.green[100]!,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- Safe to Spend Highlight ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: snapshot.safeToSpend > 0
                    ? Colors.green[50]
                    : Colors.orange[50],
                border: Border.all(
                  color: snapshot.safeToSpend > 0
                      ? Colors.green
                      : Colors.orange,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safe to Spend Today',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        currency.format(snapshot.safeToSpend),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: snapshot.safeToSpend > 0
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  if (snapshot.safeToSpend > 0)
                    ElevatedButton.icon(
                      onPressed: onAddExpense,
                      icon: const Icon(Icons.add),
                      label: const Text('Log Expense'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Quick-Add Expense Buttons ---
            Text(
              '⚡ Quick Add',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickAddButton(
                  context,
                  '🚛',
                  'Transport',
                  () => onQuickAdd?.call('Transport'),
                ),
                _buildQuickAddButton(
                  context,
                  '📦',
                  'Stock',
                  () => onQuickAdd?.call('Stock'),
                ),
                _buildQuickAddButton(
                  context,
                  '🛠️',
                  'Repairs',
                  () => onQuickAdd?.call('Repairs'),
                ),
                _buildQuickAddButton(
                  context,
                  '🍽️',
                  'Meals',
                  () => onQuickAdd?.call('Meals'),
                ),
                _buildQuickAddButton(
                  context,
                  '❓',
                  'Other',
                  () => onQuickAdd?.call('Other'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- AI Nudges ---
            if (snapshot.aiNudges.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Daily Insights',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...snapshot.aiNudges.map(
                    (nudge) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border: Border.all(color: Colors.blue[200]!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          nudge,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a quick-add expense button.
  Widget _buildQuickAddButton(
    BuildContext context,
    String emoji,
    String label,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: Colors.teal[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  /// Builds the visual fuel gauge slider.
  Widget _buildFuelGaugeSlider(BuildContext context, NumberFormat currency) {
    final total = snapshot.redZone + snapshot.safeToSpend;
    final redPercent = total > 0 ? (snapshot.redZone / total) * 100 : 50;
    final greenPercent = 100 - redPercent;

    return Column(
      children: [
        // Stacked bar showing red and green zones
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              // Red Zone
              Expanded(
                flex: redPercent.toInt(),
                child: Container(
                  height: 40,
                  color: Colors.red[400],
                  child: Center(
                    child: Text(
                      '${redPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              // Green Zone
              Expanded(
                flex: greenPercent.toInt(),
                child: Container(
                  height: 40,
                  color: Colors.green[400],
                  child: Center(
                    child: Text(
                      '${greenPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currency.format(0),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              currency.format(total),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the zone legend box.
  Widget _buildZoneLegend(
    String label,
    double amount,
    NumberFormat currency,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            currency.format(amount),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
