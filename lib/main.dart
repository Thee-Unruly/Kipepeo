
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
import 'core/models/user.dart';
import 'package:intl/intl.dart';
import 'dart:math';

// --- TRANSACTION REVIEW SCREEN ---
class TransactionReviewPage extends StatefulWidget {
  final List<MobileTransaction> transactions;
  final void Function(List<MobileTransaction>) onConfirm;
  const TransactionReviewPage({super.key, required this.transactions, required this.onConfirm});

  @override
  State<TransactionReviewPage> createState() => _TransactionReviewPageState();
}

class _TransactionReviewPageState extends State<TransactionReviewPage> {
  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.filled(widget.transactions.length, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Transactions')),
      body: ListView.builder(
        itemCount: widget.transactions.length,
        itemBuilder: (context, i) {
          final tx = widget.transactions[i];
          return CheckboxListTile(
            value: _selected[i],
            onChanged: (val) => setState(() => _selected[i] = val ?? false),
            title: Text('Ksh ${tx.amount.toStringAsFixed(0)} • ${tx.sender}'),
            subtitle: Text(tx.rawBody),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.check),
        label: const Text('Confirm'),
        onPressed: () {
          final selectedTxs = [
            for (int i = 0; i < widget.transactions.length; i++)
              if (_selected[i]) widget.transactions[i]
          ];
          widget.onConfirm(selectedTxs);
          Navigator.pop(context);
        },
      ),
    );
  }
}
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
import 'core/models/user.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _currentUser;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    // In a real app, we'd check a secure storage flag here
    setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_currentUser == null)
      return LandingPage(onLogin: (u) => setState(() => _currentUser = u));
    return MainNavigation(
      user: _currentUser!,
      onLogout: () => setState(() => _currentUser = null),
    );
  }
}

// --- AUTH SCREENS ---
class LandingPage extends StatelessWidget {
  final Function(User) onLogin;
  const LandingPage({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/butterfly.png', width: 80, height: 80),
            const SizedBox(height: 24),
            const Text(
              'Kipepeo',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.teal,
                letterSpacing: -1,
              ),
            ),
            const Text(
              'Empowering SMEs Everywhere',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(18),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => LoginPage(onLogin: onLogin),
                  ),
                ),
                child: const Text('LOGIN'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => SignupPage(onLogin: onLogin)),
              ),
              child: const Text(
                'CREATE AN ACCOUNT',
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final Function(User) onLogin;
  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset('assets/butterfly.png', width: 64, height: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number (e.g. 0712...)',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(18),
                ),
                onPressed: () async {
                  final user = await db.loginUser(
                    phoneCtrl.text,
                    passCtrl.text,
                  );
                  if (user != null) {
                    widget.onLogin(user);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid phone or password'),
                      ),
                    );
                  }
                },
                child: const Text('LOGIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  final Function(User) onLogin;
  const SignupPage({super.key, required this.onLogin});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameCtrl = TextEditingController();
  final bizCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset('assets/butterfly.png', width: 64, height: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Join Kipepeo',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Start building your business identity today.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bizCtrl,
              decoration: const InputDecoration(labelText: 'Business Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Create Password'),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(18),
                ),
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                  final user = User(
                    id: 'USR_${Random().nextInt(999999)}',
                    phoneNumber: phoneCtrl.text,
                    fullName: nameCtrl.text,
                    businessName: bizCtrl.text,
                    password: passCtrl.text,
                  );
                  await db.registerUser(user);
                  widget.onLogin(user);
                  Navigator.pop(context);
                },
                child: const Text('START MY JOURNEY'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MAIN NAV ---
class MainNavigation extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;
  const MainNavigation({super.key, required this.user, required this.onLogout});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(user: widget.user),
      const AuditHistoryPage(),
      PrivacySettingsPage(onLogout: widget.onLogout),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Passport',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'My Tracker',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security),
            label: 'Privacy',
          ),
        ],
      ),
    );
  }
}

// --- PAGE 1: PASSPORT HUB ---
class DashboardPage extends StatefulWidget {
  final User user;
  const DashboardPage({super.key, required this.user});

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final txs = await _dbService.getTransactions();
    final cashTxs = await _dbService.getCashTransactions();

    if (txs.isNotEmpty || cashTxs.isNotEmpty) {
      final profile = _featureService.generateProfile(
        widget.user.phoneNumber,
        txs,
      );
      final gov = _governanceService.evaluate(profile);
      final history = await _dbService.getLoansForProfile(profile.id);

      setState(() {
        _currentProfile = profile;
        _governanceResult = gov;
        _loanHistory = history;
      });
      _dbService.saveProfile(profile);
      _dbService.insertAuditLog(
        profile.id,
        gov.finalScore,
        gov.isApproved,
        gov.warnings,
      );
      _dbService.saveProfile(_dpService.anonymize(profile), isAnonymized: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.user.businessName}\'s Passport')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildPassportCard(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildAchievementCard(
                    Icons.sync,
                    'Update Profile',
                    'Sync business SMS',
                    () => _showVerifyTransactions(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAchievementCard(
                    Icons.payments,
                    'Record Cash',
                    'Add cash sales',
                    () => _showAddCashEntry(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildProspectusAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.teal, size: 20),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassportCard() {
    final bool hasData = _governanceResult != null;
    final score = hasData ? _governanceResult!.finalScore : 0.0;
    final color = !hasData
        ? Colors.grey
        : score > 0.7
        ? Colors.teal
        : score > 0.4
        ? Colors.orange
        : Colors.red;

    String statusLabel = !hasData
        ? "READY TO START"
        : score > 0.7
        ? "VERY STRONG"
        : score > 0.4
        ? "STEADY"
        : "GROWING";

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
            Image.asset('assets/butterfly.png', width: 64, height: 64),
            const SizedBox(height: 16),
            Text(
              'Your Business Health',
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusLabel,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 160,
                  width: 160,
                  child: CircularProgressIndicator(
                    value: hasData ? score : 0.0,
                    strokeWidth: 14,
                    color: color,
                    backgroundColor: color.withOpacity(0.1),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  hasData ? (score * 100).toStringAsFixed(0) : '--',
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              hasData
                  ? "Your business is being tracked successfully."
                  : "Welcome, {widget.user.fullName}! Sync data to begin.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProspectusAction() {
    final bool hasData = _governanceResult != null;
    return Opacity(
      opacity: hasData ? 1.0 : 0.6,
      child: Card(
        elevation: 0,
        color: hasData ? Colors.teal.shade700 : Colors.grey.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          leading: const Icon(Icons.verified, color: Colors.white, size: 32),
          title: const Text(
            'View My Business Report',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            hasData
                ? 'Official report for Banks & SACCOs'
                : 'Unlock this after syncing data',
            style: const TextStyle(color: Colors.white70),
          ),
          onTap: hasData ? () => _showVisualReport(context) : null,
        ),
      ),
    );
  }

  void _showAddCashEntry(BuildContext context) {
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TransactionType type = TransactionType.inflow;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 32,
            right: 32,
            top: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Record Cash Transaction',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('EARNINGS (IN)'),
                      selected: type == TransactionType.inflow,
                      onSelected: (v) =>
                          setModalState(() => type = TransactionType.inflow),
                      selectedColor: Colors.teal.shade100,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('SPENDING (OUT)'),
                      selected: type == TransactionType.outflow,
                      onSelected: (v) =>
                          setModalState(() => type = TransactionType.outflow),
                      selectedColor: Colors.red.shade100,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: amtCtrl,
                decoration: const InputDecoration(labelText: 'Amount (Ksh)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'What was it for?',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () async {
                    if (amtCtrl.text.isEmpty) return;
                    final tx = CashTransaction(
                      id: 'CASH_${Random().nextInt(999999)}',
                      description: descCtrl.text,
                      amount: double.parse(amtCtrl.text),
                      timestamp: DateTime.now(),
                      type: type,
                      category: type == TransactionType.inflow
                          ? 'Sales'
                          : 'Stock',
                    );
                    await _dbService.insertCashTransaction(tx);
                    Navigator.pop(context);
                    await _loadData();
                  },
                  child: const Text('SAVE CASH RECORD'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerifyTransactions(BuildContext context) async {
    setState(() => _isLoading = true);
    final txs = await _smsService.fetchInboxTransactions();
    setState(() => _isLoading = false);
    final existingIds = (await _dbService.getTransactions())
        .map((t) => t.id)
        .toSet();
    final newTxs = txs.where((t) => !existingIds.contains(t.id)).toList();
    if (newTxs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No new business transactions found.')),
      );
      return;
    }
    List<String> selectedIds = newTxs.map((t) => t.id).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify My Business Money',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Keep money for stock and earnings checked.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: newTxs.length,
                  itemBuilder: (context, i) {
                    final tx = newTxs[i];
                    final isSelected = selectedIds.contains(tx.id);
                    final isExpense = tx.type == TransactionType.outflow;
                    return Card(
                      color: isSelected
                          ? (isExpense
                                ? Colors.red.shade50
                                : Colors.teal.shade50)
                          : Colors.grey.shade100,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? (isExpense
                                    ? Colors.red.shade100
                                    : Colors.teal.shade100)
                              : Colors.grey.shade200,
                          child: Icon(
                            isExpense ? Icons.shopping_bag : Icons.payments,
                            color: isSelected
                                ? (isExpense ? Colors.red : Colors.teal)
                                : Colors.grey,
                          ),
                        ),
                        title: Text(
                          'Ksh ${tx.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          tx.rawBody.contains('Pochi')
                              ? 'Pochi Income'
                              : 'SMS Record',
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (v) {
                            setModalState(() {
                              if (v!)
                                selectedIds.add(tx.id);
                              else
                                selectedIds.remove(tx.id);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () async {
                    for (var tx in newTxs) {
                      if (selectedIds.contains(tx.id)) {
                        await _dbService.insertTransaction(tx);
                      }
                    }
                    Navigator.pop(context);
                    await _loadData();
                  },
                  child: const Text('CONFIRM BUSINESS MONEY'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVisualReport(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Ksh ', decimalDigits: 0);
    final score = _governanceResult!.finalScore;
    final color = score > 0.7
        ? Colors.teal
        : score > 0.4
        ? Colors.orange
        : Colors.red;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(
                        Icons.account_balance,
                        color: Colors.teal,
                        size: 32,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.teal,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'BUSINESS IDENTITY REPORT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 2,
                      color: Colors.teal,
                    ),
                  ),
                  const Text(
                    'Verified by Kipepeo Engine',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  _buildReportSection(
                    'BUSINESS HEALTH',
                    Column(
                      children: [
                        Text(
                          score > 0.7
                              ? "VERY STRONG"
                              : score > 0.4
                              ? "STEADY"
                              : "GROWING",
                          style: TextStyle(
                            color: color,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Based on ${_currentProfile!.transactionCount} verified records',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DONE'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}

// --- PAGE 2: MY TRACKER ---
class AuditHistoryPage extends StatefulWidget {
  const AuditHistoryPage({super.key});

  @override
  State<AuditHistoryPage> createState() => _AuditHistoryPageState();
}

class _AuditHistoryPageState extends State<AuditHistoryPage> {
  final DatabaseService _db = DatabaseService();
  final String _pId = 'PROFILE_1';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Tracker'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'LOANS'),
                  Tab(text: 'PAYMENTS'),
                ],
              ),
            ),
            body: TabBarView(
              children: [_buildLoanList(), _buildTransactionLedger()],
            ),
            floatingActionButton: Builder(
              builder: (context) {
                final currentTab = tabController?.index ?? 0;
                if (currentTab == 0) {
                  // LOANS tab
                  return FloatingActionButton.extended(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Loan'),
                    onPressed: () {
                      // TODO: Implement add loan dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add Loan tapped')),
                      );
                    },
                  );
                } else {
                  // PAYMENTS tab
                  return FloatingActionButton.extended(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment'),
                    onPressed: () {
                      // TODO: Implement add payment dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add Payment tapped')),
                      );
                    },
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoanList() {
    return FutureBuilder<List<Loan>>(
      future: _db.getLoansForProfile(_pId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return const Center(child: Text('Add a loan to start tracking.'));
      },
    );
  }

  Widget _buildTransactionLedger() {
    return FutureBuilder(
      future: Future.wait([_db.getTransactions(), _db.getCashTransactions()]),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final List<FinancialTransaction> allTxs = [
          ...snapshot.data![0] as List<MobileTransaction>,
          ...snapshot.data![1] as List<CashTransaction>,
        ];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allTxs.length,
          itemBuilder: (context, i) {
            final tx = allTxs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  tx.type == TransactionType.outflow
                      ? Icons.shopping_bag
                      : Icons.payments,
                  color: Colors.teal,
                ),
                title: Text('Ksh ${tx.amount.toStringAsFixed(0)}'),
                subtitle: Text(DateFormat('dd MMM').format(tx.timestamp)),
              ),
            );
          },
        );
      },
    );
  }
}

// --- PAGE 3: SAFETY & PRIVACY ---
class PrivacySettingsPage extends StatelessWidget {
  final VoidCallback onLogout;
  const PrivacySettingsPage({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Safety & Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const Text(
            'Kipepeo keeps your business records safe and private on your phone.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildToggleTile('Privacy Shield', 'Active', true),
          _buildToggleTile('On-Phone Memory', 'Active', true),
          const SizedBox(height: 48),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: onLogout,
            child: const Text('LOGOUT'),
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
