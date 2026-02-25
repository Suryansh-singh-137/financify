import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/insight.dart';
import '../services/insights_service.dart';
import '../services/finance_engine.dart';
import '../theme/app_theme.dart';

class InsightsView extends StatefulWidget {
  const InsightsView({super.key});

  @override
  State<InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<InsightsView> with SingleTickerProviderStateMixin {
  final InsightsService _insightsService = InsightsService();
  final FinanceEngine _engine = FinanceEngine();
  List<Insight> _insights = [];
  List<Map<String, dynamic>> _monthlyTrend = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final insights = await _insightsService.getInsights();
    final trend = await _engine.getMonthlyTrend(months: 6);
    setState(() {
      _insights = insights;
      _monthlyTrend = trend;
      _isLoading = false;
    });
  }

  Future<void> _generateInsights() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    await _insightsService.generateInsights(now.year, now.month);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(icon: const Icon(Icons.auto_awesome), onPressed: _generateInsights, tooltip: 'Regenerate'),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentCyan,
          labelColor: AppColors.accentCyan,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Insights'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInsightsTab(),
                _buildTrendsTab(),
              ],
            ),
    );
  }

  Widget _buildInsightsTab() {
    if (_insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💡', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('No insights yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Load demo data or add transactions to get insights', style: TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateInsights,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Insights'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _insights.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildInsightCard(_insights[i]),
      ),
    );
  }

  Widget _buildInsightCard(Insight insight) {
    final typeColors = {
      'overspend': AppColors.error,
      'spike': AppColors.warning,
      'subscription': AppColors.accentViolet,
      'savings': AppColors.accentGreen,
      'budget': AppColors.accentCyan,
      'general': AppColors.info,
    };
    final color = typeColors[insight.type] ?? AppColors.info;

    return GestureDetector(
      onTap: () {
        if (!insight.seen) {
          _insightsService.markSeen(insight.id);
          setState(() => insight.seen = true);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: insight.seen ? AppColors.textMuted.withOpacity(0.1) : color.withOpacity(0.4), width: insight.seen ? 1 : 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(insight.emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 15)),
                      ),
                      if (!insight.seen)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(insight.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    if (_monthlyTrend.isEmpty) {
      return const Center(child: Text('No trend data available', style: TextStyle(color: AppColors.textMuted)));
    }

    final maxValue = _monthlyTrend.map((m) => m['total'] as double).fold(0.0, (a, b) => a > b ? a : b);
    final spots = _monthlyTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['total'] as double));
    }).toList();

    final months = _monthlyTrend.map((m) {
      final date = m['month'] as DateTime;
      return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Spending (6 months)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20)),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? maxValue / 4 : 10000,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.textMuted.withOpacity(0.1), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i >= 0 && i < months.length) {
                          return Text(months[i], style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
                        }
                        return const SizedBox();
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text('₹${(v / 1000).toStringAsFixed(0)}k', style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
                      reservedSize: 36,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(colors: [AppColors.accentCyan, AppColors.accentViolet]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                        radius: 5,
                        color: AppColors.accentCyan,
                        strokeWidth: 2,
                        strokeColor: AppColors.primaryDark,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.accentCyan.withOpacity(0.2), AppColors.accentCyan.withOpacity(0.0)],
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxValue * 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Month Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._monthlyTrend.reversed.map((m) {
            final date = m['month'] as DateTime;
            final total = m['total'] as double;
            final monthName = ['January','February','March','April','May','June','July','August','September','October','November','December'][date.month - 1];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Text('$monthName ${date.year}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const Spacer(),
                  Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
