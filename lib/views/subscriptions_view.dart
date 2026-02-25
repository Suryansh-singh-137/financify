import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurrence.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

class SubscriptionsView extends StatefulWidget {
  const SubscriptionsView({super.key});

  @override
  State<SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<SubscriptionsView> {
  final SubscriptionService _service = SubscriptionService();
  List<Recurrence> _subscriptions = [];
  double _monthlyTotal = 0;
  bool _isLoading = true;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await _service.detectRecurrences();
    final subs = await _service.getSubscriptions();
    final total = await _service.getMonthlySubscriptionTotal();
    setState(() {
      _subscriptions = subs;
      _monthlyTotal = total;
      _isLoading = false;
    });
  }

  // Build calendar markers for subscriptions
  Map<int, List<Recurrence>> _getCalendarMarkers() {
    final markers = <int, List<Recurrence>>{};
    for (final sub in _subscriptions) {
      final expectedDay = sub.lastSeen.day;
      markers.putIfAbsent(expectedDay, () => []).add(sub);
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Subscriptions'),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildCalendar(),
                    _buildSavingsCard(),
                    _buildUpcomingPayments(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCalendar() {
    final markers = _getCalendarMarkers();
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final totalDays = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textMuted.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day labels
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
            itemCount: startWeekday + totalDays,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox();
              final day = index - startWeekday + 1;
              final hasMarker = markers.containsKey(day);
              final isToday = _selectedMonth.year == DateTime.now().year &&
                  _selectedMonth.month == DateTime.now().month &&
                  day == DateTime.now().day;

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: hasMarker ? const Color(0xFFEF4444).withOpacity(0.15) : (isToday ? AppColors.accentCyan.withOpacity(0.15) : null),
                  shape: BoxShape.circle,
                  border: isToday ? Border.all(color: AppColors.accentCyan, width: 1.5) : null,
                ),
                child: Center(
                  child: hasMarker
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$day', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                          ],
                        )
                      : Text('$day', style: TextStyle(fontSize: 12, color: isToday ? AppColors.accentCyan : AppColors.textSecondary)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lower Your Bills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  'You spend ₹${_monthlyTotal.toStringAsFixed(0)}/month on ${_subscriptions.length} subscriptions',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPayments() {
    final upcoming = [..._subscriptions]..sort((a, b) => a.nextExpectedDate.compareTo(b.nextExpectedDate));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upcoming Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          if (upcoming.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16)),
              child: const Center(
                child: Column(children: [
                  Text('🔄', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text('No subscriptions detected yet', style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('Add transactions to detect patterns', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcoming.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _buildSubscriptionTile(upcoming[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTile(Recurrence rec) {
    final merchantColors = {
      'netflix': const Color(0xFFE50914),
      'spotify': const Color(0xFF1DB954),
      'icloud': const Color(0xFF0A84FF),
      'icloudplus': const Color(0xFF0A84FF),
      'youtube': const Color(0xFFFF0000),
      'amazon': const Color(0xFFFF9900),
      'amazonprime': const Color(0xFF00A8E8),
    };

    final key = rec.merchantKey;
    final color = merchantColors[key] ?? AppColors.accentViolet;
    final nextDate = rec.nextExpectedDate;

    return Dismissible(
      key: Key(rec.id),
      background: Container(
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Dismiss Subscription'),
            content: Text('Mark ${rec.merchantDisplay} as not a subscription?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Dismiss', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await _service.dismissSubscription(rec.id);
        await _load();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(
                  rec.merchantDisplay.substring(0, rec.merchantDisplay.length.clamp(0, 2)).toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rec.merchantDisplay, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Due ${DateFormat('MMM d').format(nextDate)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      if (rec.confirmed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.accentGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Confirmed', style: TextStyle(color: AppColors.accentGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${rec.avgAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(rec.cadenceLabel.toUpperCase(), style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
