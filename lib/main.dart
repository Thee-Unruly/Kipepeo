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
import 'dart:math';

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
          NavigationDestination(icon: Icon(Icons.account_balance_outlined), selectedIcon: Icon(Icons.account_balance), label: 'My Tracker'),
          NavigationDestination(icon: Icon(Icons.security_outlined), selectedIcon: Icon(Icons.security), label: 'Privacy'),
        ],
      ),
    );
  }
}

// --- PAGE 1: PASSPORT HUB ---
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
  List<Loan> _loanHistory = [];
  bool _isLoading = false;
  String _status = 'Awaiting Update';

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
      final history = await _dbService.getLoansForProfile(profile.id);
      
      setState(() {
        _currentProfile = profile;
        _governanceResult = gov;
        _loanHistory = history;
      });
      _dbService.saveProfile(profile);
      _dbService.insertAuditLog(profile.id, gov.finalScore, gov.isApproved, gov.warnings);
      _dbService.saveProfile(_dpService.anonymize(profile), isAnonymized: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Business Passport')),
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
    
    // Friendly status labels
    String statusLabel = score > 0.7 ? "VERY STRONG" : score > 0.4 ? "STEADY" : "GROWING";
    String statusDesc = score > 0.7 
        ? "Your business is doing great! Banks will trust you."
        : score > 0.4 
            ? "Your business is stable. Keep tracking your stock to grow."
            : "You are beginning your journey. Sync more messages to show your strength.";
    
    String tip = score > 0.7
        ? "Tip: You are ready to negotiate for lower interest rates!"
        : "Tip: Recording every stock purchase in 'My Tracker' builds trust.";

    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.storefront, size: 48, color: Colors.teal),
            const SizedBox(height: 16),
            Text('Your Business Health', style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
            const SizedBox(height: 8),
            Text(statusLabel, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1)),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: CircularProgressIndicator(
                    value: score,
                    strokeWidth: 12,
                    color: color,
                    backgroundColor: color.withOpacity(0.1),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text((score * 100).toStringAsFixed(0), 
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: color, letterSpacing: -2)),
              ],
            ),
            const SizedBox(height: 24),
            Text(statusDesc, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Text(tip, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            ),
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
        leading: const Icon(Icons.verified, color: Colors.white, size: 32),
        title: const Text('Create My Official Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: const Text('Checked by Governance Trust Mark', style: TextStyle(color: Colors.white70)),
        onTap: () => _showProspectus(context),
      ),
    );
  }

  void _showProspectus(BuildContext context) {
    final prospectus = _prospectusService.generateProspectus(_currentProfile!, _governanceResult!, _loanHistory);
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Business Report', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Verified by Project Ultra Trust Mark', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 10)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(child: Text(prospectus, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('DONE'))),
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
        title: const Text('Update My Business Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_status),
        trailing: _isLoading ? const CircularProgressIndicator() : const Icon(Icons.sync),
        onTap: () async {
          setState(() { _isLoading = true; _status = 'Updating...'; });
          final txs = await _smsService.fetchInboxTransactions();
          for (var tx in txs) { await _dbService.insertTransaction(tx); }
          await _loadData();
          setState(() { _isLoading = false; _status = 'Profile Updated'; });
        },
      ),
    );
  }
}

// --- PAGE 2: ACCOUNTABILITY TRACKER ---
class AuditHistoryPage extends StatefulWidget {
  const AuditHistoryPage({super.key});

  @override
  State<AuditHistoryPage> createState() => _AuditHistoryPageState();
}

class _AuditHistoryPageState extends State<AuditHistoryPage> {
  final DatabaseService _db = DatabaseService();
  final String _pId = '96324880c551793f7739545464197e411c5210c14f09a5601a457494f6f89069';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loan Tracker'),
        actions: [
          IconButton(icon: const Icon(Icons.add_chart), onPressed: () => _showAddLoan(context)),
        ],
      ),
      body: FutureBuilder<List<Loan>>(
        future: _db.getLoansForProfile(_pId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final loans = snapshot.data!;
          if (loans.isEmpty) return const Center(child: Text('You haven\'t added any loans yet.'));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            itemBuilder: (context, i) => _buildLoanCard(loans[i]),
          );
        },
      ),
    );
  }

  Widget _buildLoanCard(Loan loan) {
    final currency = NumberFormat.currency(symbol: 'Ksh ', decimalDigits: 0);
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loan.lenderName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.teal)),
                Text(loan.status.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currency.format(loan.balance), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const Text('Money Still to Pay', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                CircularProgressIndicator(value: loan.progress, strokeWidth: 8, backgroundColor: Colors.grey.shade100),
              ],
            ),
            const Divider(height: 40),
            _buildStatRow('Total Loaned', currency.format(loan.principalAmount)),
            _buildStatRow('Total to Repay', currency.format(loan.totalToRepay)),
            _buildStatRow('Used for Business', '${(loan.businessUtilization * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: const Text('RECORD SPENDING'),
                    onPressed: () => _showAddExpense(context, loan),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('RECORD PAYMENT'),
                    onPressed: () => _showAddRepayment(context, loan),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _showAddLoan(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a Loan to Track', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Where did you get the loan? (Bank/Sacco Name)')),
            TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Amount (Ksh)'), keyboardType: TextInputType.number),
            TextField(controller: rateCtrl, decoration: const InputDecoration(labelText: 'Interest Rate (e.g. 0.12)'), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final loan = Loan(
                  id: 'MN_${Random().nextInt(99999)}',
                  profileId: _pId,
                  lenderName: nameCtrl.text,
                  principalAmount: double.parse(amtCtrl.text),
                  interestRate: double.parse(rateCtrl.text),
                  issuedDate: DateTime.now(),
                  dueDate: DateTime.now().add(const Duration(days: 90)),
                );
                await _db.saveLoan(loan);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('SAVE LOAN'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAddExpense(BuildContext context, Loan loan) {
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String category = 'Stock';
    final categories = ['Stock', 'Transport', 'Rent', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('What did you buy?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                isExpanded: true,
                value: category,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setModalState(() => category = v!),
              ),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (e.g. Bought Tomatoes)')),
              TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Amount Spent (Ksh)'), keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final exp = LoanExpense(
                    description: descCtrl.text, 
                    category: category, 
                    amount: double.parse(amtCtrl.text), 
                    date: DateTime.now()
                  );
                  loan.expenses.add(exp);
                  await _db.saveLoan(loan);
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('SAVE RECORD'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRepayment(BuildContext context, Loan loan) {
    final amtCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Record a Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Amount Paid (Ksh)'), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final rep = LoanRepayment(amount: double.parse(amtCtrl.text), date: DateTime.now());
                loan.repayments.add(rep);
                if (loan.balance <= 0) loan.status = LoanStatus.paid;
                await _db.saveLoan(loan);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('SAVE PAYMENT'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// --- PAGE 3: SAFETY & PRIVACY ---
class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Safety & Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const Text('Kipepeo keeps your business records safe and private on your phone.', 
                     style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          _buildToggleTile('Privacy Shield', 'Active (Your data is hidden)', true),
          _buildToggleTile('On-Phone Math', 'Reports are built right here', true),
          _buildToggleTile('Data Ownership', 'Raw records never leave phone', true),
          const SizedBox(height: 48),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: () => _showDeleteDataDialog(context), 
            child: const Text('Start Fresh (Delete All My Data)'),
          )
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('This will delete all your local business records and trackers. You will have to start over.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All records deleted. Starting fresh.')));
            }, 
            child: const Text('YES, DELETE DATA', style: TextStyle(color: Colors.red))
          ),
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
