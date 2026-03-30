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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white, // White icons and text
          elevation: 4, // Add a subtle shadow
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        )
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

  static const String _userPhoneNumber = '+2547XXXXXXXX'; // Placeholder

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
        _currentProfile = _featureService.generateProfile(_userPhoneNumber, txs);
        _governanceResult = _governanceService.evaluate(_currentProfile!); // Evaluate with new profile
        _dbService.saveProfile(_currentProfile!); // Save the newly generated profile
      } else {
        // If no transactions, try to load the last saved profile
        // We need to generate the ID for the placeholder phone number to retrieve it.
        final String profileId = _featureService.generateProfileId(_userPhoneNumber); // Using new method
        _currentProfile = null; // Clear previous profile
        _governanceResult = null; // Clear previous governance result
        
        _dbService.getProfile(profileId).then((storedProfile) {
          setState(() {
            _currentProfile = storedProfile;
            if (_currentProfile != null) {
              _governanceResult = _governanceService.evaluate(_currentProfile!); // Evaluate stored profile
            }
          });
        });
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

      await _loadStoredData(); // Reloads data, generates, and saves profile
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
            tooltip: 'Refresh Data',
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLiveData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_governanceResult != null) ...[
                _buildRiskCard(context),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: $_status',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (_isLoading) const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Local Transaction History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _transactions.isEmpty
                    ? const Center(child: Text('No transactions found. Tap refresh or pull down to fetch live data.'))
                    : ListView.separated(
                        itemCount: _transactions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: tx.type == 'CREDIT' ? Colors.green.shade50 : Colors.red.shade50,
                              child: Icon(
                                tx.type == 'CREDIT' ? Icons.arrow_downward : Icons.arrow_upward,
                                color: tx.type == 'CREDIT' ? Colors.green.shade700 : Colors.red.shade700,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              '${tx.type == 'CREDIT' ? '+' : '-'} Ksh ${tx.amount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: tx.type == 'CREDIT' ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                            subtitle: Text(
                              '${tx.reference} • ${tx.timestamp.toLocal().toString().split('.')[0]}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            // trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskCard(BuildContext context) {
    final score = _governanceResult!.finalScore;
    final theme = Theme.of(context);

    Color decisionColor;
    IconData decisionIcon;
    if (score > 0.7) {
      decisionColor = theme.colorScheme.primary;
      decisionIcon = Icons.check_circle_outline;
    } else if (score > 0.4) {
      decisionColor = theme.colorScheme.tertiary;
      decisionIcon = Icons.info_outline;
    } else {
      decisionColor = theme.colorScheme.error;
      decisionIcon = Icons.cancel_outlined;
    }

    return Container(
      decoration: ShapeDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: decisionColor.withOpacity(0.5), width: 1.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(decisionIcon, color: decisionColor, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Kipepeo Risk Score',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
                Text(
                  (score * 100).toStringAsFixed(0),
                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: decisionColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Decision: ${_governanceResult!.isApproved ? "APPROVED" : "REJECTED"}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: decisionColor),
            ),
            if (_governanceResult!.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Governance Warnings:',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 4),
              ..._governanceResult!.warnings.map((w) => Text(
                '• $w',
                style: theme.textTheme.bodySmall,
              )),
            ]
          ],
        ),
      ),
    );
  }
}
