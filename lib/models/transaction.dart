import 'package:intl/intl.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String accountId;
  final double amount;
  final String merchant; // merchant / payee name
  final String category;
  final String description; // legacy / note
  final DateTime date;
  final TransactionType type;
  final bool isRecurring;
  final String? recurrenceId;
  final String tags; // comma-separated
  final String importedFrom; // 'manual', 'csv', 'demo'
  final DateTime createdAt;

  Transaction({
    required this.id,
    this.accountId = 'default',
    required this.amount,
    String? merchant,
    required this.category,
    required this.description,
    required this.date,
    required this.type,
    this.isRecurring = false,
    this.recurrenceId,
    this.tags = '',
    this.importedFrom = 'manual',
    DateTime? createdAt,
  })  : merchant = merchant ?? description,
        createdAt = createdAt ?? DateTime.now();

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'amount': amount,
      'merchant': merchant,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'type': type.name,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_id': recurrenceId,
      'tags': tags,
      'imported_from': importedFrom,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from database Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    final desc = map['description'] as String? ?? '';
    return Transaction(
      id: map['id'] as String,
      accountId: map['account_id'] as String? ?? 'default',
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'] as String? ?? desc,
      category: map['category'] as String,
      description: desc,
      date: DateTime.parse(map['date'] as String),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      isRecurring: (map['is_recurring'] as int?) == 1,
      recurrenceId: map['recurrence_id'] as String?,
      tags: map['tags'] as String? ?? '',
      importedFrom: map['imported_from'] as String? ?? 'manual',
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
    String? accountId,
    double? amount,
    String? merchant,
    String? category,
    String? description,
    DateTime? date,
    TransactionType? type,
    bool? isRecurring,
    String? recurrenceId,
    String? tags,
    String? importedFrom,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceId: recurrenceId ?? this.recurrenceId,
      tags: tags ?? this.tags,
      importedFrom: importedFrom ?? this.importedFrom,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
