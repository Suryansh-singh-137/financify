import 'package:flutter/material.dart';
import '../models/transaction.dart' as models;
import '../models/category.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<models.Transaction> transactions;
  final VoidCallback onRefresh;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  'No transactions yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final category = CategoryInfo.getCategory(transaction.category);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: category.color.withOpacity(0.2),
              child: Text(category.emoji),
            ),
            title: Text(
              transaction.description.isEmpty
                  ? category.label
                  : transaction.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(transaction.formattedDate),
            trailing: Text(
              transaction.formattedAmount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transaction.type == models.TransactionType.expense
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          );
        },
      ),
    );
  }
}
