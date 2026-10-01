import 'package:flutter/material.dart';

/// Aurora Violet Design System — Color Tokens
class AppColors {
  AppColors._();

  // ── Primary Violet Scale ──
  static const Color violet900 = Color(0xFF2E1065);
  static const Color violet800 = Color(0xFF3B0764);
  static const Color violet700 = Color(0xFF5B21B6);
  static const Color violet600 = Color(0xFF7C3AED); // Primary
  static const Color violet500 = Color(0xFF8B5CF6);
  static const Color violet400 = Color(0xFFA78BFA);
  static const Color violet300 = Color(0xFFC4B5FD);
  static const Color violet200 = Color(0xFFDDD6FE);
  static const Color violet100 = Color(0xFFEDE9FE);
  static const Color violet50  = Color(0xFFF5F3FF);

  // ── Neutrals ──
  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1E1B2E);
  static const Color slate = Color(0xFF6B6685);
  static const Color slateLight = Color(0xFF9490A8);

  // ── Semantic ──
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);

  // ── AI Gradient ──
  static const Color gradientStart = Color(0xFF7C3AED);
  static const Color gradientMid = Color(0xFFA855F7);
  static const Color gradientEnd = Color(0xFFC084FC);
  static const Color lavenderGlow = Color(0xFFE9D5FF);

  // ── Dark Mode ──
  static const Color darkBg = Color(0xFF0F0A1F);
  static const Color darkSurface = Color(0xFF1A1333);
  static const Color darkCard = Color(0xFF241B45);
  static const Color darkText = Color(0xFFF3EEFF);
  static const Color darkTextSecondary = Color(0xFFB8B0D0);
  static const Color darkBorder = Color(0xFF3D2E6B);

  // ── AI Gradient (LinearGradient) ──
  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet700, violet600, violet500],
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B0764), violet700, Color(0xFF6D28D9)],
  );

  // ── Heatmap Levels (calendar spend intensity) ──
  static const List<Color> heatmapLevels = [
    violet50,       // Level 0 — no spend
    Color(0xFFDDD6FE), // Level 1
    Color(0xFFA78BFA), // Level 2
    Color(0xFF7C3AED), // Level 3
    Color(0xFF4C1D95), // Level 4 — heavy spend
  ];

  // ── Shadow ──
  static BoxShadow violetShadow({double opacity = 0.12, double blur = 16}) {
    return BoxShadow(
      color: violet600.withValues(alpha: opacity),
      blurRadius: blur,
      offset: const Offset(0, 4),
    );
  }
}

