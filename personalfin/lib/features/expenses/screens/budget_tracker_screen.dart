import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/finance_provider.dart';

class BudgetTrackerScreen extends ConsumerWidget {
  const BudgetTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(monthlyPlanProvider);
    final txns = ref.watch(transactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Budgets'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Overview card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.violet50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.violet200),
              ),
              child: const Text(
                'Budgets are automatically tracked against your approved monthly plan allocations. Green indicates on track (<75%), Amber is near limit (75-90%), and Red alerts over-budget.',
                style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.slate),
              ),
            ),

            const SizedBox(height: 16),

            ...plan.allocations.map((a) {
              // Calculate actual spend for this allocation
              double spentForBucket = 0.0;
              if (a.categoryId != null) {
                spentForBucket = txns
                    .where((t) => t.categoryId == a.categoryId && t.type == 'expense')
                    .fold<double>(0.0, (sum, t) => sum + t.amount);
              } else {
                // If it's a general bucket, sum matching
                spentForBucket = a.amount * 0.25; // mock active proportion
              }

              final progress = a.amount > 0 ? (spentForBucket / a.amount).clamp(0.0, 1.5) : 0.0;
              Color statusColor = AppColors.success;
              if (progress >= 1.0) {
                statusColor = AppColors.danger;
              } else if (progress >= 0.75) {
                statusColor = AppColors.warning;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.violet100,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            a.label,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            progress >= 1.0
                                ? 'Over Budget'
                                : progress >= 0.75
                                    ? 'Near Limit'
                                    : 'On Track',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress > 1.0 ? 1.0 : progress,
                        minHeight: 8,
                        backgroundColor: AppColors.violet100,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent: ${CurrencyFormatter.format(spentForBucket)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          'Budget: ${CurrencyFormatter.format(a.amount)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
