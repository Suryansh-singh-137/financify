class MonthlyFinancialState {
  final double income;
  final double totalSpent;
  final Map<String, double> categorySpending;
  final double remainingBalance;
  final double savingsRate;
  final int daysRemainingInMonth;
  final double healthScore;

  MonthlyFinancialState({
    required this.income,
    required this.totalSpent,
    required this.categorySpending,
    required this.remainingBalance,
    required this.savingsRate,
    required this.daysRemainingInMonth,
    required this.healthScore,
  });

  // Getters for computed values
  double get spentPercentage => income > 0 ? (totalSpent / income) * 100 : 0;
  
  double get dailyBurnRate {
    final daysElapsed = DateTime.now().day;
    return daysElapsed > 0 ? totalSpent / daysElapsed : 0;
  }

  double get projectedMonthlySpending {
    final totalDaysInMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      0,
    ).day;
    return dailyBurnRate * totalDaysInMonth;
  }

  String get healthStatus {
    if (healthScore >= 80) return 'Excellent';
    if (healthScore >= 60) return 'Good';
    if (healthScore >= 40) return 'Fair';
    return 'Needs Attention';
  }

  String get healthEmoji {
    if (healthScore >= 80) return '🟢';
    if (healthScore >= 60) return '🟡';
    if (healthScore >= 40) return '🟠';
    return '🔴';
  }
}

enum RiskLevel { low, medium, high, critical }

class RiskAssessment {
  final RiskLevel level;
  final double riskScore;
  final List<String> factors;
  final String recommendation;

  RiskAssessment({
    required this.level,
    required this.riskScore,
    required this.factors,
    required this.recommendation,
  });

  String get levelText {
    switch (level) {
      case RiskLevel.low:
        return 'LOW';
      case RiskLevel.medium:
        return 'MEDIUM';
      case RiskLevel.high:
        return 'HIGH';
      case RiskLevel.critical:
        return 'CRITICAL';
    }
  }

  String get emoji {
    switch (level) {
      case RiskLevel.low:
        return '✅';
      case RiskLevel.medium:
        return '⚠️';
      case RiskLevel.high:
        return '🚨';
      case RiskLevel.critical:
        return '❌';
    }
  }
}
