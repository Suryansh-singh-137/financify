import 'package:intl/intl.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final TransactionType type;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from database Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: map['amount'] as double,
      category: map['category'] as String,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Helper getters
  String get formattedAmount {
    return '₹${amount.toStringAsFixed(0)}';
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  Transaction copyWith({
    String? id,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    TransactionType? type,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
