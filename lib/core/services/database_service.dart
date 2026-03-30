import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/credit_profile.dart';
import '../models/loan.dart';
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
      version: 6, // Upgraded for accountability features
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        sender TEXT,
        amount REAL,
        timestamp TEXT,
        type TEXT,
        reference TEXT,
        rawBody TEXT
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

    await _createAnonymizedProfilesTable(db);
    await _createAuditLogsTable(db);
    await _createLoansTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) await _createAnonymizedProfilesTable(db);
    if (oldVersion < 4) await _createAuditLogsTable(db);
    if (oldVersion < 6) await _createLoansTable(db);
  }

  Future<void> _createAnonymizedProfilesTable(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS anonymized_profiles(...)'); // Simplified
  }

  Future<void> _createAuditLogsTable(Database db) async {
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
  }

  Future<void> _createLoansTable(Database db) async {
    // Drop the old basic loans table if it exists to upgrade it
    await db.execute('DROP TABLE IF EXISTS loans');
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

  // --- Accountability Loan Methods ---
  Future<void> saveLoan(Loan loan) async {
    final db = await database;
    final Map<String, dynamic> data = loan.toMap();
    
    // Convert lists to JSON strings for SQLite storage
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

  // --- Existing Methods ---
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

  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    final db = await database;
    return await db.query('audit_logs', orderBy: 'timestamp DESC');
  }

  Future<void> saveProfile(CreditProfile p, {bool isAnonymized = false}) async {
    final db = await database;
    final tableName = isAnonymized ? 'anonymized_profiles' : 'profiles';
    final Map<String, dynamic> data = p.toMap();
    data['embedding'] = json.encode(p.embedding);
    await db.insert(tableName, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertTransaction(MobileTransaction tx) async {
    final db = await database;
    await db.insert('transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MobileTransaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    return List.generate(maps.length, (i) => MobileTransaction.fromMap(maps[i]));
  }
}
