import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as models;
import '../models/recurrence.dart';
import '../models/budget.dart';
import '../models/insight.dart';

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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Transactions table (v2 expanded)
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL DEFAULT 'default',
        amount REAL NOT NULL,
        merchant TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurrence_id TEXT,
        tags TEXT DEFAULT '',
        imported_from TEXT DEFAULT 'manual',
        created_at TEXT NOT NULL
      )
    ''');

    // Accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'checking',
        currency TEXT NOT NULL DEFAULT 'INR',
        created_at TEXT NOT NULL
      )
    ''');

    // Recurrences (subscriptions) table
    await db.execute('''
      CREATE TABLE recurrences (
        id TEXT PRIMARY KEY,
        merchant_key TEXT NOT NULL UNIQUE,
        merchant_display TEXT NOT NULL,
        avg_amount REAL NOT NULL,
        cadence TEXT NOT NULL DEFAULT 'monthly',
        first_seen TEXT NOT NULL,
        last_seen TEXT NOT NULL,
        confirmed INTEGER NOT NULL DEFAULT 0,
        dismissed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        month TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        spent_cached REAL NOT NULL DEFAULT 0,
        UNIQUE(month, category)
      )
    ''');

    // Insights table
    await db.execute('''
      CREATE TABLE insights (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at TEXT NOT NULL,
        seen INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Monthly budgets / income table
    await db.execute('''
      CREATE TABLE monthly_budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL UNIQUE,
        income REAL NOT NULL,
        savings_goal REAL DEFAULT 0
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_transaction_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transaction_category ON transactions(category)');
    await db.execute('CREATE INDEX idx_transaction_merchant ON transactions(merchant)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to existing transactions table
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN account_id TEXT NOT NULL DEFAULT "default"');
        await db.execute('ALTER TABLE transactions ADD COLUMN merchant TEXT NOT NULL DEFAULT ""');
        await db.execute('ALTER TABLE transactions ADD COLUMN is_recurring INTEGER NOT NULL DEFAULT 0');
        await db.execute('ALTER TABLE transactions ADD COLUMN recurrence_id TEXT');
        await db.execute('ALTER TABLE transactions ADD COLUMN tags TEXT DEFAULT ""');
        await db.execute('ALTER TABLE transactions ADD COLUMN imported_from TEXT DEFAULT "manual"');
      } catch (_) {}

      // Migrate: fill merchant from description
      try {
        await db.execute('UPDATE transactions SET merchant = description WHERE merchant = "" OR merchant IS NULL');
      } catch (_) {}

      // Create new tables
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS accounts (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL DEFAULT 'checking',
            currency TEXT NOT NULL DEFAULT 'INR', created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recurrences (
            id TEXT PRIMARY KEY, merchant_key TEXT NOT NULL UNIQUE, merchant_display TEXT NOT NULL,
            avg_amount REAL NOT NULL, cadence TEXT NOT NULL DEFAULT 'monthly',
            first_seen TEXT NOT NULL, last_seen TEXT NOT NULL,
            confirmed INTEGER NOT NULL DEFAULT 0, dismissed INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS budgets (
            id TEXT PRIMARY KEY, month TEXT NOT NULL, category TEXT NOT NULL,
            amount REAL NOT NULL, spent_cached REAL NOT NULL DEFAULT 0,
            UNIQUE(month, category)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS insights (
            id TEXT PRIMARY KEY, type TEXT NOT NULL, title TEXT NOT NULL,
            body TEXT NOT NULL, created_at TEXT NOT NULL, seen INTEGER NOT NULL DEFAULT 0
          )
        ''');
        // Ensure monthly_budgets has UNIQUE on month
        await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_monthly_budgets_month ON monthly_budgets(month)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_transaction_merchant ON transactions(merchant)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_transaction_category ON transactions(category)');
      } catch (_) {}
    }
  }

  // ─────────────────────────────────────────────────────────
  // TRANSACTION CRUD
  // ─────────────────────────────────────────────────────────

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
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => models.Transaction.fromMap(m)).toList();
  }

  Future<List<models.Transaction>> getTransactionsByMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 1).toIso8601String();
    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return maps.map((m) => models.Transaction.fromMap(m)).toList();
  }

  Future<List<models.Transaction>> getTransactionsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return maps.map((m) => models.Transaction.fromMap(m)).toList();
  }

  Future<List<models.Transaction>> getTransactionsByMerchant(String merchantKey) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'LOWER(merchant) = ?',
      whereArgs: [merchantKey.toLowerCase()],
      orderBy: 'date DESC',
    );
    return maps.map((m) => models.Transaction.fromMap(m)).toList();
  }

  Future<void> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    await db.update('transactions', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id]);
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────────
  // RECURRENCES (SUBSCRIPTIONS)
  // ─────────────────────────────────────────────────────────

  Future<List<Recurrence>> getRecurrences({bool excludeDismissed = true}) async {
    final db = await database;
    final maps = await db.query(
      'recurrences',
      where: excludeDismissed ? 'dismissed = 0' : null,
      orderBy: 'avg_amount DESC',
    );
    return maps.map((m) => Recurrence.fromMap(m)).toList();
  }

  Future<void> upsertRecurrence(Recurrence recurrence) async {
    final db = await database;
    await db.insert(
      'recurrences',
      recurrence.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRecurrenceStatus(String id, {bool? confirmed, bool? dismissed}) async {
    final db = await database;
    final updates = <String, dynamic>{};
    if (confirmed != null) updates['confirmed'] = confirmed ? 1 : 0;
    if (dismissed != null) updates['dismissed'] = dismissed ? 1 : 0;
    if (updates.isNotEmpty) {
      await db.update('recurrences', updates, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> deleteRecurrence(String id) async {
    final db = await database;
    await db.delete('recurrences', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────────
  // BUDGETS
  // ─────────────────────────────────────────────────────────

  Future<List<Budget>> getBudgetsByMonth(String month) async {
    final db = await database;
    final maps = await db.query('budgets', where: 'month = ?', whereArgs: [month]);
    return maps.map((m) => Budget.fromMap(m)).toList();
  }

  Future<void> upsertBudget(Budget budget) async {
    final db = await database;
    await db.insert('budgets', budget.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBudgetSpent(String month, String category, double spent) async {
    final db = await database;
    await db.update(
      'budgets',
      {'spent_cached': spent},
      where: 'month = ? AND category = ?',
      whereArgs: [month, category],
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────────
  // INSIGHTS
  // ─────────────────────────────────────────────────────────

  Future<List<Insight>> getInsights() async {
    final db = await database;
    final maps = await db.query('insights', orderBy: 'created_at DESC');
    return maps.map((m) => Insight.fromMap(m)).toList();
  }

  Future<void> insertInsight(Insight insight) async {
    final db = await database;
    await db.insert('insights', insight.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markInsightSeen(String id) async {
    final db = await database;
    await db.update('insights', {'seen': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearInsights() async {
    final db = await database;
    await db.delete('insights');
  }

  // ─────────────────────────────────────────────────────────
  // MONTHLY INCOME
  // ─────────────────────────────────────────────────────────

  Future<void> setMonthlyIncome(int year, int month, double income) async {
    final db = await database;
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    await db.insert(
      'monthly_budgets',
      {'month': monthKey, 'income': income, 'savings_goal': 0.0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> getMonthlyIncome(int year, int month) async {
    final db = await database;
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    final maps = await db.query('monthly_budgets', where: 'month = ?', whereArgs: [monthKey]);
    if (maps.isEmpty) return 35000.0; // Default income ₹35,000
    return (maps.first['income'] as num).toDouble();
  }

  // ─────────────────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────────────────

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('monthly_budgets');
    await db.delete('recurrences');
    await db.delete('budgets');
    await db.delete('insights');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
