import 'package:flutter/material.dart';
import 'core/services/sms_listener_service.dart';
import 'core/services/daily_fuel_service.dart';
import 'core/services/database_service.dart';
import 'core/models/daily_snapshot.dart';
import 'core/widgets/fuel_gauge_widget.dart';

/// Example: Daily Fuel Gauge Home Screen
/// This demonstrates how to integrate all Kipepeo Daily components.
class KipepeoDailyHomePage extends StatefulWidget {
  final String userId;
  final String userPhone;

  const KipepeoDailyHomePage({
    super.key,
    required this.userId,
    required this.userPhone,
  });

  @override
  State<KipepeoDailyHomePage> createState() => _KipepeoDailyHomePageState();
}

class _KipepeoDailyHomePageState extends State<KipepeoDailyHomePage> {
  final smsListener = SmsListenerService();
  final fuelService = DailyFuelService();
  final db = DatabaseService();

  DailySnapshot? todaySnapshot;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeTodaysFuel();
  }

  /// Main flow: Load today's snapshot or create a new one
  Future<void> _initializeTodaysFuel() async {
    setState(() => isLoading = true);

    try {
      final today = DateTime.now();
      final hash = _getUserHash(widget.userPhone);

      // Step 1: Check if we already have today's snapshot
      var snapshot = await db.getDailySnapshot(hash, today);

      if (snapshot == null) {
        // Step 2: If not, fetch today's SMS data
        final todayTransactions = await smsListener
            .fetchTransactionsFromLastNDays(1);
        final todayFiltered = smsListener.filterByDate(
          todayTransactions,
          today,
        );

        // Step 3: Get opening capital (from last 7 days or user input)
        double openingCapital = await _getOpeningCapital();

        // Step 4: Get last 7 days for volatility calculation
        final last7Days = await db.getLast7DaysSnapshots(hash);

        // Step 5: Calculate fuel using the service
        snapshot = fuelService.calculateDailyFuel(
          userId: hash,
          date: today,
          openingCapital: openingCapital,
          todayTransactions: todayFiltered,
          last7DaysSnapshots: last7Days,
          manualExpenses: [], // User can add these via UI
        );

        // Step 6: Save to database
        await db.saveDailySnapshot(snapshot);
      }

      setState(() {
        todaySnapshot = snapshot;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading fuel data: $e')));
      setState(() => isLoading = false);
    }
  }

  /// Adds a manual expense and recalculates fuel
  Future<void> _addManualExpense(double amount, String description) async {
    if (todaySnapshot == null) return;

    // Update the snapshot with the new expense
    final newSnapshot = DailySnapshot(
      id: todaySnapshot!.id,
      userId: todaySnapshot!.userId,
      date: todaySnapshot!.date,
      openingCapital: todaySnapshot!.openingCapital,
      totalInflow: todaySnapshot!.totalInflow,
      totalRestockOutflow: todaySnapshot!.totalRestockOutflow,
      totalManualExpenses: todaySnapshot!.totalManualExpenses + amount,
      coefficientOfVariance: todaySnapshot!.coefficientOfVariance,
      redZone: todaySnapshot!.redZone,
      greenZone: todaySnapshot!.greenZone - amount, // Recalculate
      safeToSpend: (todaySnapshot!.safeToSpend - amount).clamp(
        0.0,
        double.infinity,
      ),
      aiNudges: todaySnapshot!.aiNudges,
      createdAt: todaySnapshot!.createdAt,
      lastUpdatedAt: DateTime.now(),
      isComplete: todaySnapshot!.isComplete,
    );

    await db.saveDailySnapshot(newSnapshot);
    setState(() => todaySnapshot = newSnapshot);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added KES $amount for "$description"')),
    );
  }

  /// Gets opening capital (from yesterday's closing or user input)
  Future<double> _getOpeningCapital() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final hash = _getUserHash(widget.userPhone);
    final yesterdaySnapshot = await db.getDailySnapshot(hash, yesterday);

    if (yesterdaySnapshot != null) {
      // Use yesterday's green zone as opening capital
      return yesterdaySnapshot.safeToSpend;
    }

    // Fallback: prompt user for opening capital
    // (In real app, this would be handled in onboarding)
    return 5000.0; // Default placeholder
  }

  /// Simple hash of phone number for user ID
  String _getUserHash(String phone) {
    // This should use the same hashing as Feature Service
    return '${widget.userId}_${DateTime.now().toIso8601String().split('T')[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kipepeo Daily'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : todaySnapshot == null
          ? const Center(child: Text('No data available'))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Fuel Gauge Widget
                  FuelGaugeWidget(
                    snapshot: todaySnapshot!,
                    onAddExpense: () => _showAddExpenseDialog(context),
                    onViewDetails: () => _showDetailsModal(context),
                  ),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showAddExpenseDialog(context),
                                icon: const Icon(Icons.add_circle),
                                label: const Text('Add Expense'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _showGetPassportDialog(context),
                                icon: const Icon(Icons.card_giftcard),
                                label: const Text('My Passport'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Amount (KES)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              _addManualExpense(amount, descCtrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDetailsModal(BuildContext context) {
    if (todaySnapshot == null) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _detailRow('Total Inflow', '${todaySnapshot!.totalInflow}'),
            _detailRow(
              'Restock Outflow',
              '${todaySnapshot!.totalRestockOutflow}',
            ),
            _detailRow(
              'Manual Expenses',
              '${todaySnapshot!.totalManualExpenses}',
            ),
            const Divider(),
            _detailRow(
              'Red Zone (Capital)',
              '${todaySnapshot!.redZone}',
              color: Colors.red,
            ),
            _detailRow(
              'Green Zone (Profit)',
              '${todaySnapshot!.greenZone}',
              color: Colors.green,
            ),
            _detailRow(
              'Safe to Spend',
              '${todaySnapshot!.safeToSpend}',
              color: Colors.blue,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showGetPassportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Get Your Kipepeo Passport'),
        content: const Text(
          'After 30 days of tracking, you\'ll be able to generate a professional business passport to share with lenders. Keep using the app daily!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
