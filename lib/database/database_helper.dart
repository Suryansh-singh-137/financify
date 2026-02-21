import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as models;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pocket_cfo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Monthly budgets table
    await db.execute('''
      CREATE TABLE monthly_budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL,
        income REAL NOT NULL,
        savings_goal REAL
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_transaction_date ON transactions(date)
    ''');
  }

  // Transaction CRUD operations
  Future<void> insertTransaction(models.Transaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<models.Transaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return models.Transaction.fromMap(maps[i]);
    });
  }

  Future<List<models.Transaction>> getTransactionsByMonth(
    int year,
    int month,
  ) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 1).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return models.Transaction.fromMap(maps[i]);
    });
  }

  Future<List<models.Transaction>> getTransactionsByCategory(
    String category,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return models.Transaction.fromMap(maps[i]);
    });
  }

  Future<void> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Monthly budget operations
  Future<void> setMonthlyIncome(int year, int month, double income) async {
    final db = await database;
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';

    await db.insert(
      'monthly_budgets',
      {
        'month': monthKey,
        'income': income,
        'savings_goal': 0.0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> getMonthlyIncome(int year, int month) async {
    final db = await database;
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';

    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_budgets',
      where: 'month = ?',
      whereArgs: [monthKey],
    );

    if (maps.isEmpty) {
      return 25000.0; // Default income
    }

    return maps.first['income'] as double;
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('monthly_budgets');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
