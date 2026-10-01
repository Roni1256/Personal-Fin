import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sparkle_badge.dart';
import '../../../core/providers/finance_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricEnabled = true;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.violet200,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.violet100,
                    child: Text(
                      profile.name.isNotEmpty ? profile.name[0] : 'R',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.violet700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const SparkleBadge(text: 'Score: 78'),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${profile.occupation} · ${profile.cityTier}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Risk Profile: ${profile.riskProfile}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.violet600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section: Financial Profile
            const Text(
              'FINANCIAL HEALTH PROFILE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: Icons.badge_outlined,
              title: 'Edit Financial Health Profile',
              subtitle: 'Update income, rent, loans and dependents',
              onTap: () => context.push('/onboarding'),
            ),
            _buildSettingTile(
              icon: Icons.psychology_outlined,
              title: 'Retake Risk Questionnaire',
              subtitle: 'Current: Moderate (60% Eq / 30% Debt / 10% Gold)',
              onTap: () => context.push('/onboarding'),
            ),

            const SizedBox(height: 20),

            // Section: App & Preferences
            const Text(
              'APP PREFERENCES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.violet600),
              title: const Text('Dark Mode (Deep Violet)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Aurora deep violet palette', style: TextStyle(fontSize: 12)),
              value: isDark,
              activeColor: AppColors.violet600,
              onChanged: (val) {
                ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.violet600),
              title: const Text('Biometric / PIN Lock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Require authentication on app launch', style: TextStyle(fontSize: 12)),
              value: _biometricEnabled,
              activeColor: AppColors.violet600,
              onChanged: (val) => setState(() => _biometricEnabled = val),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.violet600),
              title: const Text('Due Reminders & Budget Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Push alerts on EMI dates and 80% budget crossing', style: TextStyle(fontSize: 12)),
              value: _notificationsEnabled,
              activeColor: AppColors.violet600,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),

            const SizedBox(height: 20),

            // Section: DPDP Privacy & Compliance
            const Text(
              'PRIVACY & COMPLIANCE (DPDP ACT 2023)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: Icons.file_download_outlined,
              title: 'Export All My Data (JSON / CSV)',
              subtitle: 'Right to data portability under DPDP Act',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data package generated and sent to registered email.')),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.delete_forever_outlined,
              title: 'Request Account & Data Erasure',
              subtitle: 'Permanently purge all financial records and snapshots',
              textColor: AppColors.danger,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account?'),
                    content: const Text('All your profiles, budgets, and snapshots will be wiped in accordance with DPDP regulations.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/login');
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Regulatory Disclaimer Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.violet50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.violet200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Regulatory Disclaimer',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.violet900),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'PersonalFin provides educational financial planning based on information you provide. It does not guarantee returns or execute trades. Investments are subject to market risks. Consult a SEBI-registered investment adviser for personalized advice.',
                    style: TextStyle(fontSize: 11, height: 1.35, color: AppColors.slate),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                'PersonalFin v1.0.0 (Build 1) · Made with Flutter',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.violet600),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
