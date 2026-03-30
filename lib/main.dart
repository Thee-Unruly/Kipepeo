import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/sms_service.dart';
import 'core/services/database_service.dart';
import 'core/services/feature_service.dart';
import 'core/services/governance_service.dart';
import 'core/services/differential_privacy_service.dart';
import 'core/services/loan_calculator_service.dart';
import 'core/services/contract_builder_service.dart';
import 'core/services/repayment_tracker_service.dart';
import 'core/models/transaction.dart';
import 'core/models/credit_profile.dart';
import 'core/models/loan.dart';
import 'package:intl/intl.dart';

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
          elevation: 0,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const DashboardPage(),
    const AuditHistoryPage(),
    const PrivacySettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Hub'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Vault'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Shield'),
        ],
      ),
    );
  }
}

// --- PAGE 1: HUB (DASHBOARD) ---
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SmsService _smsService = SmsService();
  final DatabaseService _dbService = DatabaseService();
  final FeatureService _featureService = FeatureService();
  final GovernanceService _governanceService = GovernanceService();
  final DifferentialPrivacyService _dpService = DifferentialPrivacyService();
  final LoanCalculatorService _loanCalc = LoanCalculatorService();
  final ContractBuilderService _contractBuilder = ContractBuilderService();
  final RepaymentTrackerService _repaymentTracker = RepaymentTrackerService();

  CreditProfile? _currentProfile;
  GovernanceResult? _governanceResult;
  Loan? _activeLoan;
  bool _isLoading = false;
  String _status = 'Awaiting Sync';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final txs = await _dbService.getTransactions();
    if (txs.isNotEmpty) {
      final profile = _featureService.generateProfile('+2547XXXXXXXX', txs);
      final gov = _governanceService.evaluate(profile);
      
      // Also check for active loans
      final activeLoan = await _dbService.getActiveLoan(profile.id);
      
      // Attempt to auto-process repayments if there's an active loan
      if (activeLoan != null) {
        await _repaymentTracker.scanAndProcessRepayments(profile.id);
      }
      
      final updatedActiveLoan = await _dbService.getActiveLoan(profile.id);

      setState(() {
        _currentProfile = profile;
        _governanceResult = gov;
        _activeLoan = updatedActiveLoan;
      });
      
      _dbService.saveProfile(profile);
      _dbService.insertAuditLog(profile.id, gov.finalScore, gov.isApproved, gov.warnings);
      _dbService.saveProfile(_dpService.anonymize(profile), isAnonymized: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kipepeo Hub')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_governanceResult != null) _buildRiskCard(),
            const SizedBox(height: 20),
            if (_activeLoan != null) _buildActiveLoanCard(),
            if (_activeLoan == null && _governanceResult != null && _governanceResult!.isApproved) 
              _buildApplyButton(),
            const SizedBox(height: 20),
            _buildActionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard() {
    final score = _governanceResult!.finalScore;
    final color = score > 0.7 ? Colors.teal : score > 0.4 ? Colors.orange : Colors.red;
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text('Kipepeo Score', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Text((score * 100).toStringAsFixed(0), 
                style: TextStyle(fontSize: 84, fontWeight: FontWeight.w900, color: color, letterSpacing: -4)),
            Text(_governanceResult!.isApproved ? 'READY TO LEND' : 'HIGH RISK', 
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveLoanCard() {
    final currency = NumberFormat.currency(symbol: 'Ksh ', decimalDigits: 0);
    return Card(
      elevation: 0,
      color: Colors.teal.shade700,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('ACTIVE LOAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 16),
            Text(currency.format(_activeLoan!.totalToRepay), 
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const Text('Total Repayable', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _activeLoan!.amountPaid / _activeLoan!.totalToRepay,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Paid: ${currency.format(_activeLoan!.amountPaid)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                Text('Due: ${DateFormat('dd MMM').format(_activeLoan!.dueDate)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLoanApplication(context),
        icon: const Icon(Icons.add),
        label: const Text('NEW LOAN APPLICATION'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _showLoanApplication(BuildContext context) {
    final maxLimit = _loanCalc.estimateMaxLimit(_currentProfile!);
    double requested = maxLimit / 2;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final proposal = _loanCalc.calculateProposedLoan(_currentProfile!, requested);
          final contract = _contractBuilder.generateContractSummary(proposal, _currentProfile!);

          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Loan Proposal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Text('MAX LIMIT: Ksh ${maxLimit.toStringAsFixed(0)}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                Slider(
                  value: requested,
                  min: 500,
                  max: maxLimit,
                  divisions: (maxLimit / 500).round(),
                  label: 'Ksh ${requested.round()}',
                  onChanged: (v) => setModalState(() => requested = v),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                  child: Text(contract, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        onPressed: () async {
                          await _dbService.saveLoan(proposal);
                          if (!mounted) return;
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan issued successfully!')));
                        },
                        child: const Text('ISSUE LOAN'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        title: const Text('Sync Financial Records', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_status),
        trailing: _isLoading 
          ? const CircularProgressIndicator() 
          : CircleAvatar(
              backgroundColor: Colors.teal,
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () async {
                  setState(() { _isLoading = true; _status = 'Scanning SMS...'; });
                  final txs = await _smsService.fetchInboxTransactions();
                  for (var tx in txs) { await _dbService.insertTransaction(tx); }
                  await _loadData();
                  setState(() { _isLoading = false; _status = 'Records Updated'; });
                },
              ),
            ),
      ),
    );
  }
}

// --- PAGE 2: VAULT (HISTORY) ---
class AuditHistoryPage extends StatelessWidget {
  const AuditHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return Scaffold(
      appBar: AppBar(title: const Text('Decision Vault')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: db.getAuditLogs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final logs = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              final isApproved = log['decision'] == 'APPROVED';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(isApproved ? Icons.verified : Icons.warning, 
                               color: isApproved ? Colors.teal : Colors.red),
                  title: Text('Score: ${(log['score'] * 100).toStringAsFixed(0)}'),
                  subtitle: Text(log['timestamp'].toString().split('T')[0]),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- PAGE 3: SHIELD (PRIVACY) ---
class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Shield')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Kipepeo uses On-Device Differential Privacy to protect your financial footprint.', 
                     style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _buildToggleTile('Differential Privacy', 'Active (ε=1.0)', true),
          _buildToggleTile('Edge Inference', 'Decision made on-device', true),
          _buildToggleTile('Anonymized Sync', 'Pending connection', false),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: () {}, 
            child: const Text('Purge All Local Data'),
          )
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, String sub, bool val) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub),
      trailing: Switch(value: val, onChanged: (v) {}),
    );
  }
}
