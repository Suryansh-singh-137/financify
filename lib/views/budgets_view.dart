import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class BudgetsView extends StatefulWidget {
  const BudgetsView({super.key});

  @override
  State<BudgetsView> createState() => _BudgetsViewState();
}

class _BudgetsViewState extends State<BudgetsView> {
  final BudgetService _service = BudgetService();
  List<Budget> _budgets = [];
  double _safeToSpend = 0;
  bool _isLoading = true;
  final now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final budgets = await _service.getBudgetsForMonth(now.year, now.month);
    final safe = await _service.calculateSafeToSpend(now.year, now.month);
    setState(() {
      _budgets = budgets;
      _safeToSpend = safe;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Budgets'),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSafeToSpendCard(),
                    const SizedBox(height: 20),
                    const Text('Category Budgets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    if (_budgets.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _budgets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildBudgetCard(_budgets[i]),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBudgetDialog,
        backgroundColor: AppColors.accentCyan,
        foregroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
    );
  }

  Widget _buildSafeToSpendCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentCyan.withOpacity(0.8), AppColors.accentViolet.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text('SAFE TO SPEND', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_safeToSpend.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Available to spend this month', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final pct = budget.percentUsed;
    final color = pct >= 100
        ? AppColors.error
        : pct >= 90
            ? AppColors.warning
            : AppColors.accentGreen;

    final catInfo = CategoryInfo.getCategory(budget.category);

    return Dismissible(
      key: Key(budget.id),
      background: Container(
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await _service.deleteBudget(budget.id);
        await _load();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: catInfo.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(catInfo.emoji, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(catInfo.label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15)),
                      Text('₹${budget.spentCached.toStringAsFixed(0)} / ₹${budget.amount.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      budget.isOverBudget ? 'Over!' : '₹${budget.remaining.toStringAsFixed(0)} left',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20)),
      child: const Center(
        child: Column(children: [
          Text('🎯', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('No budgets yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Tap + to set spending limits per category', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
      ),
    );
  }

  Future<void> _showAddBudgetDialog() async {
    String selectedCategory = 'food';
    final amountController = TextEditingController();

    final categories = ['food', 'transport', 'shopping', 'bills', 'entertainment', 'health', 'education', 'other'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Budget', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              const Text('Category', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final info = CategoryInfo.getCategory(cat);
                  final selected = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accentCyan.withOpacity(0.2) : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppColors.accentCyan : Colors.transparent),
                      ),
                      child: Text('${info.emoji} ${info.label}', style: TextStyle(color: selected ? AppColors.accentCyan : AppColors.textSecondary, fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Monthly Budget Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '5000',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  fillColor: AppColors.surfaceElevated,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    await _service.createBudget(year: now.year, month: now.month, category: selectedCategory, amount: amount);
                    Navigator.pop(ctx);
                    await _load();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Budget', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
