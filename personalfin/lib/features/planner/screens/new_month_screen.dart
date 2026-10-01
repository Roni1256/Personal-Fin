import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sparkle_badge.dart';
import '../../../core/widgets/fin_orb.dart';
import '../../../core/providers/finance_provider.dart';

class NewMonthScreen extends ConsumerStatefulWidget {
  const NewMonthScreen({super.key});

  @override
  ConsumerState<NewMonthScreen> createState() => _NewMonthScreenState();
}

class _NewMonthScreenState extends ConsumerState<NewMonthScreen> {
  final _incomeController = TextEditingController(text: '60000');
  final _extraIncomeController = TextEditingController(text: '0');
  String _selectedTemplate = 'Family Balanced';

  static const List<Map<String, String>> _templates = [
    {
      'name': 'Family Balanced',
      'split': 'Needs 55% · Wants 15% · Goals 20% · Safety 10%',
      'bestFor': 'Families balancing home loan, child & insurance',
    },
    {
      'name': '50/30/20 Classic',
      'split': 'Needs 50% · Wants 30% · Save & Invest 20%',
      'bestFor': 'Beginners starting financial discipline',
    },
    {
      'name': 'Aggressive Saver',
      'split': 'Needs 45% · Wants 15% · Save & Invest 40%',
      'bestFor': 'High-savings FIRE enthusiasts',
    },
    {
      'name': 'Debt Crusher',
      'split': 'Needs 50% · Wants 10% · Debt 30% · Invest 10%',
      'bestFor': 'Rapid debt prepayment',
    },
    {
      'name': 'Freelancer Smoothing',
      'split': 'Base Needs + Tax Buffer + Variable Sinking Fund',
      'bestFor': 'Irregular monthly earnings',
    },
  ];

  @override
  void dispose() {
    _incomeController.dispose();
    _extraIncomeController.dispose();
    super.dispose();
  }

  void _onGeneratePlan() {
    final base = double.tryParse(_incomeController.text) ?? 60000;
    final extra = double.tryParse(_extraIncomeController.text) ?? 0;
    final total = base + extra;

    ref.read(monthlyPlanProvider.notifier).generateNewPlan(total, _selectedTemplate);
    context.push('/planner/review');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Planner ✦'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/planner/review'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.violet50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.violet200),
                ),
                child: Row(
                  children: [
                    const FinOrb(size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Plan for October 2026',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enter your expected income to generate a mathematically optimized budget allocation.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Expected Income Input
              const Text(
                'Expected Regular Salary / Income (₹)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _incomeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  hintText: '60,000',
                ),
              ),

              const SizedBox(height: 16),

              // Bonus / Extra Income
              const Text(
                'Bonus / Side Income Expected (₹)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _extraIncomeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  hintText: '0',
                ),
              ),

              const SizedBox(height: 24),

              // Plan Template Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Budget Strategy Template',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SparkleBadge(text: 'Fin Recommended'),
                ],
              ),
              const SizedBox(height: 12),

              ..._templates.map((tpl) {
                final isSelected = _selectedTemplate == tpl['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedTemplate = tpl['name']!),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.violet100 : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.violet600 : AppColors.violet200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.violet600 : AppColors.slate,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tpl['name']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isSelected ? AppColors.violet900 : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tpl['split']!,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Best for: ${tpl['bestFor']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onGeneratePlan,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Generate Plan with Fin ✦',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
