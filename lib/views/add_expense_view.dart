import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';

class AddExpenseView extends StatefulWidget {
  const AddExpenseView({super.key});

  @override
  State<AddExpenseView> createState() => _AddExpenseViewState();
}

class _AddExpenseViewState extends State<AddExpenseView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _db = DatabaseHelper.instance;

  String _selectedCategory = 'food';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isRecurring = false;
  TransactionType _type = TransactionType.expense;

  final _categories = ['food', 'transport', 'shopping', 'bills', 'entertainment', 'health', 'education', 'other'];

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        merchant: _merchantController.text.trim().isEmpty ? _selectedCategory : _merchantController.text.trim(),
        category: _selectedCategory,
        description: _merchantController.text.trim(),
        date: _selectedDate,
        type: _type,
        isRecurring: _isRecurring,
        importedFrom: 'manual',
      );
      await _db.insertTransaction(transaction);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_type == TransactionType.expense ? 'Expense' : 'Income'} added!')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type toggle
              Container(
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [TransactionType.expense, TransactionType.income].map((t) {
                    final selected = _type == t;
                    final label = t == TransactionType.expense ? 'Expense' : 'Income';
                    final color = t == TransactionType.expense ? AppColors.error : AppColors.accentGreen;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected ? color.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(label, style: TextStyle(color: selected ? color : AppColors.textMuted, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Amount
              _label('Amount'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  hintText: '0',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter an amount';
                  if (double.tryParse(v.replaceAll(',', '')) == null) return 'Invalid number';
                  if (double.parse(v.replaceAll(',', '')) <= 0) return 'Amount must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Merchant
              _label('Merchant / Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _merchantController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. Starbucks, Netflix...',
                  prefixIcon: Icon(Icons.storefront_outlined, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 24),

              // Category
              _label('Category'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final info = CategoryInfo.getCategory(cat);
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? info.color.withOpacity(0.2) : AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? info.color : AppColors.textMuted.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(info.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(info.label.split(' ')[0], style: TextStyle(color: selected ? info.color : AppColors.textSecondary, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Date
              _label('Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 12),
                      Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recurring toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, color: AppColors.textMuted, size: 18),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Mark as recurring', style: TextStyle(color: AppColors.textPrimary, fontSize: 14))),
                    Switch(
                      value: _isRecurring,
                      onChanged: (v) => setState(() => _isRecurring = v),
                      activeColor: AppColors.accentCyan,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5));
  }
}
