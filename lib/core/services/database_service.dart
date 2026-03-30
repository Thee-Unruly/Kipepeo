import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';

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
      version: 1,
      onCreate: _onCreate,
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
    
    // Placeholder for Vector/Profile storage
    await db.execute('''
      CREATE TABLE profiles(
        id TEXT PRIMARY KEY,
        name TEXT,
        risk_score REAL,
        last_updated TEXT,
        metadata TEXT
      )
    ''');
  }

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
