import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import 'add_expense_view.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Transaction> _all = [];
  List<Transaction> _filtered = [];
  String _searchQuery = '';
  String? _categoryFilter;
  bool _isLoading = true;

  final _categories = ['all', 'food', 'transport', 'shopping', 'bills', 'entertainment', 'health'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await _db.getAllTransactions();
    setState(() {
      _all = all;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    _filtered = _all.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _categoryFilter == null || _categoryFilter == 'all' || t.category == _categoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseView()));
              if (result == true) _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() {
                _searchQuery = v;
                _applyFilters();
              }),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                fillColor: AppColors.surfaceCard,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Category filter chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = (cat == 'all' && _categoryFilter == null) || cat == _categoryFilter;
                final info = cat == 'all' ? null : CategoryInfo.getCategory(cat);
                return GestureDetector(
                  onTap: () => setState(() {
                    _categoryFilter = cat == 'all' ? null : cat;
                    _applyFilters();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accentCyan.withOpacity(0.2) : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.accentCyan : Colors.transparent),
                    ),
                    child: Text(
                      cat == 'all' ? 'All' : '${info!.emoji} ${info.label.split(' ')[0]}',
                      style: TextStyle(color: selected ? AppColors.accentCyan : AppColors.textSecondary, fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Transaction list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📭', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('No transactions found', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => Divider(color: AppColors.textMuted.withOpacity(0.1), height: 1),
                          itemBuilder: (_, i) => _buildTile(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(Transaction t) {
    final cat = CategoryInfo.getCategory(t.category);
    return Dismissible(
      key: Key(t.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text('Delete "${t.merchant}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
      onDismissed: (_) async {
        await _db.deleteTransaction(t.id);
        await _load();
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: cat.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 20))),
        ),
        title: Text(t.merchant, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text('${t.formattedDate} · ${cat.label}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              t.type == TransactionType.expense ? '-${t.formattedAmount}' : '+${t.formattedAmount}',
              style: TextStyle(
                color: t.type == TransactionType.expense ? AppColors.error : AppColors.accentGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (t.isRecurring)
              const Text('🔄', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
