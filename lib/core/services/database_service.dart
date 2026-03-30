import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/credit_profile.dart';
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
      version: 3, // Upgraded for anonymized profiles
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

    await db.execute('''
      CREATE TABLE anonymized_profiles(
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
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
  }

  // --- Profile Methods ---
  Future<void> saveProfile(CreditProfile profile, {bool isAnonymized = false}) async {
    final db = await database;
    final tableName = isAnonymized ? 'anonymized_profiles' : 'profiles';
    
    final Map<String, dynamic> data = profile.toMap();
    data['embedding'] = json.encode(profile.embedding);

    await db.insert(
      tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CreditProfile?> getProfile(String id, {bool isAnonymized = false}) async {
    final db = await database;
    final tableName = isAnonymized ? 'anonymized_profiles' : 'profiles';
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    
    final Map<String, dynamic> map = Map<String, dynamic>.from(maps.first);
    map['embedding'] = List<double>.from(json.decode(map['embedding'] as String));

    return CreditProfile.fromMap(map);
  }

  Future<List<CreditProfile>> getAllProfiles({bool isAnonymized = false}) async {
    final db = await database;
    final tableName = isAnonymized ? 'anonymized_profiles' : 'profiles';
    
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.map((m) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(m);
      map['embedding'] = List<double>.from(json.decode(map['embedding'] as String));
      return CreditProfile.fromMap(map);
    }).toList();
  }

  // --- Transaction Methods ---
  Future<void> insertTransaction(MobileTransaction tx) async {
    final db = await database;
    await db.insert(
      'transactions',
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MobileTransaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    return List.generate(maps.length, (i) {
      return MobileTransaction.fromMap(maps[i]);
    });
  }
}
