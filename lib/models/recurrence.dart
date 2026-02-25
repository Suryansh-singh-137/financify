enum RecurrenceCadence { weekly, biweekly, monthly, quarterly, annual, unknown }

class Recurrence {
  final String id;
  final String merchantKey;
  final String merchantDisplay;
  final double avgAmount;
  final RecurrenceCadence cadence;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final bool confirmed; // user confirmed it's a subscription
  final bool dismissed; // user said "not a subscription"

  const Recurrence({
    required this.id,
    required this.merchantKey,
    required this.merchantDisplay,
    required this.avgAmount,
    required this.cadence,
    required this.firstSeen,
    required this.lastSeen,
    this.confirmed = false,
    this.dismissed = false,
  });

  String get cadenceLabel {
    switch (cadence) {
      case RecurrenceCadence.weekly:
        return 'Weekly';
      case RecurrenceCadence.biweekly:
        return 'Every 2 weeks';
      case RecurrenceCadence.monthly:
        return 'Monthly';
      case RecurrenceCadence.quarterly:
        return 'Quarterly';
      case RecurrenceCadence.annual:
        return 'Annual';
      case RecurrenceCadence.unknown:
        return 'Recurring';
    }
  }

  /// Next expected charge date based on last seen + cadence
  DateTime get nextExpectedDate {
    switch (cadence) {
      case RecurrenceCadence.weekly:
        return lastSeen.add(const Duration(days: 7));
      case RecurrenceCadence.biweekly:
        return lastSeen.add(const Duration(days: 14));
      case RecurrenceCadence.monthly:
        return DateTime(lastSeen.year, lastSeen.month + 1, lastSeen.day);
      case RecurrenceCadence.quarterly:
        return DateTime(lastSeen.year, lastSeen.month + 3, lastSeen.day);
      case RecurrenceCadence.annual:
        return DateTime(lastSeen.year + 1, lastSeen.month, lastSeen.day);
      case RecurrenceCadence.unknown:
        return lastSeen.add(const Duration(days: 30));
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant_key': merchantKey,
      'merchant_display': merchantDisplay,
      'avg_amount': avgAmount,
      'cadence': cadence.name,
      'first_seen': firstSeen.toIso8601String(),
      'last_seen': lastSeen.toIso8601String(),
      'confirmed': confirmed ? 1 : 0,
      'dismissed': dismissed ? 1 : 0,
    };
  }

  factory Recurrence.fromMap(Map<String, dynamic> map) {
    return Recurrence(
      id: map['id'] as String,
      merchantKey: map['merchant_key'] as String,
      merchantDisplay: map['merchant_display'] as String? ?? map['merchant_key'] as String,
      avgAmount: (map['avg_amount'] as num).toDouble(),
      cadence: RecurrenceCadence.values.firstWhere(
        (e) => e.name == map['cadence'],
        orElse: () => RecurrenceCadence.monthly,
      ),
      firstSeen: DateTime.parse(map['first_seen'] as String),
      lastSeen: DateTime.parse(map['last_seen'] as String),
      confirmed: (map['confirmed'] as int?) == 1,
      dismissed: (map['dismissed'] as int?) == 1,
    );
  }

  Recurrence copyWith({
    String? id,
    String? merchantKey,
    String? merchantDisplay,
    double? avgAmount,
    RecurrenceCadence? cadence,
    DateTime? firstSeen,
    DateTime? lastSeen,
    bool? confirmed,
    bool? dismissed,
  }) {
    return Recurrence(
      id: id ?? this.id,
      merchantKey: merchantKey ?? this.merchantKey,
      merchantDisplay: merchantDisplay ?? this.merchantDisplay,
      avgAmount: avgAmount ?? this.avgAmount,
      cadence: cadence ?? this.cadence,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      confirmed: confirmed ?? this.confirmed,
      dismissed: dismissed ?? this.dismissed,
    );
  }
}
