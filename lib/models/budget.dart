class Budget {
  final String id;
  final String month; // format: "YYYY-MM"
  final String category;
  final double amount;
  double spentCached;

  Budget({
    required this.id,
    required this.month,
    required this.category,
    required this.amount,
    this.spentCached = 0.0,
  });

  double get remaining => amount - spentCached;
  double get percentUsed => amount > 0 ? (spentCached / amount * 100).clamp(0, 100) : 0;
  bool get isOverBudget => spentCached > amount;
  bool get isNearLimit => percentUsed >= 90 && !isOverBudget;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'category': category,
      'amount': amount,
      'spent_cached': spentCached,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      month: map['month'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      spentCached: (map['spent_cached'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Budget copyWith({
    String? id,
    String? month,
    String? category,
    double? amount,
    double? spentCached,
  }) {
    return Budget(
      id: id ?? this.id,
      month: month ?? this.month,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      spentCached: spentCached ?? this.spentCached,
    );
  }
}
