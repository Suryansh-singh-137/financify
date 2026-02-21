import 'package:flutter/material.dart';
import '../models/financial_state.dart';

class HealthScoreCard extends StatelessWidget {
  final MonthlyFinancialState state;

  const HealthScoreCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: _getGradientColors(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Financial Health Score',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  state.healthEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  state.healthScore.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    '/100',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              state.healthStatus,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: state.healthScore / 100,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              '₹${state.remainingBalance.toStringAsFixed(0)} remaining this month',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    if (state.healthScore >= 80) {
      return [const Color(0xFF10B981), const Color(0xFF059669)];
    } else if (state.healthScore >= 60) {
      return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
    } else if (state.healthScore >= 40) {
      return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
    } else {
      return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
    }
  }
}
