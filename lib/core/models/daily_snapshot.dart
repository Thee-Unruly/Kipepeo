import 'dart:convert';

/// Represents a single day of business activity for a mama mboga.
/// This is the foundation for the "Fuel Gauge" — real-time profit tracking.
class DailySnapshot {
  final String id; // Unique ID per day per user (e.g., "USER_PHONE_2026-05-05")
  final String userId; // Hashed phone number
  final DateTime date; // The date of this snapshot

  // Capital & Cash Flow
  final double
  openingCapital; // How much cash she started with (manual or inferred)
  final double totalInflow; // All M-Pesa inflows today
  final double
  totalRestockOutflow; // M-Pesa to till/suppliers (detected from patterns)
  final double
  totalManualExpenses; // Manually logged expenses (lunch, transport, etc.)

  // Volatility metrics (for calculating the buffer)
  final double
  coefficientOfVariance; // CV from 7-day restock history (0.0 to 1.0+)

  // Calculated zones
  final double redZone; // Capital that must be protected
  final double greenZone; // Safe to spend
  final double safeToSpend; // Max(greenZone, 0)

  // AI nudges (populated by the assistant)
  final List<String>
  aiNudges; // E.g., ["You sold 80% tomatoes...", "Transport cost was high..."]

  // Metadata
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;
  final bool isComplete; // true if she's confirmed the day's data

  DailySnapshot({
    required this.id,
    required this.userId,
    required this.date,
    required this.openingCapital,
    required this.totalInflow,
    required this.totalRestockOutflow,
    required this.totalManualExpenses,
    required this.coefficientOfVariance,
    required this.redZone,
    required this.greenZone,
    required this.safeToSpend,
    required this.aiNudges,
    required this.createdAt,
    this.lastUpdatedAt,
    required this.isComplete,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'opening_capital': openingCapital,
      'total_inflow': totalInflow,
      'total_restock_outflow': totalRestockOutflow,
      'total_manual_expenses': totalManualExpenses,
      'coefficient_of_variance': coefficientOfVariance,
      'red_zone': redZone,
      'green_zone': greenZone,
      'safe_to_spend': safeToSpend,
      'ai_nudges': jsonEncode(aiNudges),
      'created_at': createdAt.toIso8601String(),
      'last_updated_at': lastUpdatedAt?.toIso8601String(),
      'is_complete': isComplete ? 1 : 0,
    };
  }

  factory DailySnapshot.fromMap(Map<String, dynamic> map) {
    return DailySnapshot(
      id: map['id'],
      userId: map['user_id'],
      date: DateTime.parse(map['date']),
      openingCapital: map['opening_capital'],
      totalInflow: map['total_inflow'],
      totalRestockOutflow: map['total_restock_outflow'],
      totalManualExpenses: map['total_manual_expenses'],
      coefficientOfVariance: map['coefficient_of_variance'],
      redZone: map['red_zone'],
      greenZone: map['green_zone'],
      safeToSpend: map['safe_to_spend'],
      aiNudges: List<String>.from(jsonDecode(map['ai_nudges'] ?? '[]')),
      createdAt: DateTime.parse(map['created_at']),
      lastUpdatedAt: map['last_updated_at'] != null
          ? DateTime.parse(map['last_updated_at'])
          : null,
      isComplete: map['is_complete'] == 1,
    );
  }
}
