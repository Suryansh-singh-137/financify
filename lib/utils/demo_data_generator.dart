import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';
import '../services/subscription_service.dart';
import '../services/insights_service.dart';
import '../services/budget_service.dart';

class DemoDataGenerator {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _random = Random();
  final _uuid = const Uuid();

  Future<void> generateDemoData() async {
    await _db.clearAllData();

    final now = DateTime.now();

    // Set income for last 3 months
    for (int m = 0; m < 3; m++) {
      final target = DateTime(now.year, now.month - m, 1);
      await _db.setMonthlyIncome(target.year, target.month, 35000.0);
    }

    // ── Subscriptions (same merchant × 3 months = detected) ───
    final subs = [
      {'merchant': 'Netflix', 'category': 'bills', 'amount': 649.0},
      {'merchant': 'Spotify', 'category': 'bills', 'amount': 119.0},
      {'merchant': 'iCloud+', 'category': 'bills', 'amount': 75.0},
      {'merchant': 'YouTube Premium', 'category': 'bills', 'amount': 189.0},
      {'merchant': 'Amazon Prime', 'category': 'bills', 'amount': 299.0},
    ];

    for (final sub in subs) {
      for (int m = 0; m < 3; m++) {
        final target = DateTime(now.year, now.month - m, 5 + _random.nextInt(5));
        await _db.insertTransaction(Transaction(
          id: _uuid.v4(),
          amount: (sub['amount'] as double) + _random.nextDouble() * 0,
          merchant: sub['merchant'] as String,
          category: sub['category'] as String,
          description: '${sub['merchant']} subscription',
          date: target,
          type: TransactionType.expense,
          isRecurring: true,
          importedFrom: 'demo',
        ));
      }
    }

    // ── Variable expenses for last 2 months ───────────────────
    final templates = [
      {'category': 'food', 'merchants': ['Zomato', 'Swiggy', 'BigBasket', 'DMart', 'Blinkit', 'Cafe Coffee Day'], 'min': 80, 'max': 1200},
      {'category': 'transport', 'merchants': ['Uber', 'Ola', 'BMTC Bus', 'Metro Card', 'Rapido', 'InDrive'], 'min': 40, 'max': 450},
      {'category': 'shopping', 'merchants': ['Flipkart', 'Amazon', 'Myntra', 'Meesho', 'Nykaa', 'H&M'], 'min': 500, 'max': 4500},
      {'category': 'entertainment', 'merchants': ['BookMyShow', 'PVR Cinemas', 'Steam', 'PlayStation', 'Lenskart'], 'min': 200, 'max': 1500},
      {'category': 'health', 'merchants': ['PharmEasy', '1mg', 'Cult.fit Gym', 'Apollo Pharmacy', 'HealthifyMe'], 'min': 150, 'max': 2000},
      {'category': 'food', 'merchants': ['Starbucks', 'McDonald\'s', 'Dominos', 'Haldirams', 'KFC'], 'min': 120, 'max': 800},
    ];

    for (int monthOffset = 0; monthOffset < 2; monthOffset++) {
      final targetMonth = DateTime(now.year, now.month - monthOffset, 1);
      final daysInMonth = monthOffset == 0 ? now.day : DateTime(now.year, now.month - monthOffset + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final txCount = 2 + _random.nextInt(3);
        for (int i = 0; i < txCount; i++) {
          final t = templates[_random.nextInt(templates.length)];
          final merchants = t['merchants'] as List<String>;
          final merchant = merchants[_random.nextInt(merchants.length)];
          final min = t['min'] as int;
          final max = t['max'] as int;
          final amount = (min + _random.nextInt(max - min)).toDouble();
          await _db.insertTransaction(Transaction(
            id: _uuid.v4(),
            amount: amount,
            merchant: merchant,
            category: t['category'] as String,
            description: merchant,
            date: DateTime(targetMonth.year, targetMonth.month, day, 9 + _random.nextInt(12), _random.nextInt(60)),
            type: TransactionType.expense,
            importedFrom: 'demo',
          ));
        }
      }
    }

    // ── A few big-ticket items for insight demonstration ──────
    final bigTicket = [
      Transaction(id: _uuid.v4(), amount: 6499, merchant: 'Croma', category: 'shopping', description: 'JBL Headphones', date: DateTime(now.year, now.month, _clamp(now.day - 3, 1, 28)), type: TransactionType.expense, importedFrom: 'demo'),
      Transaction(id: _uuid.v4(), amount: 2800, merchant: 'Zara', category: 'shopping', description: 'Clothing', date: DateTime(now.year, now.month, _clamp(now.day - 7, 1, 28)), type: TransactionType.expense, importedFrom: 'demo'),
      Transaction(id: _uuid.v4(), amount: 1400, merchant: 'Social Pub', category: 'entertainment', description: 'Dinner with friends', date: DateTime(now.year, now.month, _clamp(now.day - 5, 1, 28)), type: TransactionType.expense, importedFrom: 'demo'),
    ];
    for (final t in bigTicket) {
      await _db.insertTransaction(t);
    }

    // ── Set up default budgets ────────────────────────────────
    final budgetService = BudgetService();
    final categoryBudgets = {
      'food': 8000.0,
      'transport': 3000.0,
      'shopping': 5000.0,
      'bills': 3000.0,
      'entertainment': 2000.0,
      'health': 2000.0,
    };
    for (final entry in categoryBudgets.entries) {
      await budgetService.createBudget(
        year: now.year,
        month: now.month,
        category: entry.key,
        amount: entry.value,
      );
    }

    // ── Run subscription detection ────────────────────────────
    final subService = SubscriptionService();
    await subService.detectRecurrences();

    // ── Generate insights ─────────────────────────────────────
    final insightsService = InsightsService();
    await insightsService.generateInsights(now.year, now.month);
  }

  int _clamp(int val, int min, int max) {
    if (val < min) return min;
    if (val > max) return max;
    return val;
  }
}
