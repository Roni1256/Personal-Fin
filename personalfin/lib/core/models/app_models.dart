import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final String bucket;
  final Color color;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.bucket,
    required this.color,
  });

  static const List<CategoryItem> defaultCategories = [
    CategoryItem(id: 'rent', name: 'Rent & Housing', icon: Icons.home_outlined, bucket: 'Essentials', color: Color(0xFF6366F1)),
    CategoryItem(id: 'groceries', name: 'Groceries & Food', icon: Icons.shopping_basket_outlined, bucket: 'Essentials', color: Color(0xFF10B981)),
    CategoryItem(id: 'utilities', name: 'Bills & Utilities', icon: Icons.bolt_outlined, bucket: 'Essentials', color: Color(0xFFF59E0B)),
    CategoryItem(id: 'transport', name: 'Transport & Fuel', icon: Icons.directions_car_outlined, bucket: 'Essentials', color: Color(0xFF3B82F6)),
    CategoryItem(id: 'dining', name: 'Dining Out', icon: Icons.restaurant_outlined, bucket: 'Lifestyle', color: Color(0xFFEC4899)),
    CategoryItem(id: 'shopping', name: 'Shopping & Style', icon: Icons.shopping_bag_outlined, bucket: 'Lifestyle', color: Color(0xFF8B5CF6)),
    CategoryItem(id: 'entertainment', name: 'Entertainment', icon: Icons.movie_outlined, bucket: 'Lifestyle', color: Color(0xFF06B6D4)),
    CategoryItem(id: 'health', name: 'Healthcare & Fitness', icon: Icons.favorite_outline, bucket: 'Essentials', color: Color(0xFFEF4444)),
    CategoryItem(id: 'emi', name: 'Loan EMI', icon: Icons.account_balance_outlined, bucket: 'Debt Prepayment', color: Color(0xFFDC2626)),
    CategoryItem(id: 'investment', name: 'SIP & Investments', icon: Icons.trending_up_rounded, bucket: 'Investments', color: Color(0xFF10B981)),
    CategoryItem(id: 'emergency', name: 'Emergency Fund', icon: Icons.shield_outlined, bucket: 'Savings & Safety', color: Color(0xFF7C3AED)),
    CategoryItem(id: 'education', name: 'Education & Courses', icon: Icons.school_outlined, bucket: 'Goals', color: Color(0xFF64748B)),
    CategoryItem(id: 'travel', name: 'Travel & Vacations', icon: Icons.flight_takeoff_outlined, bucket: 'Lifestyle', color: Color(0xFF0EA5E9)),
    CategoryItem(id: 'insurance', name: 'Insurance Premiums', icon: Icons.verified_user_outlined, bucket: 'Protection', color: Color(0xFF059669)),
  ];

  static CategoryItem findById(String id) {
    return defaultCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => const CategoryItem(
        id: 'other',
        name: 'Other',
        icon: Icons.category_outlined,
        bucket: 'Lifestyle',
        color: Color(0xFF94A3B8),
      ),
    );
  }
}

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String paymentMode; // UPI, Credit Card, NetBanking, Cash
  final String type; // expense, income, transfer
  final String? merchant;
  final String? note;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.paymentMode,
    this.type = 'expense',
    this.merchant,
    this.note,
  });

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? paymentMode,
    String? type,
    String? merchant,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      paymentMode: paymentMode ?? this.paymentMode,
      type: type ?? this.type,
      merchant: merchant ?? this.merchant,
      note: note ?? this.note,
    );
  }
}

class GoalModel {
  final String id;
  final String name;
  final String goalType;
  final double targetAmount;
  final double currentSaved;
  final DateTime targetDate;
  final int priority; // 1 (highest) to 5
  final IconData icon;

  const GoalModel({
    required this.id,
    required this.name,
    required this.goalType,
    required this.targetAmount,
    required this.currentSaved,
    required this.targetDate,
    this.priority = 1,
    this.icon = Icons.flag_rounded,
  });

  double get progress => (targetAmount > 0) ? (currentSaved / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining => (targetAmount - currentSaved).clamp(0.0, double.infinity);
  int get monthsLeft {
    final now = DateTime.now();
    final diffYears = targetDate.year - now.year;
    final diffMonths = targetDate.month - now.month;
    final total = diffYears * 12 + diffMonths;
    return total > 0 ? total : 1;
  }
  double get requiredMonthlySip => remaining / monthsLeft;
}

class PlanAllocation {
  final String id;
  final String bucket;
  final String label;
  final double amount;
  final double percentage;
  final String reason;
  final Color color;
  final String? categoryId;

  const PlanAllocation({
    required this.id,
    required this.bucket,
    required this.label,
    required this.amount,
    required this.percentage,
    required this.reason,
    required this.color,
    this.categoryId,
  });

  PlanAllocation copyWith({
    double? amount,
    double? percentage,
    String? reason,
  }) {
    return PlanAllocation(
      id: id,
      bucket: bucket,
      label: label,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      reason: reason ?? this.reason,
      color: color,
      categoryId: categoryId,
    );
  }
}

class CalendarEventItem {
  final String id;
  final String title;
  final String type; // emi, sip, bill, salary, one_off
  final double amount;
  final DateTime date;
  final bool isDone;

  const CalendarEventItem({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.date,
    this.isDone = false,
  });
}
