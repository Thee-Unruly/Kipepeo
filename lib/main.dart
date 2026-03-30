import 'package:flutter/material.dart';
import 'core/services/sms_service.dart';
import 'core/services/database_service.dart';
import 'core/services/feature_service.dart';
import 'core/services/governance_service.dart';
import 'core/services/differential_privacy_service.dart';
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
          foregroundColor: Colors.white,
          elevation: 4,
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
  final DifferentialPrivacyService _dpService = DifferentialPrivacyService();

  static const String _userPhoneNumber = '+2547XXXXXXXX';

  List<MobileTransaction> _transactions = [];
  CreditProfile? _currentProfile;
  GovernanceResult? _governanceResult;
  bool _isLoading = false;
  String _status = 'Ready to sync financial records';

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
        _governanceResult = _governanceService.evaluate(_currentProfile!);
        
        // Save real profile
        _dbService.saveProfile(_currentProfile!);
        
        // Phase 3: Audit Logging (Transparency)
        _dbService.insertAuditLog(
          _currentProfile!.id, 
          _governanceResult!.finalScore, 
          _governanceResult!.isApproved, 
          _governanceResult!.warnings
        );
        
        // Phase 3: Anonymize and save to privacy-safe store
        final anonProfile = _dpService.anonymize(_currentProfile!);
        _dbService.saveProfile(anonProfile, isAnonymized: true);
        
      } else {
        final String profileId = _featureService.generateProfileId(_userPhoneNumber);
        _dbService.getProfile(profileId).then((storedProfile) {
          setState(() {
            _currentProfile = storedProfile;
            if (_currentProfile != null) {
              _governanceResult = _governanceService.evaluate(_currentProfile!);
            }
          });
        });
      }
    });
  }

  Future<void> _fetchLiveData() async {
    setState(() {
      _isLoading = true;
      _status = 'Syncing M-Pesa records...';
    });

    try {
      final liveTxs = await _smsService.fetchInboxTransactions();
      for (var tx in liveTxs) {
        await _dbService.insertTransaction(tx);
      }
      await _loadStoredData();
      setState(() {
        _status = 'Audit Log & Privacy Store Updated.';
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
              _buildPrivacyStatusCard(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Financial Activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: () => _showAuditLogs(context),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Audit Logs'),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _transactions.isEmpty
                    ? const Center(child: Text('No data found. Sync to generate profile.'))
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

  void _showAuditLogs(BuildContext context) async {
    final logs = await _dbService.getAuditLogs();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Immutable Decision Logs', style: Theme.of(context).textTheme.headlineSmall),
            const Text('Local transparency log for all credit decisions.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return ListTile(
                    title: Text('${log['decision']} - Score: ${(log['score'] * 100).toStringAsFixed(0)}'),
                    subtitle: Text('ID: ${log['profile_id'].toString().substring(0, 8)}... • ${log['timestamp']}'),
                    trailing: const Icon(Icons.lock, size: 16, color: Colors.grey),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.security, color: Colors.teal),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _status,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Local Privacy Engine Active (ε=1.0)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (_isLoading) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
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
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              ..._governanceResult!.warnings.map((w) => Text('• $w', style: theme.textTheme.bodySmall)),
            ]
          ],
        ),
      ),
    );
  }
}
