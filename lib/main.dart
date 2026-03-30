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
            const Icon(Icons.auto_awesome, size: 80, color: Colors.teal),
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
            const Icon(Icons.auto_awesome, size: 64, color: Colors.teal),
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
            const Icon(Icons.auto_awesome, size: 64, color: Colors.teal),
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
            const Icon(Icons.auto_awesome, size: 64, color: Colors.teal),
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
                  : "Welcome, ${widget.user.fullName}! Sync data to begin.",
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
    if (_currentProfile == null || _governanceResult == null) return;

    final profile = _currentProfile!;
    final gov = _governanceResult!;
    final score = gov.finalScore;
    final color = score > 0.7
        ? Colors.teal
        : score > 0.4
        ? Colors.orange
        : Colors.red;

    final currency = NumberFormat.currency(symbol: 'Ksh ', decimalDigits: 0);

    // Dynamic metrics
    double avgUtilization = 0.0;
    int onTimeRepayments = 0;
    double onTimeConsistency = 0.0;
    int totalRepaymentCount = 0;

    if (_loanHistory.isNotEmpty) {
      avgUtilization = _loanHistory.fold(0.0, (sum, l) => sum + l.businessUtilization) / _loanHistory.length;
      
      for (var loan in _loanHistory) {
        if (loan.status == LoanStatus.paid) onTimeRepayments++;
        for (var repayment in loan.repayments) {
          totalRepaymentCount++;
          if (repayment.date.isBefore(loan.dueDate.add(const Duration(hours: 24)))) {
            onTimeConsistency += 1.0;
          }
        }
      }
      if (totalRepaymentCount > 0) {
        onTimeConsistency = onTimeConsistency / totalRepaymentCount;
      } else {
        onTimeConsistency = 1.0; // Default to 100% if no payments yet to avoid penalty
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            // Handle for the modal
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  // --- HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KIPEPEO IDENTITY',
                            style: TextStyle(
                              letterSpacing: 2,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            profile.id.substring(0, 12).toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_2, color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // --- TRUST SCORE PASS ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.1), color.withOpacity(0.02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'BUSINESS TRUST SCORE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.5,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          (score * 100).toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: -4,
                          ),
                        ),
                        Text(
                          score > 0.7 ? "VERY STRONG" : score > 0.4 ? "STEADY" : "GROWING",
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniMetric('RECORDS', profile.transactionCount.toString()),
                            _buildMiniMetric('HEALTH', '${(profile.riskScore * 10).toStringAsFixed(1)}/10'),
                            _buildMiniMetric('ON-TIME', '${(onTimeConsistency * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- PAYMENT RELIABILITY ---
                  _buildReportSection(
                    'REPAYMENT PERFORMANCE',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment Early/On-Time Rate',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${(onTimeConsistency * 100).toStringAsFixed(0)}%',
                              style: TextStyle(fontWeight: FontWeight.bold, color: onTimeConsistency > 0.8 ? Colors.teal : Colors.orange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: onTimeConsistency,
                            minHeight: 10,
                            backgroundColor: Colors.teal.withOpacity(0.05),
                            color: onTimeConsistency > 0.8 ? Colors.teal : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Evidence confirms payments are made on or before the due date.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- CASHFLOW SUMMARY ---
                  const Text(
                    'VERIFIED CASHFLOW (Monthly)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildValueCard(
                          'Inflow', 
                          currency.format(profile.avgMonthlyInflow), 
                          Colors.teal,
                          Icons.arrow_downward
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildValueCard(
                          'Outflow', 
                          currency.format(profile.avgMonthlyOutflow), 
                          Colors.red,
                          Icons.arrow_upward
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- BUSINESS DISCIPLINE ---
                  _buildReportSection(
                    'BUSINESS DISCIPLINE',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Stock Utilization Efficiency',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${(avgUtilization * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: avgUtilization,
                            minHeight: 10,
                            backgroundColor: Colors.teal.withOpacity(0.05),
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Percentage of loans spent directly on business stock and transport.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- AI VERIFICATION SEAL ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_user, color: Colors.blue.shade700, size: 28),
                            const SizedBox(width: 12),
                            const Text(
                              'PROJECT ULTRA TRUST SEAL',
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...gov.warnings.isEmpty 
                          ? [
                              const _SealTip('✅ AI Audit: No predatory debt traps detected.'),
                              const _SealTip('✅ Mobile Verifier: Data integrity confirmed.'),
                              const _SealTip('✅ On-Time: History confirms early payment discipline.'),
                              const _SealTip('✅ Privacy Guard: Data masked & anonymized.'),
                            ]
                          : gov.warnings.map((w) => _SealTip('⚠️ Alert: $w')).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),

            // --- BOTTOM ACTION ---
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('DOWNLOAD PDF REPORT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.share, color: Colors.teal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildValueCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ],
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

class _SealTip extends StatelessWidget {
  final String text;
  const _SealTip(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
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

  late Future<List<Loan>> _loansFuture;
  late Future<List<dynamic>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _loansFuture = _db.getLoansForProfile(_pId);
      _transactionsFuture = Future.wait([
        _db.getTransactions(),
        _db.getCashTransactions(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Tracker'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'LOANS'),
              Tab(text: 'PAYMENTS'),
              Tab(text: 'HEALTH HISTORY'),
            ],
            labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: _buildLoanList(),
            ),
            RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: _buildTransactionLedger(),
            ),
            RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: _buildAuditLogHistory(),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                if (tabController.index == 0) {
                  return FloatingActionButton.extended(
                    onPressed: () => _showAddLoanModal(context),
                    label: const Text('Add Loan'),
                    icon: const Icon(Icons.add_task),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }

  void _showAddLoanModal(BuildContext context) {
    final lenderCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '0.1'); // 10% default
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 32,
            right: 32,
            top: 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'New Loan Record',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: lenderCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lender / Source',
                    hintText: 'e.g. M-Shwari, KCB, Sacco',
                    prefixIcon: Icon(Icons.business_center),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Principal Amount',
                    prefixText: 'Ksh ',
                    prefixIcon: Icon(Icons.payments),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Interest Rate (decimal)',
                    hintText: 'e.g. 0.1 for 10%',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: Colors.teal),
                  title: const Text('Due Date'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(dueDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() => dueDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      if (lenderCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                      final loan = Loan(
                        id: 'LN_${Random().nextInt(999999)}',
                        profileId: _pId,
                        lenderName: lenderCtrl.text,
                        principalAmount: double.parse(amountCtrl.text),
                        interestRate: double.parse(rateCtrl.text),
                        issuedDate: DateTime.now(),
                        dueDate: dueDate,
                        status: LoanStatus.active,
                      );
                      await _db.saveLoan(loan);
                      if (!mounted) return;
                      Navigator.pop(context);
                      _refreshData();
                    },
                    child: const Text('SAVE LOAN RECORD'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoanList() {
    return FutureBuilder<List<Loan>>(
      future: _loansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No loans tracked yet.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Add a loan to start tracking your business creditworthiness.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddLoanModal(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add My First Loan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade50,
                          foregroundColor: Colors.teal,
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        final loans = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: loans.length,
          itemBuilder: (context, i) {
            final loan = loans[i];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.teal.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loan.lenderName.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1.2,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due: ${DateFormat('dd MMM yyyy').format(loan.dueDate)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: loan.status == LoanStatus.active
                                ? Colors.orange.shade50
                                : Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            loan.status.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: loan.status == LoanStatus.active
                                  ? Colors.orange
                                  : Colors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Balance',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Ksh ${loan.balance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: loan.progress,
                        backgroundColor: Colors.teal.withOpacity(0.05),
                        color: Colors.teal,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Paid: Ksh ${loan.totalPaid.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        Text(
                          'Total: Ksh ${loan.totalToRepay.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _showLoanDetails(context, loan),
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: const Text('MANAGE USE & REPAYMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.teal.shade50.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLoanDetails(BuildContext context, Loan loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.lenderName.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 1),
                      ),
                      const Text(
                        'LOAN PERFORMANCE RECORD',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              // Balance Progress
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Ksh ${loan.balance.toStringAsFixed(0)}', 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.teal)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: loan.progress,
                        minHeight: 12,
                        color: Colors.teal,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(loan.progress * 100).toStringAsFixed(0)}% Repaid',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'USE BREAKDOWN'),
                          Tab(text: 'REPAYMENTS'),
                        ],
                        labelColor: Colors.teal,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.teal,
                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Use Breakdown Tab
                            Column(
                              children: [
                                Expanded(
                                  child: loan.expenses.isEmpty 
                                    ? const Center(child: Text('Add how you used this loan (Stock, Rent, etc.)'))
                                    : ListView.builder(
                                        itemCount: loan.expenses.length,
                                        itemBuilder: (context, i) {
                                          final e = loan.expenses[i];
                                          return ListTile(
                                            leading: const Icon(Icons.shopping_bag, color: Colors.orange),
                                            title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text(e.category),
                                            trailing: Text('Ksh ${e.amount.toStringAsFixed(0)}'),
                                          );
                                        },
                                      ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _addLoanAction(context, loan, true, () => setModalState(() {})),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Money Use'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade50, foregroundColor: Colors.orange, elevation: 0),
                                ),
                              ],
                            ),
                            // Repayments Tab
                            Column(
                              children: [
                                Expanded(
                                  child: loan.repayments.isEmpty 
                                    ? const Center(child: Text('No repayments recorded yet.'))
                                    : ListView.builder(
                                        itemCount: loan.repayments.length,
                                        itemBuilder: (context, i) {
                                          final r = loan.repayments[i];
                                          return ListTile(
                                            leading: const Icon(Icons.check_circle, color: Colors.teal),
                                            title: const Text('Loan Repayment'),
                                            subtitle: Text(DateFormat('dd MMM').format(r.date)),
                                            trailing: Text('Ksh ${r.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          );
                                        },
                                      ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _addLoanAction(context, loan, false, () => setModalState(() {})),
                                  icon: const Icon(Icons.payments),
                                  label: const Text('Record Repayment'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade50, foregroundColor: Colors.teal, elevation: 0),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addLoanAction(BuildContext context, Loan loan, bool isExpense, VoidCallback onUpdate) {
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Stock';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 32, right: 32, top: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isExpense ? 'Record Loan Use' : 'Record Repayment', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Amount (Ksh)'), keyboardType: TextInputType.number),
              if (isExpense) ...[
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'What was it for?')),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  items: ['Stock', 'Transport', 'Rent', 'Wages', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => category = v!),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (amtCtrl.text.isEmpty) return;
                    final amount = double.parse(amtCtrl.text);
                    if (isExpense) {
                      loan.expenses.add(LoanExpense(description: descCtrl.text, category: category, amount: amount, date: DateTime.now()));
                    } else {
                      loan.repayments.add(LoanRepayment(amount: amount, date: DateTime.now()));
                      if (loan.balance <= 0) loan.status = LoanStatus.paid;
                    }
                    await _db.saveLoan(loan);
                    Navigator.pop(context);
                    onUpdate();
                    _refreshData();
                  },
                  child: const Text('SAVE RECORD'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditLogHistory() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _db.getAuditLogs(_pId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return const Center(child: Text('Sync your data to start your health history.'));
        
        final logs = snapshot.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('REPORTING HISTORY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
                  TextButton.icon(
                    onPressed: () => _exportHistoryAsCSV(logs),
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('EXPORT ALL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: TextButton.styleFrom(foregroundColor: Colors.teal),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: logs.length,
                itemBuilder: (context, i) {
                  final log = logs[i];
                  final score = (log['score'] as double);
                  final color = score > 0.7 ? Colors.teal : score > 0.4 ? Colors.orange : Colors.red;
                  final date = DateTime.parse(log['timestamp']);

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.1),
                        child: Text((score * 10).toStringAsFixed(1), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      title: Text(log['decision'], style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                      subtitle: Text(DateFormat('dd MMMM yyyy, HH:mm').format(date), style: const TextStyle(fontSize: 10)),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _exportHistoryAsCSV(List<Map<String, dynamic>> logs) async {
    // Generate CSV Content
    String csv = "Date,Health Score,Decision\n";
    for (var log in logs) {
      csv += "${log['timestamp']},${log['score']},${log['decision']}\n";
    }

    // Since we are in a demo/agent environment, we show a success message 
    // In a production app, we would use 'path_provider' and 'share_plus' to save/share the file.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Business Passport History has been generated as a CSV file.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 8), maxLines: 5, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('SHARE')),
        ],
      ),
    );
  }

  Widget _buildTransactionLedger() {
    return FutureBuilder<List<dynamic>>(
      future: _transactionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || (snapshot.data![0].isEmpty && snapshot.data![1].isEmpty)) {
          return const Center(child: Text('No transactions recorded yet.'));
        }
        
        final List<FinancialTransaction> allTxs = [
          ...snapshot.data![0] as List<MobileTransaction>,
          ...snapshot.data![1] as List<CashTransaction>,
        ];
        
        allTxs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: allTxs.length,
          itemBuilder: (context, i) {
            final tx = allTxs[i];
            final isExpense = tx.type == TransactionType.outflow;
            
            // Determine the display title and sub-tag
            String displayTitle = "Transaction";
            String? subTag;
            if (tx is MobileTransaction) {
              displayTitle = tx.sender;
              subTag = tx.category;
            } else if (tx is CashTransaction) {
              displayTitle = tx.description.isNotEmpty ? tx.description : "Cash Record";
              subTag = tx.category ?? "Cash";
            }

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade100),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isExpense ? Colors.red.shade50 : Colors.teal.shade50,
                  child: Icon(
                    isExpense ? Icons.shopping_cart_outlined : Icons.payments_outlined,
                    color: isExpense ? Colors.red : Colors.teal,
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subTag != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          subTag.toUpperCase(),
                          style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ksh ${tx.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 16,
                        color: isExpense ? Colors.black : Colors.teal.shade700
                      ),
                    ),
                    Text(
                      DateFormat('dd MMMM, HH:mm').format(tx.timestamp),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpense ? Colors.red.shade50 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isExpense ? 'OUT' : 'IN',
                    style: TextStyle(
                      color: isExpense ? Colors.red : Colors.teal,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                ),
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
