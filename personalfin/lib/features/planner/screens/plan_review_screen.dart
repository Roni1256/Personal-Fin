import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/finance_provider.dart';

class PlanReviewScreen extends ConsumerWidget {
  const PlanReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(monthlyPlanProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allocatedTotal = plan.allocations.fold<double>(0.0, (sum, a) => sum + a.amount);
    final remainingUnallocated = plan.totalIncome - allocatedTotal;

    return Scaffold(
      appBar: AppBar(
        title: Text('${DateFormatter.monthYear(DateTime.now())} Plan'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: plan.isApproved ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              plan.isApproved ? 'Approved ✓' : 'Draft Proposal',
              style: TextStyle(
                color: plan.isApproved ? const Color(0xFF065F46) : const Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Income & Allocation Summary Header
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.violet200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Planned Income',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(plan.totalIncome),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Strategy',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            plan.templateName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.violet600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Multi-segment progress bar representing buckets
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: plan.allocations.map((a) {
                          return Expanded(
                            flex: (a.amount).toInt(),
                            child: Container(
                              color: a.color,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Allocated: ${CurrencyFormatter.format(allocatedTotal)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        remainingUnallocated.abs() < 1
                            ? '100% Assigned ✓'
                            : 'Unassigned: ${CurrencyFormatter.format(remainingUnallocated)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: remainingUnallocated.abs() < 1 ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Allocations List with Interactive Sliders
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: plan.allocations.length,
                itemBuilder: (context, index) {
                  final a = plan.allocations[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.violet100,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: a.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                a.label,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(a.amount),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.violet900,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${CurrencyFormatter.formatPercent(a.percentage)})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: a.color,
                            thumbColor: a.color,
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: a.amount.clamp(0, plan.totalIncome),
                            min: 0,
                            max: plan.totalIncome,
                            divisions: 60,
                            onChanged: (newVal) {
                              ref.read(monthlyPlanProvider.notifier).updateAllocationAmount(a.id, newVal);
                            },
                          ),
                        ),
                        // Fin AI Rationale
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.violet50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✦ ', style: TextStyle(color: AppColors.violet600, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  a.reason,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.ink,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Approval Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Tweak Strategy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(monthlyPlanProvider.notifier).approvePlan();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Plan approved! Budget locked for October 2026.')),
                        );
                        context.go('/calendar');
                      },
                      child: const Text('Approve & Lock Budget ✓', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
