import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/finance_engine.dart';
import '../services/model_service.dart';
import '../models/financial_state.dart';
import '../models/transaction.dart' as models;
import '../models/category.dart';
import '../database/database_helper.dart';
import '../utils/demo_data_generator.dart';
import '../theme/app_theme.dart';
import 'add_expense_view.dart';
import '../widgets/category_chart.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final FinanceEngine _financeEngine = FinanceEngine();
  final DatabaseHelper _db = DatabaseHelper.instance;

  MonthlyFinancialState? _financialState;
  List<models.Transaction> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final state = await _financeEngine.calculateMonthlyState();
      final transactions = await _db.getTransactionsByMonth(
        DateTime.now().year,
        DateTime.now().month,
      );
      setState(() {
        _financialState = state;
        _recentTransactions = transactions.take(8).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelService = Provider.of<ModelService>(context);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.accentCyan.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.account_balance_wallet, color: AppColors.accentCyan, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pocket CFO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(children: [
                  Icon(Icons.shield, size: 10, color: AppColors.accentGreen),
                  SizedBox(width: 3),
                  Text('Privacy Mode', style: TextStyle(fontSize: 10, color: AppColors.accentGreen)),
                ]),
              ],
            ),
          ],
        ),
        actions: [
          if (!modelService.isLLMLoaded)
            TextButton.icon(
              onPressed: () => modelService.downloadAndLoadLLM(),
              icon: const Icon(Icons.smart_toy, size: 16, color: AppColors.warning),
              label: const Text('Load AI', style: TextStyle(color: AppColors.warning, fontSize: 12)),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'demo') _loadDemoData();
              else if (v == 'income') _setIncome();
              else if (v == 'refresh') _loadData();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'demo', child: Row(children: [Icon(Icons.auto_awesome, size: 18), SizedBox(width: 8), Text('Load Demo Data')])),
              const PopupMenuItem(value: 'income', child: Row(children: [Icon(Icons.attach_money, size: 18), SizedBox(width: 8), Text('Set Income')])),
              const PopupMenuItem(value: 'refresh', child: Row(children: [Icon(Icons.refresh, size: 18), SizedBox(width: 8), Text('Refresh')])),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _financialState == null
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Health Score + Safe to Spend hero row
                        _buildHeroRow(),
                        const SizedBox(height: 16),

                        // Monthly summary row
                        _buildMonthlySummaryRow(),
                        const SizedBox(height: 16),

                        // Subscription alert chip
                        if (_financialState!.subscriptionTotal > 0) _buildSubscriptionChip(),
                        if (_financialState!.subscriptionTotal > 0) const SizedBox(height: 16),

                        // Quick actions
                        _buildQuickActions(),
                        const SizedBox(height: 20),

                        // Category breakdown
                        if (_financialState!.categorySpending.isNotEmpty) ...[
                          const Text('Spending Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 10),
                          CategoryChart(state: _financialState!),
                          const SizedBox(height: 20),
                        ],

                        // Recent transactions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            TextButton(onPressed: () {}, child: const Text('See all', style: TextStyle(color: AppColors.accentCyan, fontSize: 13))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildRecentTransactions(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseView()));
          if (result == true) _loadData();
        },
        backgroundColor: AppColors.accentCyan,
        foregroundColor: AppColors.primaryDark,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildHeroRow() {
    final state = _financialState!;
    final healthColor = state.healthScore >= 70 ? AppColors.accentGreen : state.healthScore >= 45 ? AppColors.warning : AppColors.error;

    return Row(
      children: [
        // Safe to spend card
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentCyan.withOpacity(0.85), AppColors.accentViolet.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SAFE TO SPEND', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text(
                  '₹${state.safeToSpend.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.daysRemainingInMonth} days left',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Health score card
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: healthColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(state.healthEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  '${state.healthScore.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: healthColor),
                ),
                const Text('Health', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummaryRow() {
    final state = _financialState!;
    return Row(
      children: [
        _miniCard('Income', '₹${(state.income / 1000).toStringAsFixed(0)}k', AppColors.accentGreen, Icons.arrow_downward),
        const SizedBox(width: 10),
        _miniCard('Spent', '₹${(state.totalSpent / 1000).toStringAsFixed(1)}k', AppColors.error, Icons.arrow_upward),
        const SizedBox(width: 10),
        _miniCard('Saved', '${state.savingsRate.toStringAsFixed(0)}%', AppColors.accentCyan, Icons.savings),
      ],
    );
  }

  Widget _miniCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionChip() {
    final total = _financialState!.subscriptionTotal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentViolet.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentViolet.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.repeat, color: AppColors.accentViolet, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '₹${total.toStringAsFixed(0)}/mo in subscriptions detected',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const Text('View →', style: TextStyle(color: AppColors.accentViolet, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    const actions = [
      {'icon': Icons.add_circle_outline, 'label': 'Add', 'color': AppColors.accentCyan},
      {'icon': Icons.repeat, 'label': 'Subs', 'color': AppColors.accentViolet},
      {'icon': Icons.pie_chart_outline, 'label': 'Budgets', 'color': Color(0xFFF59E0B)},
      {'icon': Icons.bar_chart, 'label': 'Insights', 'color': AppColors.accentGreen},
    ];

    return Row(
      children: actions.map((a) {
        return Expanded(
          child: GestureDetector(
            onTap: () async {
              if (a['label'] == 'Add') {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseView()));
                if (result == true) _loadData();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Icon(a['icon'] as IconData, color: a['color'] as Color, size: 22),
                  const SizedBox(height: 6),
                  Text(a['label'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentTransactions() {
    if (_recentTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('No transactions this month', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentTransactions.length,
        separatorBuilder: (_, __) => Divider(color: AppColors.textMuted.withOpacity(0.1), height: 1),
        itemBuilder: (_, i) {
          final t = _recentTransactions[i];
          final cat = CategoryInfo.getCategory(t.category);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: cat.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 18))),
            ),
            title: Text(t.merchant, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text(t.formattedDate, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            trailing: Text(
              t.type == models.TransactionType.expense ? '-${t.formattedAmount}' : '+${t.formattedAmount}',
              style: TextStyle(
                color: t.type == models.TransactionType.expense ? AppColors.error : AppColors.accentGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💸', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('No transactions yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Load demo data or add your first expense', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDemoData,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Load Demo Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDemoData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Load Demo Data'),
        content: const Text('Replace all data with a realistic demo dataset? This includes subscriptions, budgets and insights.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Load Demo')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      await DemoDataGenerator().generateDemoData();
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Demo data loaded!')));
    }
  }

  Future<void> _setIncome() async {
    final controller = TextEditingController(text: '35000');
    final income = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Monthly Income'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₹ ', labelText: 'Monthly Income'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (income != null && income > 0) {
      final now = DateTime.now();
      await _db.setMonthlyIncome(now.year, now.month, income);
      await _loadData();
    }
  }
}
