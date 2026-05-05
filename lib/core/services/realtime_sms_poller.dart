import 'dart:async';
import '../models/transaction.dart';
import 'sms_listener_service.dart';
import 'database_service.dart';

typedef OnNewTransactionsCallback = void Function(List<MobileTransaction> txs);

/// Real-time SMS polling service.
/// Polls for new SMS every N seconds and notifies listeners.
class RealtimeSmsPoller {
  final SmsListenerService _smsListener = SmsListenerService();
  final DatabaseService _db = DatabaseService();

  Timer? _pollingTimer;
  DateTime _lastCheckTime = DateTime.now();
  bool _isRunning = false;

  final List<OnNewTransactionsCallback> _listeners = [];

  /// Start polling for new SMS messages every [intervalSeconds].
  /// Default is 60 seconds (1 minute).
  void startPolling({int intervalSeconds = 60}) {
    if (_isRunning) {
      print('[RealtimeSmsPoller] Already polling.');
      return;
    }

    _isRunning = true;
    _lastCheckTime = DateTime.now();
    print('[RealtimeSmsPoller] Starting polling every ${intervalSeconds}s');

    _pollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _pollForNewMessages(),
    );
  }

  /// Stop polling.
  void stopPolling() {
    _pollingTimer?.cancel();
    _isRunning = false;
    print('[RealtimeSmsPoller] Stopped polling.');
  }

  /// Register a callback to be called when new transactions arrive.
  void addListener(OnNewTransactionsCallback callback) {
    _listeners.add(callback);
  }

  /// Unregister a callback.
  void removeListener(OnNewTransactionsCallback callback) {
    _listeners.remove(callback);
  }

  /// Internal polling logic.
  Future<void> _pollForNewMessages() async {
    try {
      // Fetch transactions since last check
      final newTransactions = await _smsListener.fetchNewTransactionsSince(_lastCheckTime);

      if (newTransactions.isNotEmpty) {
        print('[RealtimeSmsPoller] Found ${newTransactions.length} new transactions');

        // Save to database
        for (final tx in newTransactions) {
          await _db.insertTransaction(tx);
        }

        // Notify all listeners
        for (final listener in _listeners) {
          listener(newTransactions);
        }
      }

      _lastCheckTime = DateTime.now();
    } catch (e) {
      print('[RealtimeSmsPoller] Error during polling: $e');
    }
  }

  /// Manually trigger a poll (useful for testing or on-demand updates).
  Future<void> pollNow() async {
    await _pollForNewMessages();
  }

  /// Check if polling is currently running.
  bool get isRunning => _isRunning;
}

/// Global singleton instance for the app to use.
final realtimeSmsPoller = RealtimeSmsPoller();
