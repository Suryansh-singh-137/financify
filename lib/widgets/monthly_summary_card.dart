import 'package:flutter/material.dart';
import '../models/financial_state.dart';

class MonthlySummaryCard extends StatelessWidget {
  final MonthlyFinancialState state;

  const MonthlySummaryCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Month',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRow(
              'Income',
              '₹${state.income.toStringAsFixed(0)}',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildRow(
              'Spent',
              '₹${state.totalSpent.toStringAsFixed(0)} (${state.spentPercentage.toStringAsFixed(0)}%)',
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildRow(
              'Remaining',
              '₹${state.remainingBalance.toStringAsFixed(0)}',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildRow(
              'Savings Rate',
              '${state.savingsRate.toStringAsFixed(1)}%',
              state.savingsRate >= 15 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildRow(
              'Days Remaining',
              '${state.daysRemainingInMonth} days',
              Colors.grey,
            ),
            const SizedBox(height: 12),
            _buildRow(
              'Daily Burn Rate',
              '₹${state.dailyBurnRate.toStringAsFixed(0)}/day',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
