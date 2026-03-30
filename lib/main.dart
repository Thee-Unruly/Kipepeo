import 'package:flutter/material.dart';
import 'core/services/sms_service.dart';
import 'core/services/database_service.dart';
import 'core/services/feature_service.dart';
import 'core/services/governance_service.dart';
import 'core/models/transaction.dart';
import 'core/models/credit_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KipepeoApp());
}

class KipepeoApp extends StatelessWidget {
  const KipepeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kipepeo Engine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final SmsService _smsService = SmsService();
  final DatabaseService _dbService = DatabaseService();
  final FeatureService _featureService = FeatureService();
  final GovernanceService _governanceService = GovernanceService();

  List<MobileTransaction> _transactions = [];
  CreditProfile? _currentProfile;
  GovernanceResult? _governanceResult;
  bool _isLoading = false;
  String _status = 'Ready to fetch live data';

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final txs = await _dbService.getTransactions();
    setState(() {
      _transactions = txs;
      if (txs.isNotEmpty) {
        _currentProfile = _featureService.generateProfile('USER_PHONE', txs);
        _governanceResult = _governanceService.evaluate(_currentProfile!);
      }
    });
  }

  Future<void> _fetchLiveData() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching and parsing SMS...';
    });

    try {
      final liveTxs = await _smsService.fetchInboxTransactions();
      
      for (var tx in liveTxs) {
        await _dbService.insertTransaction(tx);
      }

      await _loadStoredData();
      setState(() {
        _status = 'Successfully synced ${liveTxs.length} new transactions.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kipepeo Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchLiveData,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_governanceResult != null) ...[
              _buildRiskCard(),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (_isLoading) const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Local Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: _transactions.isEmpty
                  ? const Center(child: Text('No transactions found. Tap refresh to fetch live data.'))
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final tx = _transactions[index];
                        return ListTile(
                          leading: Icon(
                            tx.type == 'CREDIT' ? Icons.arrow_downward : Icons.arrow_upward,
                            color: tx.type == 'CREDIT' ? Colors.green : Colors.red,
                          ),
                          title: Text('${tx.type}: Ksh ${tx.amount}'),
                          subtitle: Text('${tx.reference} • ${tx.timestamp.toLocal().toString().split('.')[0]}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard() {
    final score = _governanceResult!.finalScore;
    final color = score > 0.7 ? Colors.green : score > 0.4 ? Colors.orange : Colors.red;

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kipepeo Risk Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text((score * 100).toStringAsFixed(0), 
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Decision: ${_governanceResult!.isApproved ? "APPROVED" : "REJECTED"}', 
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            if (_governanceResult!.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Governance Warnings:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ..._governanceResult!.warnings.map((w) => Text('• $w', style: const TextStyle(fontSize: 12))),
            ]
          ],
        ),
      ),
    );
  }
}
