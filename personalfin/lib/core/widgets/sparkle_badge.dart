import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SparkleBadge extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const SparkleBadge({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.violet600.withValues(alpha: 0.12),
              AppColors.gradientMid.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: AppColors.violet400.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 13,
              color: AppColors.violet600,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.violet700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
