import '../models/financial_state.dart';

class PromptBuilder {
  /// Build system prompt for the AI CFO
  static String getSystemPrompt() {
    return '''You are a personal CFO (Chief Financial Officer) analyzing someone's finances.
Your role is to provide practical, actionable financial advice based on the data provided.

Guidelines:
- Be concise - respond in exactly 3-4 sentences
- Be honest and realistic, not overly optimistic
- Use Indian currency (₹) in all financial references
- Reference specific numbers from the financial context
- Explain implications clearly
- Suggest concrete next steps
- Be encouraging but realistic
- Focus on actionable advice

Tone: Professional yet friendly, like a trusted financial advisor.''';
  }

  /// Build financial context from monthly state
  static String buildFinancialContext(MonthlyFinancialState state) {
    final buffer = StringBuffer();
    
    buffer.writeln('FINANCIAL CONTEXT:');
    buffer.writeln('Monthly Income: ₹${state.income.toStringAsFixed(0)}');
    buffer.writeln('Total Spent This Month: ₹${state.totalSpent.toStringAsFixed(0)}');
    buffer.writeln('Remaining Balance: ₹${state.remainingBalance.toStringAsFixed(0)}');
    buffer.writeln('Spent Percentage: ${state.spentPercentage.toStringAsFixed(1)}%');
    buffer.writeln('Savings Rate: ${state.savingsRate.toStringAsFixed(1)}%');
    buffer.writeln('Days Remaining in Month: ${state.daysRemainingInMonth}');
    buffer.writeln('Financial Health Score: ${state.healthScore.toStringAsFixed(0)}/100 (${state.healthStatus})');
    buffer.writeln('Daily Burn Rate: ₹${state.dailyBurnRate.toStringAsFixed(0)}/day');
    
    if (state.categorySpending.isNotEmpty) {
      buffer.writeln('\nCATEGORY BREAKDOWN:');
      final sortedCategories = state.categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sortedCategories.take(5)) {
        final percentage = state.income > 0 
            ? (entry.value / state.income) * 100 
            : 0;
        buffer.writeln(
          '${_capitalizeFirst(entry.key)}: ₹${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}% of income)',
        );
      }
    }
    
    return buffer.toString();
  }

  /// Build context for purchase risk assessment
  static String buildPurchaseContext(
    double amount,
    MonthlyFinancialState state,
    RiskAssessment risk,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('PURCHASE ANALYSIS:');
    buffer.writeln('Proposed Purchase Amount: ₹${amount.toStringAsFixed(0)}');
    buffer.writeln('Current Remaining Balance: ₹${state.remainingBalance.toStringAsFixed(0)}');
    buffer.writeln('Balance After Purchase: ₹${(state.remainingBalance - amount).toStringAsFixed(0)}');
    buffer.writeln('Days Remaining: ${state.daysRemainingInMonth}');
    buffer.writeln('Risk Level: ${risk.levelText} ${risk.emoji}');
    buffer.writeln('Risk Score: ${risk.riskScore.toStringAsFixed(1)}% of remaining balance');
    
    if (state.daysRemainingInMonth > 0) {
      final dailyBudgetAfter = 
          (state.remainingBalance - amount) / state.daysRemainingInMonth;
      buffer.writeln('Daily Budget After Purchase: ₹${dailyBudgetAfter.toStringAsFixed(0)}');
    }
    
    return buffer.toString();
  }

  /// Build context for category spending analysis
  static String buildCategoryContext(
    String category,
    MonthlyFinancialState state,
  ) {
    final categoryAmount = state.categorySpending[category] ?? 0;
    final categoryPercentage = state.income > 0 
        ? (categoryAmount / state.income) * 100 
        : 0;
    
    final buffer = StringBuffer();
    buffer.writeln('CATEGORY ANALYSIS:');
    buffer.writeln('Category: ${_capitalizeFirst(category)}');
    buffer.writeln('Amount Spent: ₹${categoryAmount.toStringAsFixed(0)}');
    buffer.writeln('Percentage of Income: ${categoryPercentage.toStringAsFixed(1)}%');
    buffer.writeln('Total Monthly Spending: ₹${state.totalSpent.toStringAsFixed(0)}');
    buffer.writeln('Category as % of Total Spending: ${(state.totalSpent > 0 ? (categoryAmount / state.totalSpent) * 100 : 0).toStringAsFixed(1)}%');
    
    // Add recommended percentages for common categories
    final recommendedPercentages = {
      'food': 20.0,
      'transport': 15.0,
      'shopping': 10.0,
      'bills': 25.0,
      'entertainment': 5.0,
      'health': 10.0,
    };
    
    if (recommendedPercentages.containsKey(category)) {
      buffer.writeln('Recommended Percentage: ${recommendedPercentages[category]}%');
    }
    
    return buffer.toString();
  }

  /// Build full prompt with context and user query
  static String buildFullPrompt({
    required String userQuery,
    required MonthlyFinancialState state,
    double? purchaseAmount,
    RiskAssessment? risk,
    String? category,
  }) {
    final buffer = StringBuffer();
    
    // Add system prompt
    buffer.writeln(getSystemPrompt());
    buffer.writeln();
    
    // Add financial context
    buffer.writeln(buildFinancialContext(state));
    buffer.writeln();
    
    // Add specific context based on query type
    if (purchaseAmount != null && risk != null) {
      buffer.writeln(buildPurchaseContext(purchaseAmount, state, risk));
      buffer.writeln();
    }
    
    if (category != null) {
      buffer.writeln(buildCategoryContext(category, state));
      buffer.writeln();
    }
    
    // Add user query
    buffer.writeln('USER QUESTION:');
    buffer.writeln(userQuery);
    buffer.writeln();
    
    // Add instructions
    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln('- Respond in exactly 3-4 sentences');
    buffer.writeln('- Reference specific numbers from the context');
    buffer.writeln('- Provide actionable advice');
    buffer.writeln('- Be encouraging but realistic');
    
    return buffer.toString();
  }

  /// Suggested questions for quick access
  static List<String> getSuggestedQuestions() {
    return [
      'How is my financial health?',
      'Can I afford ₹5000 for new headphones?',
      'How much did I spend on food this month?',
      'Where am I overspending?',
      'Should I save more money?',
      'What\'s my biggest expense?',
      'Am I spending too fast?',
      'How much can I safely spend today?',
    ];
  }

  /// Helper to capitalize first letter
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
