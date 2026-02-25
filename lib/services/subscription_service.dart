import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/recurrence.dart';
import '../models/transaction.dart';

/// Rule-based subscription detection engine.
/// Two transactions from same merchant, similar amount (±15%), with cadence.
class SubscriptionService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  /// Normalize merchant name for grouping
  String _normalizeMerchant(String merchant) {
    return merchant
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  /// Returns cadence in days for a given RecurrenceCadence
  int _cadenceDays(RecurrenceCadence c) {
    switch (c) {
      case RecurrenceCadence.weekly:
        return 7;
      case RecurrenceCadence.biweekly:
        return 14;
      case RecurrenceCadence.monthly:
        return 30;
      case RecurrenceCadence.quarterly:
        return 91;
      case RecurrenceCadence.annual:
        return 365;
      case RecurrenceCadence.unknown:
        return 30;
    }
  }

  RecurrenceCadence _detectCadence(List<DateTime> dates) {
    if (dates.length < 2) return RecurrenceCadence.unknown;
    dates.sort();
    // Average gap in days
    int totalGap = 0;
    for (int i = 1; i < dates.length; i++) {
      totalGap += dates[i].difference(dates[i - 1]).inDays;
    }
    final avgGap = totalGap / (dates.length - 1);
    if (avgGap <= 10) return RecurrenceCadence.weekly;
    if (avgGap <= 20) return RecurrenceCadence.biweekly;
    if (avgGap <= 45) return RecurrenceCadence.monthly;
    if (avgGap <= 120) return RecurrenceCadence.quarterly;
    if (avgGap <= 400) return RecurrenceCadence.annual;
    return RecurrenceCadence.unknown;
  }

  /// Scans all transactions and detects recurring subscriptions.
  /// Creates / updates records in the recurrences table.
  Future<List<Recurrence>> detectRecurrences() async {
    final transactions = await _db.getAllTransactions();

    // Group expenses by normalized merchant
    final Map<String, List<Transaction>> groups = {};
    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        final key = _normalizeMerchant(t.merchant);
        if (key.isEmpty) continue;
        groups.putIfAbsent(key, () => []).add(t);
      }
    }

    final detected = <Recurrence>[];

    for (final entry in groups.entries) {
      final key = entry.key;
      final txList = entry.value;
      if (txList.length < 2) continue;

      // Check if amounts are similar (within 15%)
      txList.sort((a, b) => a.date.compareTo(b.date));
      final amounts = txList.map((t) => t.amount).toList();
      final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      final allSimilar = amounts.every((a) => (a - avgAmount).abs() / avgAmount <= 0.15);
      if (!allSimilar) continue;

      final dates = txList.map((t) => t.date).toList();
      final cadence = _detectCadence(dates);

      // Verify the gap matches cadence (at least 2 occurrences at right interval)
      final expectedDays = _cadenceDays(cadence);
      bool hasValidCadence = false;
      for (int i = 1; i < dates.length; i++) {
        final gap = dates[i].difference(dates[i - 1]).inDays;
        if ((gap - expectedDays).abs() <= expectedDays * 0.4) {
          hasValidCadence = true;
          break;
        }
      }
      if (!hasValidCadence && txList.length < 3) continue;

      final merchantDisplay = txList.first.merchant;
      final existing = await _db.getRecurrences(excludeDismissed: false);
      final existingRec = existing.where((r) => r.merchantKey == key).firstOrNull;

      if (existingRec != null) {
        if (existingRec.dismissed) continue; // user dismissed
        final updated = existingRec.copyWith(
          avgAmount: avgAmount,
          cadence: cadence,
          lastSeen: dates.last,
        );
        await _db.upsertRecurrence(updated);
        detected.add(updated);
      } else {
        final rec = Recurrence(
          id: _uuid.v4(),
          merchantKey: key,
          merchantDisplay: merchantDisplay,
          avgAmount: avgAmount,
          cadence: cadence,
          firstSeen: dates.first,
          lastSeen: dates.last,
        );
        await _db.upsertRecurrence(rec);
        detected.add(rec);
      }
    }

    return detected;
  }

  Future<List<Recurrence>> getSubscriptions() => _db.getRecurrences();

  Future<void> confirmSubscription(String id) =>
      _db.updateRecurrenceStatus(id, confirmed: true);

  Future<void> dismissSubscription(String id) =>
      _db.updateRecurrenceStatus(id, dismissed: true);

  Future<double> getMonthlySubscriptionTotal() async {
    final recs = await _db.getRecurrences();
    double total = 0;
    for (final r in recs) {
      switch (r.cadence) {
        case RecurrenceCadence.monthly:
          total += r.avgAmount;
          break;
        case RecurrenceCadence.weekly:
          total += r.avgAmount * 4.33;
          break;
        case RecurrenceCadence.biweekly:
          total += r.avgAmount * 2.17;
          break;
        case RecurrenceCadence.quarterly:
          total += r.avgAmount / 3;
          break;
        case RecurrenceCadence.annual:
          total += r.avgAmount / 12;
          break;
        case RecurrenceCadence.unknown:
          total += r.avgAmount;
          break;
      }
    }
    return total;
  }
}
