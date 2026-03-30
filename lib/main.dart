import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/sms_service.dart';
import 'core/services/database_service.dart';
import 'core/services/feature_service.dart';
import 'core/services/governance_service.dart';
import 'core/services/differential_privacy_service.dart';
import 'core/services/prospectus_service.dart';
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
      title: 'Kipepeo Passport',
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
          NavigationDestination(icon: Icon(Icons.badge_outlined), selectedIcon: Icon(Icons.badge), label: 'Passport'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Vault'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Shield'),
        ],
      ),
    );
  }
}

// --- PAGE 1: PASSPORT (DASHBOARD) ---
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
  final ProspectusService _prospectusService = ProspectusService();

  CreditProfile? _currentProfile;
  GovernanceResult? _governanceResult;
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
      
      setState(() {
        _currentProfile = profile;
        _governanceResult = gov;
      });
      
      _dbService.saveProfile(profile);
      _dbService.insertAuditLog(profile.id, gov.finalScore, gov.isApproved, gov.warnings);
      _dbService.saveProfile(_dpService.anonymize(profile), isAnonymized: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Financial Passport')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_governanceResult != null) _buildPassportCard(),
            const SizedBox(height: 24),
            if (_governanceResult != null) _buildProspectusAction(),
            const SizedBox(height: 24),
            _buildActionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPassportCard() {
    final score = _governanceResult!.finalScore;
    final color = score > 0.7 ? Colors.teal : score > 0.4 ? Colors.orange : Colors.red;
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet, size: 48, color: Colors.teal),
            const SizedBox(height: 16),
            Text('Business Health Score', style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text((score * 100).toStringAsFixed(0), 
                style: TextStyle(fontSize: 84, fontWeight: FontWeight.w900, color: color, letterSpacing: -4)),
            Text(_governanceResult!.isApproved ? 'VERIFIED HEALTHY' : 'NEEDS REVIEW', 
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildProspectusAction() {
    return Card(
      elevation: 0,
      color: Colors.teal.shade700,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        leading: const Icon(Icons.description, color: Colors.white, size: 32),
        title: const Text('Generate Credit Prospectus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: const Text('Lender-ready summary for your SACCO/Bank', style: TextStyle(color: Colors.white70)),
        onTap: () => _showProspectus(context),
      ),
    );
  }

  void _showProspectus(BuildContext context) {
    final prospectus = _prospectusService.generateProspectus(_currentProfile!, _governanceResult!);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your Prospectus', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: prospectus));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prospectus copied to clipboard! Ready to share.')));
                  },
                )
              ],
            ),
            const Text('Share this summary with a lender to prove your creditworthiness.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                child: SingleChildScrollView(
                  child: Text(prospectus, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check),
                label: const Text('DONE'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
        title: const Text('Refresh Financial Identity', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_status),
        trailing: _isLoading 
          ? const CircularProgressIndicator() 
          : CircleAvatar(
              backgroundColor: Colors.teal,
              child: IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                onPressed: () async {
                  setState(() { _isLoading = true; _status = 'Updating Identity...'; });
                  final txs = await _smsService.fetchInboxTransactions();
                  for (var tx in txs) { await _dbService.insertTransaction(tx); }
                  await _loadData();
                  setState(() { _isLoading = false; _status = 'Identity Refreshed'; });
                },
              ),
            ),
      ),
    );
  }
}

// --- PAGE 2: VAULT (HISTORY) ---
class AuditHistoryPage extends StatefulWidget {
  const AuditHistoryPage({super.key});

  @override
  State<AuditHistoryPage> createState() => _AuditHistoryPageState();
}

class _AuditHistoryPageState extends State<AuditHistoryPage> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identity Vault')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _db.getAuditLogs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final logs = snapshot.data!;
          if (logs.isEmpty) return const Center(child: Text('No identity history found.'));
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              final isApproved = log['decision'] == 'APPROVED';
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Icon(isApproved ? Icons.verified : Icons.warning, 
                               color: isApproved ? Colors.teal : Colors.red),
                  title: Text('Health Index: ${(log['score'] * 100).toStringAsFixed(0)}'),
                  subtitle: Text('Verified on ${log['timestamp'].toString().split('T')[0]}'),
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
        padding: const EdgeInsets.all(32),
        children: [
          const Text('Kipepeo uses On-Device Differential Privacy to protect your financial footprint.', 
                     style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          _buildToggleTile('Differential Privacy', 'Active (ε=1.0)', true),
          _buildToggleTile('Edge Inference', 'Identity built on-device', true),
          _buildToggleTile('Data Ownership', 'Raw data never leaves phone', true),
          const SizedBox(height: 48),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: () {}, 
            child: const Text('Purge My Identity Data'),
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
