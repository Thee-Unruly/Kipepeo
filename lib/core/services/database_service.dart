import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/credit_profile.dart';
import 'dart:convert'; // For JSON encoding/decoding

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
      version: 2, // Upgraded version for new schema
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Basic migration: Drop and recreate for simplicity in early dev
      await db.execute('DROP TABLE IF EXISTS profiles');
      await _onCreate(db, newVersion);
    }
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

  // --- Profile Methods ---
  Future<void> saveProfile(CreditProfile profile) async {
    final db = await database;
    // Convert embedding (List<double>) to a JSON string for storage
    final Map<String, dynamic> data = profile.toMap();
    data['embedding'] = json.encode(profile.embedding);

    await db.insert(
      'profiles',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CreditProfile?> getProfile(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    
    // Convert embedding JSON string back to List<double>
    final Map<String, dynamic> map = Map<String, dynamic>.from(maps.first);
    map['embedding'] = List<double>.from(json.decode(map['embedding'] as String));

    return CreditProfile.fromMap(map);
  }

  Future<List<CreditProfile>> getAllProfiles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('profiles');
    return maps.map((m) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(m);
      map['embedding'] = List<double>.from(json.decode(map['embedding'] as String));
      return CreditProfile.fromMap(map);
    }).toList();
  }
}
