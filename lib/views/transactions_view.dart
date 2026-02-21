import 'package:flutter/material.dart';
import '../models/transaction.dart' as models;
import '../models/category.dart';
import '../database/database_helper.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  final _db = DatabaseHelper.instance;
  List<models.Transaction> _transactions = [];
  bool _isLoading = true;
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final List<models.Transaction> transactions;
      
      if (_filterCategory != null) {
        transactions = (await _db.getTransactionsByCategory(_filterCategory!)).cast<models.Transaction>();
      } else {
        transactions = (await _db.getAllTransactions()).cast<models.Transaction>();
      }

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('All Categories'),
                selected: _filterCategory == null,
                onTap: () {
                  setState(() => _filterCategory = null);
                  Navigator.pop(context);
                  _loadTransactions();
                },
              ),
              const Divider(),
              ...DefaultCategories.all.map((category) {
                return ListTile(
                  leading: Icon(category.icon, color: category.color),
                  title: Text(category.name),
                  selected: _filterCategory == category.id,
                  onTap: () {
                    setState(() => _filterCategory = category.id);
                    Navigator.pop(context);
                    _loadTransactions();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          IconButton(
            icon: Icon(
              _filterCategory != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: Column(
                    children: [
                      if (_filterCategory != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: Colors.blue.shade900.withOpacity(0.3),
                          child: Row(
                            children: [
                              const Text('Filtered by: '),
                              Chip(
                                label: Text(
                                  DefaultCategories.getById(_filterCategory!)
                                      .name,
                                ),
                                onDeleted: () {
                                  setState(() => _filterCategory = null);
                                  _loadTransactions();
                                },
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            return _buildTransactionTile(transaction);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _filterCategory != null
                ? 'No transactions in this category'
                : 'No transactions yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _filterCategory != null
                ? 'Try a different filter'
                : 'Add your first expense to get started',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(models.Transaction transaction) {
    final category = DefaultCategories.getById(transaction.category);

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text(
              'Are you sure you want to delete this transaction?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await _db.deleteTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: category.color.withOpacity(0.2),
            child: Icon(category.icon, color: category.color),
          ),
          title: Text(
            transaction.description.isEmpty
                ? category.name
                : transaction.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category.name),
              Text(
                transaction.formattedDate,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          trailing: Text(
            transaction.formattedAmount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: transaction.type == models.TransactionType.expense
                  ? Colors.red
                  : Colors.green,
            ),
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}
