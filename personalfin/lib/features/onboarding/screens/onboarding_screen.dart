import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/fin_orb.dart';
import '../../../core/widgets/sparkle_badge.dart';
import '../../../core/providers/finance_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4; // Compact 4-step wizard combining the core sections

  // Form states
  final _nameController = TextEditingController(text: 'Roni');
  final _ageController = TextEditingController(text: '28');
  String _cityTier = 'Tier 1 (Metro)';
  String _occupation = 'Salaried (Tech)';
  final _incomeController = TextEditingController(text: '60000');
  final _rentController = TextEditingController(text: '15000');
  final _emiController = TextEditingController(text: '14000');
  final _savingsController = TextEditingController(text: '92000');
  String _riskProfile = 'Moderate';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _incomeController.dispose();
    _rentController.dispose();
    _emiController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Complete onboarding
      final income = double.tryParse(_incomeController.text) ?? 60000;
      ref.read(profileProvider.notifier).completeOnboarding(
            name: _nameController.text.trim().isEmpty ? 'Roni' : _nameController.text.trim(),
            age: int.tryParse(_ageController.text) ?? 28,
            cityTier: _cityTier,
            occupation: _occupation,
            riskProfile: _riskProfile,
            monthlyIncome: income,
          );
      context.go('/health-score');
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _prevStep,
        ),
        title: Text('Step ${_currentStep + 1} of $_totalSteps'),
        actions: [
          TextButton(
            onPressed: () => context.go('/health-score'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: AppColors.violet100,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.violet600),
                  minHeight: 6,
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == _totalSteps - 1
                            ? 'Calculate Health Score ✦'
                            : 'Continue',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Personal();
      case 1:
        return _buildStep2IncomeExpenses();
      case 2:
        return _buildStep3AssetsLiabilities();
      case 3:
        return _buildStep4RiskGoals();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1Personal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SparkleBadge(text: 'Section 1: You & Demographics'),
        const SizedBox(height: 12),
        const Text(
          'Tell Fin about yourself',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'This helps us benchmark your savings and cost of living accurately.',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        const Text('Your Name', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'e.g. Arun')),
        const SizedBox(height: 16),
        const Text('Age', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g. 28')),
        const SizedBox(height: 16),
        const Text('City of Residence', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _cityTier,
          decoration: const InputDecoration(),
          items: const [
            DropdownMenuItem(value: 'Tier 1 (Metro)', child: Text('Tier 1 Metro (Mumbai, BLR, Delhi, HYD)')),
            DropdownMenuItem(value: 'Tier 2 City', child: Text('Tier 2 (Pune, Jaipur, Kochi, etc.)')),
            DropdownMenuItem(value: 'Tier 3 / Towns', child: Text('Tier 3 / Towns')),
          ],
          onChanged: (v) => setState(() => _cityTier = v!),
        ),
        const SizedBox(height: 16),
        const Text('Employment Type', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _occupation,
          decoration: const InputDecoration(),
          items: const [
            DropdownMenuItem(value: 'Salaried (Tech)', child: Text('Salaried Full-time')),
            DropdownMenuItem(value: 'Freelancer / Consultant', child: Text('Freelancer / Independent')),
            DropdownMenuItem(value: 'Business Owner', child: Text('Business Owner')),
          ],
          onChanged: (v) => setState(() => _occupation = v!),
        ),
      ],
    );
  }

  Widget _buildStep2IncomeExpenses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SparkleBadge(text: 'Section 2: Cash Flow Engine'),
        const SizedBox(height: 12),
        const Text(
          'Monthly Cash In & Out',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Your monthly income becomes the baseline for automated budget allocation.',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        const Text('Take-Home Monthly Salary (₹)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _incomeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₹ ', hintText: '60,000'),
        ),
        const SizedBox(height: 16),
        const Text('Rent & Maintenance (₹)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _rentController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₹ ', hintText: '15,000'),
        ),
        const SizedBox(height: 16),
        const Text('Existing Loan EMIs (₹)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _emiController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₹ ', hintText: '14,000'),
        ),
      ],
    );
  }

  Widget _buildStep3AssetsLiabilities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SparkleBadge(text: 'Section 3: Net Worth Snapshot'),
        const SizedBox(height: 12),
        const Text(
          'Savings & Assets',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Calculates emergency fund runway and debt-to-income safety metrics.',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        const Text('Liquid Savings (Bank Balance + FDs) (₹)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _savingsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₹ ', hintText: '92,000'),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.violet50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.violet200),
          ),
          child: const Row(
            children: [
              FinOrb(size: 38),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Fin Tip: 6 months of essentials is the recommended emergency reserve for your profile.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.violet900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4RiskGoals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SparkleBadge(text: 'Section 4: Investment Strategy'),
        const SizedBox(height: 12),
        const Text(
          'Risk Appetite & Horizon',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Fin uses this SEBI-informed framework to recommend equity vs debt ratios.',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        ...['Conservative', 'Moderate', 'Aggressive'].map((profile) {
          final isSelected = _riskProfile == profile;
          return GestureDetector(
            onTap: () => setState(() => _riskProfile = profile),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.violet900 : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile == 'Conservative'
                              ? '80% Debt/FD · 20% Index SIP (Capital preservation)'
                              : profile == 'Moderate'
                                  ? '60% Equity · 30% Debt · 10% Gold (Balanced growth)'
                                  : '80% Equity · 20% Debt (Aggressive compounding)',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
