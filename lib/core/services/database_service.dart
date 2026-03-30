import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/credit_profile.dart';
import '../models/loan.dart';
import '../models/user.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'kipepeo.db');
    return await openDatabase(
      path,
      version: 9, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        phoneNumber TEXT UNIQUE,
        fullName TEXT,
        businessName TEXT,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        sender TEXT,
        amount REAL,
        timestamp TEXT,
        type TEXT,
        reference TEXT,
        category TEXT,
        rawBody TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cash_transactions(
        id TEXT PRIMARY KEY,
        description TEXT,
        amount REAL,
        timestamp TEXT,
        type TEXT,
        category TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE profiles(
        id TEXT PRIMARY KEY,
        risk_score REAL,
        last_updated TEXT,
        avg_monthly_inflow REAL,
        avg_monthly_outflow REAL,
        repayment_rate REAL,
        transaction_count INTEGER,
        embedding TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anonymized_profiles(
        id TEXT PRIMARY KEY,
        risk_score REAL,
        last_updated TEXT,
        avg_monthly_inflow REAL,
        avg_monthly_outflow REAL,
        repayment_rate REAL,
        transaction_count INTEGER,
        embedding TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id TEXT,
        timestamp TEXT,
        score REAL,
        decision TEXT,
        warnings TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE loans(
        id TEXT PRIMARY KEY,
        profileId TEXT,
        lenderName TEXT,
        principalAmount REAL,
        interestRate REAL,
        issuedDate TEXT,
        dueDate TEXT,
        status TEXT,
        expenses TEXT,
        repayments TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE transactions ADD COLUMN category TEXT DEFAULT "General"');
    }
  }

  // --- User Methods ---
  Future<void> registerUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
  }

  Future<User?> loginUser(String phoneNumber, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'phoneNumber = ? AND password = ?',
      whereArgs: [phoneNumber, password],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUser(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  // --- Profile Methods ---
  Future<List<CreditProfile>> getAllProfiles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('profiles');
    return maps.map((m) {
      final List<dynamic> embeddingList = json.decode(m['embedding'] ?? '[]');
      return CreditProfile(
        id: m['id'],
        riskScore: m['risk_score'],
        lastUpdated: DateTime.parse(m['last_updated']),
        avgMonthlyInflow: m['avg_monthly_inflow'],
        avgMonthlyOutflow: m['avg_monthly_outflow'],
        repaymentRate: m['repayment_rate'],
        transactionCount: m['transaction_count'],
        embedding: embeddingList.cast<double>(),
      );
    }).toList();
  }

  Future<void> saveProfile(CreditProfile p, {bool isAnonymized = false}) async {
    final db = await database;
    final tableName = isAnonymized ? 'anonymized_profiles' : 'profiles';
    final Map<String, dynamic> data = p.toMap();
    data['embedding'] = json.encode(p.embedding);
    await db.insert(tableName, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Transaction Methods ---
  Future<void> insertTransaction(MobileTransaction tx) async {
    final db = await database;
    await db.insert('transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MobileTransaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    return List.generate(maps.length, (i) => MobileTransaction.fromMap(maps[i]));
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Cash Transaction Methods ---
  Future<void> insertCashTransaction(CashTransaction tx) async {
    final db = await database;
    await db.insert('cash_transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CashTransaction>> getCashTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cash_transactions', orderBy: 'timestamp DESC');
    return maps.map((m) => CashTransaction.fromMap(m)).toList();
  }

  Future<void> deleteCashTransaction(String id) async {
    final db = await database;
    await db.delete('cash_transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Loan Methods ---
  Future<void> saveLoan(Loan loan) async {
    final db = await database;
    final Map<String, dynamic> data = loan.toMap();
    data['expenses'] = json.encode(loan.expenses.map((e) => e.toMap()).toList());
    data['repayments'] = json.encode(loan.repayments.map((r) => r.toMap()).toList());
    await db.insert('loans', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Loan>> getLoansForProfile(String profileId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('loans', where: 'profileId = ?', whereArgs: [profileId]);
    return maps.map((m) {
      final List<dynamic> expJson = json.decode(m['expenses'] ?? '[]');
      final List<dynamic> repJson = json.decode(m['repayments'] ?? '[]');
      return Loan(
        id: m['id'],
        profileId: m['profileId'],
        lenderName: m['lenderName'],
        principalAmount: m['principalAmount'],
        interestRate: m['interestRate'],
        issuedDate: DateTime.parse(m['issuedDate']),
        dueDate: DateTime.parse(m['dueDate']),
        status: LoanStatus.values.byName(m['status']),
        expenses: expJson.map((e) => LoanExpense.fromMap(e)).toList(),
        repayments: repJson.map((r) => LoanRepayment.fromMap(r)).toList(),
      );
    }).toList();
  }

  Future<Loan?> getActiveLoan(String profileId) async {
    final loans = await getLoansForProfile(profileId);
    final active = loans.where((l) => l.status == LoanStatus.active).toList();
    return active.isEmpty ? null : active.first;
  }

  // --- Audit Methods ---
  Future<void> insertAuditLog(String pId, double s, bool a, List<String> w) async {
    final db = await database;
    await db.insert('audit_logs', {
      'profile_id': pId,
      'timestamp': DateTime.now().toIso8601String(),
      'score': s,
      'decision': a ? 'APPROVED' : 'REJECTED',
      'warnings': json.encode(w),
    });
  }
}
