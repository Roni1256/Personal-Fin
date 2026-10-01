import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sparkle_badge.dart';
import '../../../core/providers/finance_provider.dart';

class HealthScoreScreen extends ConsumerWidget {
  const HealthScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Center(child: SparkleBadge(text: 'Health Check Complete ✦')),
              const SizedBox(height: 20),
              const Text(
                'Your Financial Health Score',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on SEBI & RBI personal finance wellness benchmarks',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 36),

              // Score Circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: CircularProgressIndicator(
                      value: profile.healthScore / 100,
                      strokeWidth: 14,
                      backgroundColor: AppColors.violet100,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.violet600),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${profile.healthScore}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppColors.violet900,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'out of 100',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'Good Financial Standing · Grade A',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Gaps & Strengths breakdown cards
              _buildMetricCard(
                context: context,
                icon: Icons.shield_outlined,
                iconColor: AppColors.warning,
                title: 'Emergency Runway: ${profile.emergencyFundMonths} Months',
                subtitle: 'Gap: Target is 6 months (₹1,32,000 needed). Fin will prioritize this in your plan.',
                isStrength: false,
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                context: context,
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.success,
                title: 'Debt-to-Income (DTI): ${profile.dtiRatio}%',
                subtitle: 'Excellent! Stays safely below the 35% RBI risk ceiling.',
                isStrength: true,
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                context: context,
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.violet600,
                title: 'Savings Discipline: ${profile.savingsRate.toInt()}%',
                subtitle: 'Higher than 82% of peers in your city tier.',
                isStrength: true,
              ),

              const SizedBox(height: 36),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Go to Dashboard ✦', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isStrength,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStrength ? AppColors.violet100 : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
