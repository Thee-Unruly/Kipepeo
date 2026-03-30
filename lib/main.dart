import 'package:flutter/material.dart';
import 'core/services/sms_service.dart';
import 'core/services/database_service.dart';
import 'core/services/vector_search_service.dart';
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
      home: const SimulationDashboard(),
    );
  }
}

class SimulationDashboard extends StatefulWidget {
  const SimulationDashboard({super.key});

  @override
  State<SimulationDashboard> createState() => _SimulationDashboardState();
}

class _SimulationDashboardState extends State<SimulationDashboard> {
  final SmsService _smsService = SmsService();
  final DatabaseService _dbService = DatabaseService();
  final VectorSearchService _vectorSearch = VectorSearchService();

  List<MobileTransaction> _transactions = [];
  List<CreditProfile> _profiles = [];
  String _status = 'Ready to simulate';

  Future<void> _runSimulation() async {
    setState(() => _status = 'Simulating Phase 1...');

    // 1. Get Mock Transactions
    final mocks = _smsService.getMockTransactions();
    
    // 2. Save to DB
    for (var tx in mocks) {
      await _dbService.insertTransaction(tx);
    }

    // 3. Create a Mock Credit Profile for "Mama Mboga"
    final mockProfile = CreditProfile(
      id: 'hash_mama_mboga',
      riskScore: 0.85,
      lastUpdated: DateTime.now(),
      avgMonthlyInflow: 50000.0,
      avgMonthlyOutflow: 30000.0,
      repaymentRate: 0.98,
      transactionCount: 150,
      embedding: [0.1, 0.5, -0.2, 0.9, 0.4], // Mock 5D embedding
    );
    await _dbService.saveProfile(mockProfile);

    // 4. Refresh Data
    final savedTxs = await _dbService.getTransactions();
    final savedProfiles = await _dbService.getAllProfiles();

    setState(() {
      _transactions = savedTxs;
      _profiles = savedProfiles;
      _status = 'Simulation Complete!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kipepeo: Phase 1 Simulation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_status', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _runSimulation,
              child: const Text('Start Phase 1 Simulation'),
            ),
            const Divider(),
            const Text('Local Transactions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  return ListTile(
                    title: Text('${tx.type}: Ksh ${tx.amount}'),
                    subtitle: Text('Ref: ${tx.reference}'),
                  );
                },
              ),
            ),
            const Divider(),
            const Text('Local Credit Profiles:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ..._profiles.map((p) => ListTile(
              title: Text('Risk Score: ${p.riskScore}'),
              subtitle: Text('Inflow: Ksh ${p.avgMonthlyInflow}'),
              trailing: const Icon(Icons.verified_user, color: Colors.green),
            )),
          ],
        ),
      ),
    );
  }
}
