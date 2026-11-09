import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/models/app_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/finance_provider.dart';
import '../../../core/services/api_service.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  String _amountString = '0';
  final _titleController = TextEditingController();
  String _selectedCategoryId = 'dining';
  String _paymentMode = 'UPI (GPay)';
  final DateTime _txnDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _onKeypadTap(String val) {
    setState(() {
      if (val == 'C') {
        _amountString = '0';
      } else if (val == '⌫') {
        if (_amountString.length > 1) {
          _amountString = _amountString.substring(0, _amountString.length - 1);
        } else {
          _amountString = '0';
        }
      } else if (val == '.') {
        if (!_amountString.contains('.')) {
          _amountString += '.';
        }
      } else {
        if (_amountString == '0') {
          _amountString = val;
        } else if (_amountString.length < 8) {
          _amountString += val;
        }
      }
    });
  }

  Future<void> _onSaveExpense() async {
    final amount = double.tryParse(_amountString) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0')),
      );
      return;
    }

    final cat = CategoryItem.findById(_selectedCategoryId);
    final title = _titleController.text.trim().isEmpty ? cat.name : _titleController.text.trim();
    final accessToken = ref.read(authProvider).accessToken;

    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        final result = await ref.read(apiServiceProvider).createTransaction(
          accessToken: accessToken,
          payload: {
            'title': title,
            'amount': amount,
            'categoryId': _selectedCategoryId,
            'date': _txnDate.toIso8601String(),
            'paymentMode': _paymentMode,
            'type': 'expense',
            'merchant': cat.name,
          },
        );

        final data = result['transaction'] as Map<String, dynamic>? ?? {};
        final txn = TransactionModel(
          id: (data['id'] ?? 'txn_${DateTime.now().millisecondsSinceEpoch}').toString(),
          title: (data['title'] as String?) ?? title,
          amount: ((data['amount'] as num?) ?? amount).toDouble(),
          categoryId: (data['categoryId'] as String?) ?? _selectedCategoryId,
          date: DateTime.tryParse((data['date'] as String?) ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
          paymentMode: (data['paymentMode'] as String?) ?? _paymentMode,
          type: (data['type'] as String?) ?? 'expense',
          merchant: data['merchant'] as String?,
        );
        ref.read(transactionsProvider.notifier).addTransaction(txn);
      } else {
        final txn = TransactionModel(
          id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          amount: amount,
          categoryId: _selectedCategoryId,
          date: _txnDate,
          paymentMode: _paymentMode,
          type: 'expense',
        );
        ref.read(transactionsProvider.notifier).addTransaction(txn);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged ${CurrencyFormatter.format(amount)} to ${cat.name}')),
      );
      context.pop();
    } catch (error) {
      final fallbackTxn = TransactionModel(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        amount: amount,
        categoryId: _selectedCategoryId,
        date: _txnDate,
        paymentMode: _paymentMode,
        type: 'expense',
      );
      ref.read(transactionsProvider.notifier).addTransaction(fallbackTxn);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved locally: ${CurrencyFormatter.format(amount)} ($error)')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            tooltip: 'OCR Receipt Scanner',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt OCR scanner ready for camera input')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Amount Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  Text(
                    '₹ $_amountString',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                      color: AppColors.violet600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'What was this for? (e.g. Coffee, Fuel)',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),

            // Category Chips Selector (Horizontal scroll)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: CategoryItem.defaultCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = CategoryItem.defaultCategories[index];
                  final isSelected = _selectedCategoryId == cat.id;
                  return ChoiceChip(
                    avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                    label: Text(cat.name),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedCategoryId = cat.id),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Payment Mode Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['UPI (GPay)', 'Credit Card', 'Cash', 'NetBanking'].map((mode) {
                  final isSelected = _paymentMode == mode;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _paymentMode = mode),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.violet600 : (isDark ? AppColors.darkCard : AppColors.violet50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            mode,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.ink),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Spacer(),

            // Custom Numeric Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  _buildKeypadRow(['4', '5', '6']),
                  _buildKeypadRow(['7', '8', '9']),
                  _buildKeypadRow(['.', '0', '⌫']),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onSaveExpense,
                      child: const Text('Log Expense ✓', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: keys.map((key) {
        return Expanded(
          child: InkWell(
            onTap: () => _onKeypadTap(key),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Text(
                key,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
