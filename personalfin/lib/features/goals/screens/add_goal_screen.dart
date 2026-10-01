import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/app_models.dart';
import '../../../core/providers/finance_provider.dart';

class AddGoalScreen extends ConsumerStatefulWidget {
  const AddGoalScreen({super.key});

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _savedController = TextEditingController(text: '0');
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  void _onSaveGoal() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    final saved = double.tryParse(_savedController.text) ?? 0;

    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter goal name and target amount')),
      );
      return;
    }

    final newGoal = GoalModel(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      goalType: 'Custom',
      targetAmount: amount,
      currentSaved: saved,
      targetDate: _targetDate,
      priority: 2,
      icon: Icons.flag_rounded,
    );

    ref.read(goalsProvider.notifier).addGoal(newGoal);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Goal "$name" created! Fin has integrated it into your plan.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Financial Goal'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Goal Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g. Wedding, House Down Payment'),
              ),
              const SizedBox(height: 16),
              const Text('Target Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixText: '₹ ', hintText: '5,00,000'),
              ),
              const SizedBox(height: 16),
              const Text('Already Saved So Far (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _savedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixText: '₹ ', hintText: '0'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onSaveGoal,
                  child: const Text('Save & Calculate SIP ✦', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
