import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/budget.dart';
import '../models/transaction.dart';

class BudgetService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  String _monthKey(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  Future<List<Budget>> getBudgetsForMonth(int year, int month) async {
    final budgets = await _db.getBudgetsByMonth(_monthKey(year, month));
    await _refreshSpentCache(year, month, budgets);
    return budgets;
  }

  Future<void> _refreshSpentCache(int year, int month, List<Budget> budgets) async {
    final transactions = await _db.getTransactionsByMonth(year, month);
    final Map<String, double> spent = {};
    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        spent[t.category] = (spent[t.category] ?? 0) + t.amount;
      }
    }
    for (final budget in budgets) {
      final s = spent[budget.category] ?? 0;
      budget.spentCached = s;
      await _db.updateBudgetSpent(_monthKey(year, month), budget.category, s);
    }
  }

  Future<Budget> createBudget({
    required int year,
    required int month,
    required String category,
    required double amount,
  }) async {
    final budget = Budget(
      id: _uuid.v4(),
      month: _monthKey(year, month),
      category: category,
      amount: amount,
    );
    await _db.upsertBudget(budget);
    return budget;
  }

  Future<void> updateBudget(Budget budget) => _db.upsertBudget(budget);

  Future<void> deleteBudget(String id) => _db.deleteBudget(id);

  /// Safe-to-Spend = income − (confirmed fixed/recurring expenses) − (expected variable spend pace)
  Future<double> calculateSafeToSpend(int year, int month) async {
    final income = await _db.getMonthlyIncome(year, month);
    final transactions = await _db.getTransactionsByMonth(year, month);

    double totalSpent = 0;
    for (final t in transactions) {
      if (t.type == TransactionType.expense) totalSpent += t.amount;
    }

    // Days math
    final now = DateTime.now();
    final totalDays = DateTime(year, month + 1, 0).day;
    final daysElapsed = (now.year == year && now.month == month) ? now.day : totalDays;
    final daysRemaining = totalDays - daysElapsed;

    // Daily spend pace
    final dailyPace = daysElapsed > 0 ? totalSpent / daysElapsed : 0.0;
    final projectedRemainingSpend = dailyPace * daysRemaining;

    final safeToSpend = income - totalSpent - projectedRemainingSpend;
    return safeToSpend.clamp(0.0, income);
  }

  Future<Map<String, double>> getCategorySpending(int year, int month) async {
    final transactions = await _db.getTransactionsByMonth(year, month);
    final Map<String, double> spent = {};
    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        spent[t.category] = (spent[t.category] ?? 0) + t.amount;
      }
    }
    return spent;
  }
}
