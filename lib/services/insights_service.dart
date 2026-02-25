import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/insight.dart';
import '../models/transaction.dart';
import 'subscription_service.dart';

/// Rule-based auto insights generator.
/// Generates at least 3 insights per month from transaction data.
class InsightsService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SubscriptionService _subService = SubscriptionService();
  final _uuid = const Uuid();

  Future<List<Insight>> generateInsights(int year, int month) async {
    final insights = <Insight>[];

    await _db.clearInsights();

    final currentMonthTx = await _db.getTransactionsByMonth(year, month);
    // Get last month transactions for comparison
    final lastMonth = month == 1 ? 12 : month - 1;
    final lastYear = month == 1 ? year - 1 : year;
    final lastMonthTx = await _db.getTransactionsByMonth(lastYear, lastMonth);

    // ── 1. Overall Overspend Alert ─────────────────────────────
    final income = await _db.getMonthlyIncome(year, month);
    double totalSpent = 0;
    for (final t in currentMonthTx) {
      if (t.type == TransactionType.expense) totalSpent += t.amount;
    }
    final spentPct = income > 0 ? (totalSpent / income) * 100 : 0;
    if (spentPct > 80) {
      insights.add(Insight(
        id: _uuid.v4(),
        type: 'overspend',
        title: 'High spending alert',
        body:
            'You\'ve spent ₹${totalSpent.toStringAsFixed(0)} this month — ${spentPct.toStringAsFixed(0)}% of your income. '
            'Consider reducing discretionary spending for the rest of the month.',
      ));
    } else {
      insights.add(Insight(
        id: _uuid.v4(),
        type: 'savings',
        title: 'On track this month',
        body:
            'You\'ve spent ₹${totalSpent.toStringAsFixed(0)} (${spentPct.toStringAsFixed(0)}% of income). '
            'You\'re within a healthy spending range.',
      ));
    }

    // ── 2. Category Spike vs Last Month ───────────────────────
    final Map<String, double> currentCat = {};
    for (final t in currentMonthTx) {
      if (t.type == TransactionType.expense) {
        currentCat[t.category] = (currentCat[t.category] ?? 0) + t.amount;
      }
    }
    final Map<String, double> lastCat = {};
    for (final t in lastMonthTx) {
      if (t.type == TransactionType.expense) {
        lastCat[t.category] = (lastCat[t.category] ?? 0) + t.amount;
      }
    }

    String? spikeCategory;
    double maxChange = 0;
    double spikeCurrentAmt = 0;
    double spikePct = 0;

    for (final cat in currentCat.keys) {
      final curr = currentCat[cat] ?? 0;
      final prev = lastCat[cat] ?? 0;
      if (prev > 0) {
        final change = ((curr - prev) / prev) * 100;
        if (change > maxChange && change > 20) {
          maxChange = change;
          spikeCategory = cat;
          spikeCurrentAmt = curr;
          spikePct = change;
        }
      } else if (curr > 2000) {
        if (spikeCategory == null) {
          spikeCategory = cat;
          spikeCurrentAmt = curr;
          spikePct = 100;
        }
      }
    }

    if (spikeCategory != null) {
      insights.add(Insight(
        id: _uuid.v4(),
        type: 'spike',
        title: '${_capitalize(spikeCategory)} spending spiked',
        body:
            '${_capitalize(spikeCategory)} is up ${spikePct.toStringAsFixed(0)}% vs last month '
            '(₹${spikeCurrentAmt.toStringAsFixed(0)} this month). Review these transactions.',
      ));
    } else {
      // Show top spending category instead
      if (currentCat.isNotEmpty) {
        final topCat =
            currentCat.entries.reduce((a, b) => a.value > b.value ? a : b);
        insights.add(Insight(
          id: _uuid.v4(),
          type: 'spike',
          title: 'Top category: ${_capitalize(topCat.key)}',
          body:
              '${_capitalize(topCat.key)} is your biggest expense this month at ₹${topCat.value.toStringAsFixed(0)}.',
        ));
      }
    }

    // ── 3. Subscription Summary ────────────────────────────────
    final subs = await _subService.getSubscriptions();
    final subTotal = await _subService.getMonthlySubscriptionTotal();
    if (subs.isNotEmpty) {
      insights.add(Insight(
        id: _uuid.v4(),
        type: 'subscription',
        title: '${subs.length} recurring subscriptions detected',
        body:
            'You\'re paying ~₹${subTotal.toStringAsFixed(0)}/month on ${subs.length} subscriptions. '
            'Top one: ${subs.first.merchantDisplay} (₹${subs.first.avgAmount.toStringAsFixed(0)}/mo). '
            'Review if all are still needed.',
      ));
    }

    // ── 4. Largest transaction ─────────────────────────────────
    if (currentMonthTx.isNotEmpty) {
      final largest = currentMonthTx
          .where((t) => t.type == TransactionType.expense)
          .fold<Transaction?>(null, (prev, t) {
        if (prev == null || t.amount > prev.amount) return t;
        return prev;
      });
      if (largest != null && largest.amount > 3000) {
        insights.add(Insight(
          id: _uuid.v4(),
          type: 'general',
          title: 'Largest expense this month',
          body:
              '₹${largest.amount.toStringAsFixed(0)} at ${largest.merchant} on ${_formatDate(largest.date)}. '
              'That\'s ${((largest.amount / income) * 100).toStringAsFixed(1)}% of your monthly income.',
        ));
      }
    }

    // ── 5. Savings rate insight ────────────────────────────────
    final savingsRate = income > 0 ? ((income - totalSpent) / income) * 100 : 0;
    if (savingsRate > 25) {
      insights.add(Insight(
        id: _uuid.v4(),
        type: 'savings',
        title: 'Great savings rate!',
        body:
            'You\'re saving ${savingsRate.toStringAsFixed(0)}% of your income this month. '
            'Financial experts recommend 20%+ — you\'re exceeding that! 🎉',
      ));
    } else if (savingsRate < 10 && income > 0) {
      insights.add(Insight(
        id: _uuid.v4(),
        type: 'savings',
        title: 'Low savings rate',
        body:
            'You\'re saving only ${savingsRate.toStringAsFixed(0)}% this month. '
            'Try to target at least 20% to build a financial buffer.',
      ));
    }

    // Save all insights
    for (final insight in insights) {
      await _db.insertInsight(insight);
    }

    return insights;
  }

  Future<List<Insight>> getInsights() => _db.getInsights();

  Future<void> markSeen(String id) => _db.markInsightSeen(id);

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}
