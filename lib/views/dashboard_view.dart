import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/finance_engine.dart';
import '../services/model_service.dart';
import '../models/financial_state.dart';
import '../models/transaction.dart' as models;
import '../database/database_helper.dart';
import '../utils/demo_data_generator.dart';
import 'add_expense_view.dart';
import 'ai_chat_view.dart';
import 'transactions_view.dart';
import '../widgets/health_score_card.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/category_chart.dart';
import '../widgets/recent_transactions_list.dart';

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
        _recentTransactions = transactions.take(10).toList().cast<models.Transaction>();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelService = Provider.of<ModelService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, size: 24),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pocket CFO', style: TextStyle(fontSize: 18)),
                Text(
                  'Your Private Financial Brain',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // LLM Model Status Indicator
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Row(
                children: [
                  Icon(
                    modelService.isLLMLoaded 
                        ? Icons.check_circle 
                        : Icons.cloud_off,
                    color: modelService.isLLMLoaded 
                        ? Colors.green 
                        : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    modelService.isLLMLoaded ? 'AI Ready' : 'Load AI',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'demo') {
                _loadDemoData();
              } else if (value == 'clear') {
                _clearData();
              } else if (value == 'income') {
                _setIncome();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'demo',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome),
                    SizedBox(width: 8),
                    Text('Load Demo Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'income',
                child: Row(
                  children: [
                    Icon(Icons.attach_money),
                    SizedBox(width: 8),
                    Text('Set Monthly Income'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: 8),
                    Text('Clear All Data'),
                  ],
                ),
              ),
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
                        // Show model loading card if not loaded
                        if (!modelService.isLLMLoaded)
                          _buildModelLoadingCard(modelService),
                        
                        // Health Score Card
                        HealthScoreCard(state: _financialState!),
                        const SizedBox(height: 16),
                        
                        // Monthly Summary
                        MonthlySummaryCard(state: _financialState!),
                        const SizedBox(height: 16),
                        
                        // Category Breakdown Chart
                        if (_financialState!.categorySpending.isNotEmpty)
                          CategoryChart(state: _financialState!),
                        const SizedBox(height: 16),
                        
                        // Quick Actions
                        _buildQuickActions(),
                        const SizedBox(height: 16),
                        
                        // Recent Transactions
                        _buildSectionHeader('Recent Transactions'),
                        const SizedBox(height: 8),
                        RecentTransactionsList(
                          transactions: _recentTransactions,
                          onRefresh: _loadData,
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddExpense(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TransactionsView(),
              ),
            ).then((_) => _loadData());
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AIChatView(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Ask CFO',
          ),
        ],
      ),
    );
  }

  Widget _buildModelLoadingCard(ModelService modelService) {
    return Card(
      color: Colors.orange.shade900.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'AI Model Not Loaded',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'To ask your AI CFO questions, you need to load the AI model first.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (modelService.isLLMDownloading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: modelService.llmDownloadProgress / 100,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Downloading: ${modelService.llmDownloadProgress.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              )
            else if (modelService.isLLMLoading)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Loading model...'),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () => modelService.downloadAndLoadLLM(),
                icon: const Icon(Icons.download),
                label: const Text('Load AI Model'),
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
          Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Add your first expense to get started'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddExpense(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Actions'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.chat_bubble,
                label: 'Ask CFO',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIChatView(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.list,
                label: 'All Transactions',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionsView(),
                    ),
                  ).then((_) => _loadData());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _navigateToAddExpense(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseView(),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _loadDemoData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Demo Data'),
        content: const Text(
          'This will clear all existing data and load demo transactions for presentation. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Load Demo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final generator = DemoDataGenerator();
      await generator.generateDemoData();
      _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo data loaded successfully!')),
        );
      }
    }
  }

  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all transactions. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.clearAllData();
      _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    }
  }

  Future<void> _setIncome() async {
    final controller = TextEditingController(text: '25000');
    
    final income = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Income'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefix: Text('₹ '),
            labelText: 'Monthly Income',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (income != null && income > 0) {
      final now = DateTime.now();
      await _db.setMonthlyIncome(now.year, now.month, income);
      _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Monthly income set to ₹${income.toStringAsFixed(0)}')),
        );
      }
    }
  }
}
