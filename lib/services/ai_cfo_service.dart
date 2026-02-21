import 'package:flutter/foundation.dart';
import 'package:runanywhere/runanywhere.dart';
import '../models/financial_state.dart';
import 'prompt_builder.dart';
import 'finance_engine.dart';

class AICFOService extends ChangeNotifier {
  final FinanceEngine _financeEngine = FinanceEngine();
  
  bool _isGenerating = false;
  String _lastResponse = '';
  String _lastError = '';

  bool get isGenerating => _isGenerating;
  String get lastResponse => _lastResponse;
  String get lastError => _lastError;

  /// Ask a general financial question
  Future<String> askQuestion(String question) async {
    try {
      _isGenerating = true;
      _lastError = '';
      notifyListeners();

      // Get current financial state
      final state = await _financeEngine.calculateMonthlyState();

      // Check if question is about a specific purchase
      final purchaseAmount = _extractPurchaseAmount(question);
      RiskAssessment? risk;
      
      if (purchaseAmount != null) {
        risk = _financeEngine.assessPurchase(purchaseAmount, state);
      }

      // Check if question is about a specific category
      final category = _extractCategory(question);

      // Build prompt
      final prompt = PromptBuilder.buildFullPrompt(
        userQuery: question,
        state: state,
        purchaseAmount: purchaseAmount,
        risk: risk,
        category: category,
      );

      // Generate response using RunAnywhere LLM
      final response = await _generateResponse(prompt);

      _lastResponse = response;
      _isGenerating = false;
      notifyListeners();

      return response;
    } catch (e) {
      _lastError = e.toString();
      _isGenerating = false;
      notifyListeners();
      return 'Sorry, I encountered an error processing your question. Please make sure the LLM model is loaded and try again.';
    }
  }

  /// Generate AI response using RunAnywhere
  Future<String> _generateResponse(String prompt) async {
    if (!RunAnywhere.isModelLoaded) {
      throw Exception('LLM model is not loaded. Please load the model first.');
    }

    final responseBuffer = StringBuffer();

    try {
      final result = await RunAnywhere.generateStream(
        prompt,
        options: const LLMGenerationOptions(
          maxTokens: 200, // Keep responses concise
          temperature: 0.7,
        ),
      );
      
      await for (final token in result.stream) {
        responseBuffer.write(token);
      }
    } catch (e) {
      throw Exception('Failed to generate response: $e');
    }

    return responseBuffer.toString().trim();
  }

  /// Extract purchase amount from question
  /// Looks for patterns like "₹5000", "Rs 5000", "5000 rupees"
  double? _extractPurchaseAmount(String question) {
    // Pattern: ₹5000 or Rs 5000 or 5000 rupees
    final patterns = [
      RegExp(r'₹\s*(\d+(?:,\d+)*)'),
      RegExp(r'Rs\.?\s*(\d+(?:,\d+)*)'),
      RegExp(r'(\d+(?:,\d+)*)\s*rupees?'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(question);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        return double.tryParse(amountStr);
      }
    }

    return null;
  }

  /// Extract category from question
  String? _extractCategory(String question) {
    final lowerQuestion = question.toLowerCase();
    final categories = [
      'food',
      'transport',
      'shopping',
      'bills',
      'entertainment',
      'health',
      'education',
      'savings',
    ];

    for (final category in categories) {
      if (lowerQuestion.contains(category)) {
        return category;
      }
    }

    return null;
  }

  /// Get quick financial summary (without full AI generation)
  Future<String> getQuickSummary() async {
    final state = await _financeEngine.calculateMonthlyState();
    
    final buffer = StringBuffer();
    buffer.writeln('💰 Financial Health: ${state.healthScore.toStringAsFixed(0)}/100 ${state.healthEmoji}');
    buffer.writeln('💵 Remaining: ₹${state.remainingBalance.toStringAsFixed(0)}');
    buffer.writeln('📊 Spent: ${state.spentPercentage.toStringAsFixed(0)}%');
    buffer.writeln('💾 Savings Rate: ${state.savingsRate.toStringAsFixed(0)}%');
    
    return buffer.toString();
  }

  /// Clear last response
  void clearLastResponse() {
    _lastResponse = '';
    _lastError = '';
    notifyListeners();
  }
}
