import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/finance_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final plan = ref.watch(monthlyPlanProvider);
    final totalSpent = ref.watch(totalSpentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Insights ✦'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export CSV / PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting DPDP-compliant Financial Statement PDF...')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ── Monthly Report Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.violet800,
                    AppColors.violet600,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${DateFormatter.monthYear(DateTime.now()).toUpperCase()} REPORT CARD',
                        style: const TextStyle(
                          color: AppColors.lavenderGlow,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Grade A (84% Adherence)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildReportStat('Savings Rate', '${profile.savingsRate.toStringAsFixed(1)}%', AppColors.lavenderGlow),
                      _buildReportStat('Total Spent', CurrencyFormatter.format(totalSpent), Colors.white),
                      _buildReportStat('Health Score', '${profile.healthScore}/100', AppColors.successLight),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Net Worth Trajectory (6-Month Trend) ──
            Container(
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
                  const Text(
                    'Net Worth Growth (Past 6 Months)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compounding at +3.2% month-over-month',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  // Visual bar chart representing past 6 months
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTrendBar('May', 0.55, '₹3.9L'),
                      _buildTrendBar('Jun', 0.62, '₹4.1L'),
                      _buildTrendBar('Jul', 0.70, '₹4.3L'),
                      _buildTrendBar('Aug', 0.80, '₹4.5L'),
                      _buildTrendBar('Sep', 0.90, '₹4.7L'),
                      _buildTrendBar('Oct', 1.00, '₹4.8L', isCurrent: true),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Category Allocation vs Actual Breakdown ──
            Container(
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
                  const Text(
                    'Spend Breakdown by Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  ...plan.allocations.map((a) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(a.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(CurrencyFormatter.format(a.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (a.amount / plan.totalIncome),
                              minHeight: 6,
                              backgroundColor: AppColors.violet100,
                              valueColor: AlwaysStoppedAnimation<Color>(a.color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.lavenderGlow)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTrendBar(String label, double heightFraction, String val, {bool isCurrent = false}) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 10, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
        const SizedBox(height: 6),
        Container(
          width: 24,
          height: 90 * heightFraction,
          decoration: BoxDecoration(
            color: isCurrent ? AppColors.violet600 : AppColors.violet300,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate)),
      ],
    );
  }
}
