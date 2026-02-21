import '../models/transaction.dart';
import '../models/financial_state.dart';
import '../database/database_helper.dart';

class FinanceEngine {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Calculate the complete financial state for current month
  Future<MonthlyFinancialState> calculateMonthlyState() async {
    final now = DateTime.now();
    final transactions = await _db.getTransactionsByMonth(now.year, now.month);
    final income = await _db.getMonthlyIncome(now.year, now.month);

    // Calculate total spent and category breakdown
    double totalSpent = 0.0;
    final Map<String, double> categorySpending = {};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        totalSpent += transaction.amount;
        categorySpending[transaction.category] =
            (categorySpending[transaction.category] ?? 0) + transaction.amount;
      }
    }

    // Calculate remaining balance
    final remainingBalance = income - totalSpent;

    // Calculate savings rate
    final savingsRate = income > 0 ? ((remainingBalance / income) * 100).toDouble() : 0.0;

    // Calculate days remaining in month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = lastDayOfMonth - now.day;

    // Calculate health score
    final healthScore = _calculateHealthScore(
      income: income,
      totalSpent: totalSpent,
      remainingBalance: remainingBalance,
      daysRemaining: daysRemaining,
      categorySpending: categorySpending,
    );

    return MonthlyFinancialState(
      income: income,
      totalSpent: totalSpent,
      categorySpending: categorySpending,
      remainingBalance: remainingBalance,
      savingsRate: savingsRate,
      daysRemainingInMonth: daysRemaining,
      healthScore: healthScore,
    );
  }

  /// Calculate financial health score (0-100)
  /// Algorithm:
  /// - 40% Savings Rate Weight
  /// - 30% Budget Adherence Weight
  /// - 20% Spending Consistency Weight
  /// - 10% Emergency Buffer Weight
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
      savingsScore = 40; // Excellent
    } else if (savingsRate >= 20) {
      savingsScore = 35; // Great
    } else if (savingsRate >= 15) {
      savingsScore = 30; // Good
    } else if (savingsRate >= 10) {
      savingsScore = 20; // Fair
    } else if (savingsRate >= 5) {
      savingsScore = 10; // Poor
    }

    // 2. Budget Adherence Weight (30 points)
    final spentPercentage = income > 0 ? (totalSpent / income) * 100 : 0;
    final now = DateTime.now();
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.day;
    final expectedSpentPercentage =
        (daysElapsed / totalDaysInMonth) * 100;

    double adherenceScore = 0;
    final adherenceDiff = (spentPercentage - expectedSpentPercentage).abs();
    if (adherenceDiff <= 5) {
      adherenceScore = 30; // Perfect pace
    } else if (adherenceDiff <= 10) {
      adherenceScore = 25;
    } else if (adherenceDiff <= 15) {
      adherenceScore = 20;
    } else if (adherenceDiff <= 25) {
      adherenceScore = 15;
    } else {
      adherenceScore = 10;
    }

    // 3. Spending Consistency Weight (20 points)
    // Check if any category exceeds recommended percentage
    double consistencyScore = 20;
    final foodSpending = categorySpending['food'] ?? 0;
    final foodPercentage = income > 0 ? (foodSpending / income) * 100 : 0;
    if (foodPercentage > 25) consistencyScore -= 5;

    final shoppingSpending = categorySpending['shopping'] ?? 0;
    final shoppingPercentage =
        income > 0 ? (shoppingSpending / income) * 100 : 0;
    if (shoppingPercentage > 15) consistencyScore -= 5;

    // 4. Emergency Buffer Weight (10 points)
    double bufferScore = 0;
    final dailyBudget =
        daysRemaining > 0 ? remainingBalance / daysRemaining : 0;
    if (dailyBudget >= 500) {
      bufferScore = 10;
    } else if (dailyBudget >= 300) {
      bufferScore = 7;
    } else if (dailyBudget >= 150) {
      bufferScore = 5;
    } else if (dailyBudget >= 100) {
      bufferScore = 3;
    }

    final totalScore = savingsScore + adherenceScore + consistencyScore + bufferScore;
    return totalScore.clamp(0, 100);
  }

  /// Assess risk for a proposed purchase
  RiskAssessment assessPurchase(
    double amount,
    MonthlyFinancialState state,
  ) {
    final percentageOfRemaining =
        state.remainingBalance > 0
            ? (amount / state.remainingBalance) * 100
            : 100;

    // Determine risk level
    RiskLevel level;
    if (percentageOfRemaining < 10) {
      level = RiskLevel.low;
    } else if (percentageOfRemaining < 25) {
      level = RiskLevel.medium;
    } else if (percentageOfRemaining < 50) {
      level = RiskLevel.high;
    } else {
      level = RiskLevel.critical;
    }

    // Generate risk factors
    final factors = <String>[];
    factors.add(
      'Purchase is ${percentageOfRemaining.toStringAsFixed(1)}% of remaining balance',
    );

    if (state.daysRemainingInMonth > 0) {
      final remainingAfter = state.remainingBalance - amount;
      final dailyBudgetAfter = remainingAfter / state.daysRemainingInMonth;
      factors.add(
        'Daily budget after purchase: ₹${dailyBudgetAfter.toStringAsFixed(0)}',
      );
    }

    if (state.savingsRate < 15) {
      factors.add('Current savings rate is below recommended 15%');
    }

    // Generate recommendation
    String recommendation;
    switch (level) {
      case RiskLevel.low:
        recommendation =
            'This purchase is safe and within your budget. Go ahead!';
        break;
      case RiskLevel.medium:
        recommendation =
            'Consider if this purchase is necessary. You can afford it but it will impact your buffer.';
        break;
      case RiskLevel.high:
        recommendation =
            'High risk - This will significantly reduce your remaining balance. Consider postponing.';
        break;
      case RiskLevel.critical:
        recommendation =
            'Critical risk - This purchase would leave you with very little for the rest of the month. Strongly not recommended.';
        break;
    }

    return RiskAssessment(
      level: level,
      riskScore: percentageOfRemaining.toDouble(),
      factors: factors,
      recommendation: recommendation,
    );
  }

  /// Get spending trends (week over week)
  Future<Map<String, dynamic>> getSpendingTrends() async {
    final now = DateTime.now();
    
    // Current week spending
    final weekStart = now.subtract(Duration(days: (now.weekday - 1)));
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    final allTransactions = await _db.getAllTransactions();
    
    double currentWeekSpending = 0;
    double lastWeekSpending = 0;
    
    for (final transaction in allTransactions) {
      if (transaction.type == TransactionType.expense) {
        if (transaction.date.isAfter(weekStart) && 
            transaction.date.isBefore(weekEnd)) {
          currentWeekSpending += transaction.amount;
        } else if (transaction.date.isAfter(weekStart.subtract(const Duration(days: 7))) &&
                   transaction.date.isBefore(weekStart)) {
          lastWeekSpending += transaction.amount;
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
}
