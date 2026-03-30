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
      version: 5,
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
    if (oldVersion < 3) {
      await _createAnonymizedProfilesTable(db);
    }
    if (oldVersion < 4) {
      await _createAuditLogsTable(db);
    }
    if (oldVersion < 5) {
      await _createLoansTable(db);
    }
  }

  Future<void> _createAnonymizedProfilesTable(Database db) async {
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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS loans(
        id TEXT PRIMARY KEY,
        profileId TEXT,
        principalAmount REAL,
        interestRate REAL,
        totalToRepay REAL,
        amountPaid REAL,
        issuedDate TEXT,
        dueDate TEXT,
        status TEXT
      )
    ''');
  }

  // --- Loan Methods ---
  Future<void> saveLoan(Loan loan) async {
    final db = await database;
    await db.insert(
      'loans',
      loan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Loan>> getLoansForProfile(String profileId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'profileId = ?',
      whereArgs: [profileId],
    );
    return maps.map((m) => Loan.fromMap(m)).toList();
  }

  Future<Loan?> getActiveLoan(String profileId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'profileId = ? AND status = ?',
      whereArgs: [profileId, LoanStatus.active.name],
    );
    if (maps.isEmpty) return null;
    return Loan.fromMap(maps.first);
  }

  // --- Audit Log Methods ---
  Future<void> insertAuditLog(String profileId, double score, bool approved, List<String> warnings) async {
    final db = await database;
    await db.insert('audit_logs', {
      'profile_id': profileId,
      'timestamp': DateTime.now().toIso8601String(),
      'score': score,
      'decision': approved ? 'APPROVED' : 'REJECTED',
      'warnings': json.encode(warnings),
    });
  }

  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    final db = await database;
    return await db.query('audit_logs', orderBy: 'timestamp DESC');
  }

  // --- Profile Methods ---
  Future<void> saveProfile(CreditProfile profile, {bool isAnonymized = false}) async {
    final db = await database;
    final tableName = isAnonymized ? 'anonymized_profiles' : 'profiles';
    final Map<String, dynamic> data = profile.toMap();
    data['embedding'] = json.encode(profile.embedding);
    await db.insert(tableName, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CreditProfile?> getProfile(String id, {bool isAnonymized = false}) async {
    final db = await database;
    final tableName = isAnonymized ? 'anonymized_profiles' : 'profiles';
    final List<Map<String, dynamic>> maps = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final Map<String, dynamic> map = Map<String, dynamic>.from(maps.first);
    map['embedding'] = List<double>.from(json.decode(map['embedding'] as String));
    return CreditProfile.fromMap(map);
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
}
