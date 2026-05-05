import 'dart:math';
import '../models/daily_snapshot.dart';
import '../models/transaction.dart';

class DailyFuelService {
  /// Calculates the daily "Fuel Gauge" — Red Zone, Green Zone, and Safe to Spend.
  /// This is the heart of Kipepeo Daily.
  DailySnapshot calculateDailyFuel({
    required String userId,
    required DateTime date,
    required double openingCapital,
    required List<MobileTransaction> todayTransactions,
    required List<DailySnapshot> last7DaysSnapshots,
    required List<double>
    manualExpenses, // e.g., [50, 100] for lunch, transport
  }) {
    // Aggregate today's data
    double todayInflow = 0;
    double todayRestockOutflow = 0;

    for (var tx in todayTransactions) {
      if (tx.type == TransactionType.inflow) {
        todayInflow += tx.amount;
      } else if (_isRestockingExpense(tx.rawBody)) {
        todayRestockOutflow += tx.amount;
      }
    }

    double totalManualExpenses = manualExpenses.fold(0, (sum, e) => sum + e);

    // Step 1: Calculate volatility from last 7 days
    double coefficientOfVariance = _calculateCoefficientOfVariance(
      last7DaysSnapshots,
    );

    // Step 2: Calculate volatility buffer
    double volatilityBuffer = _calculateVolatilityBuffer(coefficientOfVariance);

    // Step 3: Calculate Red Zone
    double redZone = _calculateRedZone(
      todayRestockOutflow,
      last7DaysSnapshots,
      volatilityBuffer,
      openingCapital, // Used only for cold-start
    );

    // Step 4: Calculate Green Zone
    double greenZone = todayInflow - redZone - totalManualExpenses;

    // Step 5: Safe to Spend
    double safeToSpend = max(greenZone, 0);

    // Step 6: Generate AI nudges (placeholder — will be expanded)
    List<String> aiNudges = _generateAiNudges(
      todayInflow,
      todayRestockOutflow,
      totalManualExpenses,
      safeToSpend,
      last7DaysSnapshots,
    );

    final now = DateTime.now();
    final snapshotId = '${userId}_${date.toIso8601String().split('T')[0]}';

    return DailySnapshot(
      id: snapshotId,
      userId: userId,
      date: date,
      openingCapital: openingCapital,
      totalInflow: todayInflow,
      totalRestockOutflow: todayRestockOutflow,
      totalManualExpenses: totalManualExpenses,
      coefficientOfVariance: coefficientOfVariance,
      redZone: redZone,
      greenZone: greenZone,
      safeToSpend: safeToSpend,
      aiNudges: aiNudges,
      createdAt: now,
      lastUpdatedAt: null,
      isComplete: false,
    );
  }

  /// Detects if a transaction is for restocking (till, supplier, market).
  bool _isRestockingExpense(String rawBody) {
    final body = rawBody.toLowerCase();
    return body.contains('till') ||
        body.contains('paybill') ||
        body.contains('supplier') ||
        body.contains('market') ||
        body.contains('wholesale');
  }

  /// Calculates coefficient of variance (CV) from 7-day restock history.
  /// CV = stdDev / mean. High CV = inconsistent, Low CV = stable.
  double _calculateCoefficientOfVariance(List<DailySnapshot> last7Days) {
    if (last7Days.isEmpty) return 0.5; // Default mid-range for cold-start

    List<double> restockCosts = last7Days
        .map((s) => s.totalRestockOutflow)
        .toList();

    double mean =
        restockCosts.fold(0, (sum, val) => sum + val) / restockCosts.length;
    if (mean == 0) return 0.5;

    double variance =
        restockCosts.fold(
          0,
          (sum, val) => sum + pow(val - mean, 2).toDouble(),
        ) /
        restockCosts.length;
    double stdDev = sqrt(variance);

    double cv = stdDev / mean;
    return cv.clamp(0.0, 1.0); // Cap at 1.0 for extremely volatile cases
  }

  /// Maps coefficient of variance to volatility buffer percentage.
  /// Stable (CV < 0.3) → 10%
  /// Moderate (CV 0.3-0.5) → 15%
  /// High (CV > 0.5) → 20%
  double _calculateVolatilityBuffer(double cv) {
    if (cv < 0.3) return 0.10;
    if (cv < 0.5) return 0.15;
    return 0.20;
  }

  /// Calculates Red Zone using the locked formula.
  /// RedZone = max(TodayRestockSpend, 7DayAvgRestockSpend) × (1 + VolatilityBuffer)
  /// For cold-start (< 3 days), use ManualOpeningCapital × 0.9
  double _calculateRedZone(
    double todayRestockOutflow,
    List<DailySnapshot> last7Days,
    double volatilityBuffer,
    double manualOpeningCapital,
  ) {
    // Cold-start protection: first 3 days
    if (last7Days.length < 3) {
      return manualOpeningCapital * 0.9;
    }

    // Calculate 7-day average
    double avg7DayRestock =
        last7Days.fold(0, (sum, s) => sum + s.totalRestockOutflow) /
        last7Days.length;

    // Apply formula
    double baseRedZone = max(todayRestockOutflow, avg7DayRestock);
    double adjustedRedZone = baseRedZone * (1 + volatilityBuffer);

    return adjustedRedZone;
  }

  /// Generates AI nudges based on today's activity and patterns.
  /// These are simple rules for v1; can be expanded with ML later.
  List<String> _generateAiNudges(
    double todayInflow,
    double todayRestockOutflow,
    double totalManualExpenses,
    double safeToSpend,
    List<DailySnapshot> last7Days,
  ) {
    List<String> nudges = [];

    // Nudge 1: High manual expenses
    if (totalManualExpenses > 500) {
      nudges.add(
        '⚠️ You spent KES ${totalManualExpenses.toStringAsFixed(0)} on non-stock today. '
        'That\'s high. Can you reduce it tomorrow?',
      );
    }

    // Nudge 2: Low sales day
    double avg7DayInflow = last7Days.isEmpty
        ? 0
        : last7Days.fold(0, (sum, s) => sum + s.totalInflow) / last7Days.length;
    if (avg7DayInflow > 0 && todayInflow < (avg7DayInflow * 0.7)) {
      nudges.add(
        '📉 Your sales today (KES ${todayInflow.toStringAsFixed(0)}) were 30% below your average. '
        'What happened? Bad weather? Less foot traffic?',
      );
    }

    // Nudge 3: High restock relative to sales
    if (todayRestockOutflow > (todayInflow * 0.6)) {
      nudges.add(
        '📦 You restocked heavily today (KES ${todayRestockOutflow.toStringAsFixed(0)}) '
        'relative to sales. Make sure you sell it tomorrow!',
      );
    }

    // Nudge 4: Positive reinforcement
    if (safeToSpend > 2000) {
      nudges.add(
        '✅ Great day! You have KES ${safeToSpend.toStringAsFixed(0)} safe to spend. '
        'Well done! 🎉',
      );
    }

    return nudges.isNotEmpty
        ? nudges
        : ['📊 Your day is tracked. Check your fuel gauge above.'];
  }
}
