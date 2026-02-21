import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';

class DemoDataGenerator {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _random = Random();
  final _uuid = const Uuid();

  /// Generate realistic demo data for hackathon presentation
  Future<void> generateDemoData() async {
    // Clear existing data first
    await _db.clearAllData();

    // Set monthly income
    await _db.setMonthlyIncome(
      DateTime.now().year,
      DateTime.now().month,
      25000.0, // ₹25,000 monthly income
    );

    // Generate transactions for current month
    await _generateCurrentMonthTransactions();
  }

  Future<void> _generateCurrentMonthTransactions() async {
    final now = DateTime.now();
    final currentDay = now.day;

    // Transaction templates with realistic amounts
    final templates = [
      // Food
      {'category': 'food', 'descriptions': ['Coffee', 'Lunch', 'Groceries', 'Dinner', 'Snacks'], 'minAmount': 50, 'maxAmount': 1200},
      // Transport
      {'category': 'transport', 'descriptions': ['Uber', 'Metro', 'Bus', 'Auto', 'Fuel'], 'minAmount': 30, 'maxAmount': 500},
      // Shopping
      {'category': 'shopping', 'descriptions': ['Clothes', 'Electronics', 'Shoes', 'Accessories'], 'minAmount': 500, 'maxAmount': 3000},
      // Bills
      {'category': 'bills', 'descriptions': ['Netflix', 'Internet', 'Phone', 'Electricity', 'Rent'], 'minAmount': 200, 'maxAmount': 10000},
      // Entertainment
      {'category': 'entertainment', 'descriptions': ['Movie', 'Concert', 'Gaming', 'Sports'], 'minAmount': 200, 'maxAmount': 1500},
      // Health
      {'category': 'health', 'descriptions': ['Gym', 'Medicine', 'Doctor', 'Supplements'], 'minAmount': 100, 'maxAmount': 2000},
    ];

    // Generate 2-4 transactions per day
    for (int day = 1; day <= currentDay; day++) {
      final transactionsPerDay = 2 + _random.nextInt(3); // 2-4 transactions

      for (int i = 0; i < transactionsPerDay; i++) {
        final template = templates[_random.nextInt(templates.length)];
        final descriptions = template['descriptions'] as List<String>;
        final description = descriptions[_random.nextInt(descriptions.length)];
        
        final minAmount = template['minAmount'] as int;
        final maxAmount = template['maxAmount'] as int;
        final amount = (minAmount + _random.nextInt(maxAmount - minAmount)).toDouble();

        final transactionDate = DateTime(
          now.year,
          now.month,
          day,
          _random.nextInt(24), // Random hour
          _random.nextInt(60), // Random minute
        );

        final transaction = Transaction(
          id: _uuid.v4(),
          amount: amount,
          category: template['category'] as String,
          description: description,
          date: transactionDate,
          type: TransactionType.expense,
        );

        await _db.insertTransaction(transaction);
      }
    }

    // Add some specific high-value transactions for demo
    final demoTransactions = [
      Transaction(
        id: _uuid.v4(),
        amount: 1200,
        category: 'food',
        description: 'Restaurant dinner with friends',
        date: DateTime(now.year, now.month, now.day - 2),
        type: TransactionType.expense,
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 5000,
        category: 'shopping',
        description: 'New smartphone accessories',
        date: DateTime(now.year, now.month, now.day - 5),
        type: TransactionType.expense,
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 499,
        category: 'bills',
        description: 'Netflix subscription',
        date: DateTime(now.year, now.month, 1),
        type: TransactionType.expense,
      ),
    ];

    for (final transaction in demoTransactions) {
      await _db.insertTransaction(transaction);
    }
  }

  /// Clear all demo data
  Future<void> clearDemoData() async {
    await _db.clearAllData();
  }
}
