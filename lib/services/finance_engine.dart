import '../models/transaction.dart';
import '../models/financial_state.dart';
import '../database/database_helper.dart';
import 'budget_service.dart';
import 'subscription_service.dart';

class FinanceEngine {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final BudgetService _budgetService = BudgetService();
  final SubscriptionService _subService = SubscriptionService();

  /// Calculate the complete financial state for current month
  Future<MonthlyFinancialState> calculateMonthlyState() async {
    final now = DateTime.now();
    return calculateMonthlyStateFor(now.year, now.month);
  }

  Future<MonthlyFinancialState> calculateMonthlyStateFor(int year, int month) async {
    final transactions = await _db.getTransactionsByMonth(year, month);
    final income = await _db.getMonthlyIncome(year, month);

    double totalSpent = 0.0;
    final Map<String, double> categorySpending = {};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        totalSpent += transaction.amount;
        categorySpending[transaction.category] =
            (categorySpending[transaction.category] ?? 0) + transaction.amount;
      }
    }

    final remainingBalance = income - totalSpent;
    final savingsRate = income > 0 ? ((remainingBalance / income) * 100).toDouble() : 0.0;

    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final daysRemaining = year == DateTime.now().year && month == DateTime.now().month
        ? lastDayOfMonth - DateTime.now().day
        : 0;

    final healthScore = _calculateHealthScore(
      income: income,
      totalSpent: totalSpent,
      remainingBalance: remainingBalance,
      daysRemaining: daysRemaining,
      categorySpending: categorySpending,
    );

    // Safe to spend
    final safeToSpend = await _budgetService.calculateSafeToSpend(year, month);

    // Subscription total
    final subscriptionTotal = await _subService.getMonthlySubscriptionTotal();

    return MonthlyFinancialState(
      income: income,
      totalSpent: totalSpent,
      categorySpending: categorySpending,
      remainingBalance: remainingBalance,
      savingsRate: savingsRate,
      daysRemainingInMonth: daysRemaining,
      healthScore: healthScore,
      safeToSpend: safeToSpend,
      subscriptionTotal: subscriptionTotal,
    );
  }

  double _calculateHealthScore({
    required double income,
    required double totalSpent,
    required double remainingBalance,
    required int daysRemaining,
    required Map<String, double> categorySpending,
  }) {
    // 1. Savings Rate Weight (40 points)
    final savingsRate = income > 0 ? (remainingBalance / income) * 100 : 0;
    double savingsScore = 0;
    if (savingsRate >= 30) {
      savingsScore = 40;
    } else if (savingsRate >= 20) {
      savingsScore = 35;
    } else if (savingsRate >= 15) {
      savingsScore = 30;
    } else if (savingsRate >= 10) {
      savingsScore = 20;
    } else if (savingsRate >= 5) {
      savingsScore = 10;
    }

    // 2. Budget Adherence Weight (30 points)
    final spentPercentage = income > 0 ? (totalSpent / income) * 100 : 0;
    final now = DateTime.now();
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.day;
    final expectedSpentPercentage = (daysElapsed / totalDaysInMonth) * 100;

    double adherenceScore = 0;
    final adherenceDiff = (spentPercentage - expectedSpentPercentage).abs();
    if (adherenceDiff <= 5) adherenceScore = 30;
    else if (adherenceDiff <= 10) adherenceScore = 25;
    else if (adherenceDiff <= 15) adherenceScore = 20;
    else if (adherenceDiff <= 25) adherenceScore = 15;
    else adherenceScore = 10;

    // 3. Spending Consistency (20 points)
    double consistencyScore = 20;
    final foodSpending = categorySpending['food'] ?? 0;
    if (income > 0 && (foodSpending / income) * 100 > 25) consistencyScore -= 5;
    final shoppingSpending = categorySpending['shopping'] ?? 0;
    if (income > 0 && (shoppingSpending / income) * 100 > 15) consistencyScore -= 5;

    // 4. Emergency Buffer Weight (10 points)
    double bufferScore = 0;
    final dailyBudget = daysRemaining > 0 ? remainingBalance / daysRemaining : 0;
    if (dailyBudget >= 500) bufferScore = 10;
    else if (dailyBudget >= 300) bufferScore = 7;
    else if (dailyBudget >= 150) bufferScore = 5;
    else if (dailyBudget >= 100) bufferScore = 3;

    return (savingsScore + adherenceScore + consistencyScore + bufferScore).clamp(0, 100);
  }

  RiskAssessment assessPurchase(double amount, MonthlyFinancialState state) {
    final percentageOfRemaining =
        state.remainingBalance > 0 ? (amount / state.remainingBalance) * 100 : 100;

    RiskLevel level;
    if (percentageOfRemaining < 10) level = RiskLevel.low;
    else if (percentageOfRemaining < 25) level = RiskLevel.medium;
    else if (percentageOfRemaining < 50) level = RiskLevel.high;
    else level = RiskLevel.critical;

    final factors = <String>[];
    factors.add('Purchase is ${percentageOfRemaining.toStringAsFixed(1)}% of remaining balance');

    if (state.daysRemainingInMonth > 0) {
      final remainingAfter = state.remainingBalance - amount;
      final dailyBudgetAfter = remainingAfter / state.daysRemainingInMonth;
      factors.add('Daily budget after purchase: ₹${dailyBudgetAfter.toStringAsFixed(0)}');
    }

    if (state.savingsRate < 15) {
      factors.add('Current savings rate is below recommended 15%');
    }

    final safeAfter = state.safeToSpend - amount;
    if (safeAfter >= 0) {
      factors.add('Safe-to-Spend after: ₹${safeAfter.toStringAsFixed(0)}');
    }

    String recommendation;
    switch (level) {
      case RiskLevel.low:
        recommendation = 'This purchase is safe and within your budget. Go ahead!';
        break;
      case RiskLevel.medium:
        recommendation = 'Consider if this is necessary. You can afford it but it will impact your buffer.';
        break;
      case RiskLevel.high:
        recommendation = 'High risk — this will significantly reduce your remaining balance. Consider postponing.';
        break;
      case RiskLevel.critical:
        recommendation = 'Critical risk — this purchase would leave very little for the rest of the month. Not recommended.';
        break;
    }

    return RiskAssessment(
      level: level,
      riskScore: percentageOfRemaining.toDouble(),
      factors: factors,
      recommendation: recommendation,
    );
  }

  Future<Map<String, dynamic>> getSpendingTrends() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final allTransactions = await _db.getAllTransactions();

    double currentWeekSpending = 0;
    double lastWeekSpending = 0;
    for (final t in allTransactions) {
      if (t.type == TransactionType.expense) {
        if (t.date.isAfter(weekStart) && t.date.isBefore(weekEnd)) {
          currentWeekSpending += t.amount;
        } else if (t.date.isAfter(weekStart.subtract(const Duration(days: 7))) &&
            t.date.isBefore(weekStart)) {
          lastWeekSpending += t.amount;
        }
      }
    }
    final percentageChange = lastWeekSpending > 0
        ? ((currentWeekSpending - lastWeekSpending) / lastWeekSpending) * 100
        : 0.0;
    return {
      'currentWeek': currentWeekSpending,
      'lastWeek': lastWeekSpending,
      'percentageChange': percentageChange,
      'trend': percentageChange > 0 ? 'increasing' : 'decreasing',
    };
  }

  /// Get monthly spending totals for the last N months
  Future<List<Map<String, dynamic>>> getMonthlyTrend({int months = 6}) async {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = months - 1; i >= 0; i--) {
      final target = DateTime(now.year, now.month - i, 1);
      final txList = await _db.getTransactionsByMonth(target.year, target.month);
      double total = 0;
      for (final t in txList) {
        if (t.type == TransactionType.expense) total += t.amount;
      }
      result.add({
        'month': target,
        'total': total,
      });
    }
    return result;
  }
}
