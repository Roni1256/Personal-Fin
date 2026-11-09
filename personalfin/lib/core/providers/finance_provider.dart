import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';

// ── Profile & Health Score State ──
class ProfileState {
  final String name;
  final int age;
  final String cityTier;
  final String occupation;
  final String riskProfile; // Conservative, Moderate, Aggressive
  final double monthlyIncome;
  final double netWorth;
  final int healthScore;
  final double emergencyFundMonths;
  final double savingsRate;
  final double dtiRatio;
  final bool isOnboarded;

  const ProfileState({
    required this.name,
    required this.age,
    required this.cityTier,
    required this.occupation,
    required this.riskProfile,
    required this.monthlyIncome,
    required this.netWorth,
    required this.healthScore,
    required this.emergencyFundMonths,
    required this.savingsRate,
    required this.dtiRatio,
    this.isOnboarded = true,
  });

  ProfileState copyWith({
    String? name,
    int? age,
    String? cityTier,
    String? occupation,
    String? riskProfile,
    double? monthlyIncome,
    double? netWorth,
    int? healthScore,
    double? emergencyFundMonths,
    double? savingsRate,
    double? dtiRatio,
    bool? isOnboarded,
  }) {
    return ProfileState(
      name: name ?? this.name,
      age: age ?? this.age,
      cityTier: cityTier ?? this.cityTier,
      occupation: occupation ?? this.occupation,
      riskProfile: riskProfile ?? this.riskProfile,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      netWorth: netWorth ?? this.netWorth,
      healthScore: healthScore ?? this.healthScore,
      emergencyFundMonths: emergencyFundMonths ?? this.emergencyFundMonths,
      savingsRate: savingsRate ?? this.savingsRate,
      dtiRatio: dtiRatio ?? this.dtiRatio,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier()
      : super(
          const ProfileState(
            name: 'Roni',
            age: 28,
            cityTier: 'Tier 1 (Bengaluru)',
            occupation: 'Software Engineer',
            riskProfile: 'Moderate',
            monthlyIncome: 60000,
            netWorth: 482300,
            healthScore: 78,
            emergencyFundMonths: 2.8,
            savingsRate: 35.0,
            dtiRatio: 23.3,
            isOnboarded: true,
          ),
        );

  void updateProfile({
    String? name,
    int? age,
    String? cityTier,
    String? occupation,
    String? riskProfile,
    double? monthlyIncome,
  }) {
    state = state.copyWith(
      name: name,
      age: age,
      cityTier: cityTier,
      occupation: occupation,
      riskProfile: riskProfile,
      monthlyIncome: monthlyIncome,
    );
  }

  void applyProfile(Map<String, dynamic> payload) {
    final name = (payload['name'] as String?) ?? state.name;
    final monthlyIncome = ((payload['monthlyIncome'] as num?) ?? state.monthlyIncome).toDouble();
    final riskProfile = (payload['riskProfile'] as String?) ?? state.riskProfile;
    final occupation = (payload['occupation'] as String?) ?? state.occupation;
    final age = (payload['age'] as num?)?.toInt() ?? state.age;
    final cityTier = (payload['cityTier'] as String?) ?? state.cityTier;
    final healthScore = (payload['healthScore'] as num?)?.toInt() ?? state.healthScore;
    final netWorth = ((payload['netWorth'] as num?) ?? state.netWorth).toDouble();

    state = state.copyWith(
      name: name,
      age: age,
      cityTier: cityTier,
      occupation: occupation,
      riskProfile: riskProfile,
      monthlyIncome: monthlyIncome,
      healthScore: healthScore,
      netWorth: netWorth,
    );
  }

  void completeOnboarding({
    required String name,
    required int age,
    required String cityTier,
    required String occupation,
    required String riskProfile,
    required double monthlyIncome,
  }) {
    state = state.copyWith(
      name: name,
      age: age,
      cityTier: cityTier,
      occupation: occupation,
      riskProfile: riskProfile,
      monthlyIncome: monthlyIncome,
      healthScore: 82,
      isOnboarded: true,
    );
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});

// ── Monthly Plan State ──
class MonthlyPlanState {
  final String monthYm;
  final double totalIncome;
  final String templateName;
  final List<PlanAllocation> allocations;
  final bool isApproved;

  const MonthlyPlanState({
    required this.monthYm,
    required this.totalIncome,
    required this.templateName,
    required this.allocations,
    required this.isApproved,
  });

  MonthlyPlanState copyWith({
    String? monthYm,
    double? totalIncome,
    String? templateName,
    List<PlanAllocation>? allocations,
    bool? isApproved,
  }) {
    return MonthlyPlanState(
      monthYm: monthYm ?? this.monthYm,
      totalIncome: totalIncome ?? this.totalIncome,
      templateName: templateName ?? this.templateName,
      allocations: allocations ?? this.allocations,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

class MonthlyPlanNotifier extends StateNotifier<MonthlyPlanState> {
  MonthlyPlanNotifier()
      : super(
          const MonthlyPlanState(
            monthYm: '2026-10',
            totalIncome: 60000,
            templateName: 'Family Balanced',
            isApproved: true,
            allocations: [
              PlanAllocation(
                id: '1',
                bucket: 'Essentials',
                label: 'Essentials (Rent, Food, Bills)',
                amount: 22000,
                percentage: 36.7,
                reason: 'Covers fixed rent, groceries & essentials based on 3-month trailing avg.',
                color: Color(0xFF6366F1),
                categoryId: 'rent',
              ),
              PlanAllocation(
                id: '2',
                bucket: 'Debt Prepayment',
                label: 'Home Loan EMI',
                amount: 14000,
                percentage: 23.3,
                reason: 'Fixed monthly obligation due on the 5th.',
                color: Color(0xFFEF4444),
                categoryId: 'emi',
              ),
              PlanAllocation(
                id: '3',
                bucket: 'Savings & Safety',
                label: 'Emergency Fund Top-up',
                amount: 6000,
                percentage: 10.0,
                reason: 'You currently have 2.8 of 6 target months covered.',
                color: AppColors.violet600,
                categoryId: 'emergency',
              ),
              PlanAllocation(
                id: '4',
                bucket: 'Investments',
                label: 'SIP (Index + Debt + Gold)',
                amount: 5000,
                percentage: 8.3,
                reason: 'Split: Nifty 50 ₹3k, Debt ₹1.5k, SGB/Gold ₹500 aligned to Moderate risk.',
                color: Color(0xFF10B981),
                categoryId: 'investment',
              ),
              PlanAllocation(
                id: '5',
                bucket: 'Goals',
                label: 'Car Down Payment Goal',
                amount: 3000,
                percentage: 5.0,
                reason: 'Keeps your 2027 purchase milestone on schedule.',
                color: Color(0xFF0EA5E9),
                categoryId: 'travel',
              ),
              PlanAllocation(
                id: '6',
                bucket: 'Protection',
                label: 'Insurance Premiums (Term+Health)',
                amount: 2000,
                percentage: 3.3,
                reason: 'Monthly amortisation for annual renewal due in Dec.',
                color: Color(0xFF059669),
                categoryId: 'insurance',
              ),
              PlanAllocation(
                id: '7',
                bucket: 'Lifestyle',
                label: 'Dining, Outings & Shopping',
                amount: 6000,
                percentage: 10.0,
                reason: 'Discretionary buffer to enjoy your hard-earned salary guilt-free.',
                color: Color(0xFFEC4899),
                categoryId: 'dining',
              ),
              PlanAllocation(
                id: '8',
                bucket: 'Buffer / Misc',
                label: 'Contingency Buffer',
                amount: 2000,
                percentage: 3.3,
                reason: 'Unplanned seasonal or weekend expenses.',
                color: Color(0xFF8B5CF6),
              ),
            ],
          ),
        );

  void applyPlan(Map<String, dynamic> payload) {
    final rawAllocations = payload['allocations'] as List<dynamic>? ?? const [];
    final allocations = rawAllocations.map((item) {
      final value = item as Map<String, dynamic>;
      final amount = ((value['amount'] as num?) ?? (value['amountPaise'] as num? ?? 0) / 100).toDouble();
      final percentage = ((value['percentage'] as num?) ?? 0).toDouble();
      return PlanAllocation(
        id: value['id']?.toString() ?? UniqueKey().toString(),
        bucket: value['bucket']?.toString() ?? 'Misc',
        label: value['label']?.toString() ?? 'Allocation',
        amount: amount,
        percentage: percentage,
        reason: value['reason']?.toString() ?? 'Budget allocation',
        color: AppColors.violet600,
        categoryId: value['categoryId']?.toString(),
      );
    }).toList();

    state = MonthlyPlanState(
      monthYm: payload['monthYm']?.toString() ?? state.monthYm,
      totalIncome: ((payload['totalIncome'] as num?) ?? state.totalIncome).toDouble(),
      templateName: payload['templateName']?.toString() ?? state.templateName,
      allocations: allocations,
      isApproved: payload['isApproved'] as bool? ?? state.isApproved,
    );
  }

  void updateAllocationAmount(String id, double newAmount) {
    final oldAllocations = state.allocations;
    final index = oldAllocations.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final updated = List<PlanAllocation>.from(oldAllocations);
    final target = updated[index];
    final newPct = (newAmount / state.totalIncome) * 100;
    updated[index] = target.copyWith(amount: newAmount, percentage: newPct);

    state = state.copyWith(allocations: updated);
  }

  void approvePlan() {
    state = state.copyWith(isApproved: true);
  }

  void generateNewPlan(double income, String template) {
    // Generate allocation splits based on template
    final double essentials = income * 0.36;
    final double emi = 14000;
    final double emergency = income * 0.10;
    final double investments = income * 0.12;
    final double goals = income * 0.08;
    final double protection = 2000;
    final double lifestyle = income * 0.12;
    final double buffer = income - (essentials + emi + emergency + investments + goals + protection + lifestyle);

    final newAllocations = [
      PlanAllocation(
        id: '1',
        bucket: 'Essentials',
        label: 'Essentials (Rent, Food, Bills)',
        amount: essentials,
        percentage: (essentials / income) * 100,
        reason: 'Essential survival expenses calculated by Fin Engine.',
        color: const Color(0xFF6366F1),
        categoryId: 'rent',
      ),
      PlanAllocation(
        id: '2',
        bucket: 'Debt Prepayment',
        label: 'Loan EMI Obligations',
        amount: emi,
        percentage: (emi / income) * 100,
        reason: 'Fixed monthly liabilities.',
        color: const Color(0xFFEF4444),
        categoryId: 'emi',
      ),
      PlanAllocation(
        id: '3',
        bucket: 'Savings & Safety',
        label: 'Emergency Fund Top-up',
        amount: emergency,
        percentage: (emergency / income) * 100,
        reason: 'Priority buffer allocation.',
        color: AppColors.violet600,
        categoryId: 'emergency',
      ),
      PlanAllocation(
        id: '4',
        bucket: 'Investments',
        label: 'Wealth SIPs',
        amount: investments,
        percentage: (investments / income) * 100,
        reason: 'Compounding portfolio based on risk score.',
        color: const Color(0xFF10B981),
        categoryId: 'investment',
      ),
      PlanAllocation(
        id: '5',
        bucket: 'Goals',
        label: 'Target Goals Contribution',
        amount: goals,
        percentage: (goals / income) * 100,
        reason: 'Priority goal contributions.',
        color: const Color(0xFF0EA5E9),
        categoryId: 'travel',
      ),
      PlanAllocation(
        id: '6',
        bucket: 'Protection',
        label: 'Insurance Coverage',
        amount: protection,
        percentage: (protection / income) * 100,
        reason: 'Safety and term insurance cover reserve.',
        color: const Color(0xFF059669),
        categoryId: 'insurance',
      ),
      PlanAllocation(
        id: '7',
        bucket: 'Lifestyle',
        label: 'Dining & Leisure',
        amount: lifestyle,
        percentage: (lifestyle / income) * 100,
        reason: 'Flexible lifestyle spend.',
        color: const Color(0xFFEC4899),
        categoryId: 'dining',
      ),
      PlanAllocation(
        id: '8',
        bucket: 'Buffer / Misc',
        label: 'Buffer',
        amount: buffer > 0 ? buffer : 1000,
        percentage: (buffer / income) * 100,
        reason: 'Contingency safety cushion.',
        color: const Color(0xFF8B5CF6),
      ),
    ];

    state = MonthlyPlanState(
      monthYm: '2026-10',
      totalIncome: income,
      templateName: template,
      allocations: newAllocations,
      isApproved: false,
    );
  }
}

final monthlyPlanProvider = StateNotifierProvider<MonthlyPlanNotifier, MonthlyPlanState>((ref) {
  return MonthlyPlanNotifier();
});

// ── Transactions State ──
class TransactionsNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionsNotifier()
      : super([
          TransactionModel(
            id: 't1',
            title: 'Swiggy Gourmet Dinner',
            amount: 520,
            categoryId: 'dining',
            date: DateTime.now().subtract(const Duration(hours: 3)),
            paymentMode: 'UPI (GPay)',
            merchant: 'Swiggy',
          ),
          TransactionModel(
            id: 't2',
            title: 'Nature Basket Groceries',
            amount: 1450,
            categoryId: 'groceries',
            date: DateTime.now().subtract(const Duration(days: 1)),
            paymentMode: 'Credit Card',
            merchant: 'Natures Basket',
          ),
          TransactionModel(
            id: 't3',
            title: 'Shell Petrol Fill',
            amount: 800,
            categoryId: 'transport',
            date: DateTime.now().subtract(const Duration(days: 2)),
            paymentMode: 'UPI',
            merchant: 'Shell',
          ),
          TransactionModel(
            id: 't4',
            title: 'Netflix & Spotify Subs',
            amount: 899,
            categoryId: 'entertainment',
            date: DateTime.now().subtract(const Duration(days: 3)),
            paymentMode: 'Credit Card',
          ),
          TransactionModel(
            id: 't5',
            title: 'Home Loan EMI Auto-debit',
            amount: 14000,
            categoryId: 'emi',
            date: DateTime(DateTime.now().year, DateTime.now().month, 5),
            paymentMode: 'NetBanking Auto',
            merchant: 'HDFC Bank',
          ),
          TransactionModel(
            id: 't6',
            title: 'SIP Mutual Fund Index',
            amount: 5000,
            categoryId: 'investment',
            date: DateTime(DateTime.now().year, DateTime.now().month, 10),
            paymentMode: 'Auto-Debit',
            merchant: 'Zerodha Coin',
          ),
        ]);

  void addTransaction(TransactionModel txn) {
    state = [txn, ...state];
  }

  void deleteTransaction(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>((ref) {
  return TransactionsNotifier();
});

// ── Goals State ──
class GoalsNotifier extends StateNotifier<List<GoalModel>> {
  GoalsNotifier()
      : super([
          GoalModel(
            id: 'g1',
            name: 'Emergency Fund (6 Months)',
            goalType: 'Safety',
            targetAmount: 200000,
            currentSaved: 92000,
            targetDate: DateTime(2027, 4, 30),
            priority: 1,
            icon: Icons.shield_rounded,
          ),
          GoalModel(
            id: 'g2',
            name: 'EV Car Down Payment',
            goalType: 'Asset',
            targetAmount: 350000,
            currentSaved: 160000,
            targetDate: DateTime(2027, 10, 15),
            priority: 2,
            icon: Icons.electric_car_rounded,
          ),
          GoalModel(
            id: 'g3',
            name: 'Japan Autumn Trip',
            goalType: 'Lifestyle',
            targetAmount: 180000,
            currentSaved: 45000,
            targetDate: DateTime(2027, 11, 1),
            priority: 3,
            icon: Icons.flight_takeoff_rounded,
          ),
        ]);

  void addGoal(GoalModel goal) {
    state = [...state, goal];
  }

  void addContribution(String goalId, double amount) {
    state = [
      for (final g in state)
        if (g.id == goalId)
          GoalModel(
            id: g.id,
            name: g.name,
            goalType: g.goalType,
            targetAmount: g.targetAmount,
            currentSaved: g.currentSaved + amount,
            targetDate: g.targetDate,
            priority: g.priority,
            icon: g.icon,
          )
        else
          g
    ];
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, List<GoalModel>>((ref) {
  return GoalsNotifier();
});

// ── Calendar Events ──
final calendarEventsProvider = Provider<List<CalendarEventItem>>((ref) {
  final now = DateTime.now();
  return [
    CalendarEventItem(
      id: 'e1',
      title: 'Home Loan EMI Auto-debit',
      type: 'emi',
      amount: 14000,
      date: DateTime(now.year, now.month, 5),
      isDone: true,
    ),
    CalendarEventItem(
      id: 'e2',
      title: 'SIP Mutual Fund Index',
      type: 'sip',
      amount: 5000,
      date: DateTime(now.year, now.month, 10),
      isDone: false,
    ),
    CalendarEventItem(
      id: 'e3',
      title: 'Electricity & Gas Bill',
      type: 'bill',
      amount: 2400,
      date: DateTime(now.year, now.month, 15),
      isDone: false,
    ),
    CalendarEventItem(
      id: 'e4',
      title: 'Broadband Fiber Bill',
      type: 'bill',
      amount: 1199,
      date: DateTime(now.year, now.month, 18),
      isDone: false,
    ),
    CalendarEventItem(
      id: 'e5',
      title: 'Diwali Gifts & Shopping',
      type: 'one_off',
      amount: 6000,
      date: DateTime(now.year, now.month, 24),
      isDone: false,
    ),
  ];
});

// ── Computed Summary Providers ──
final totalSpentProvider = Provider<double>((ref) {
  final txns = ref.watch(transactionsProvider);
  return txns
      .where((t) => t.type == 'expense')
      .fold<double>(0.0, (sum, t) => sum + t.amount);
});

final safeToSpendTodayProvider = Provider<double>((ref) {
  final plan = ref.watch(monthlyPlanProvider);
  final spent = ref.watch(totalSpentProvider);
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysLeft = (daysInMonth - now.day + 1).clamp(1, 31);

  // Lifestyle + Buffer bucket allocations
  final discretionaryBudget = plan.allocations
      .where((a) => a.bucket == 'Lifestyle' || a.bucket == 'Buffer / Misc')
      .fold<double>(0.0, (sum, a) => sum + a.amount);

  final remainingDiscretionary = (discretionaryBudget - (spent * 0.3)).clamp(0.0, double.infinity);
  return (remainingDiscretionary / daysLeft);
});
