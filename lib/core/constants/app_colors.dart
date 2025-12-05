import 'package:flutter/material.dart';

/// BukTrack App Colors
class AppColors {
  AppColors._();

  // ========== Primary Colors ==========
  static const Color primary = Color(0xFFf97316);
  static const Color primaryLight = Color(0xFFfb923c);
  static const Color primaryDark = Color(0xFFea580c);
  static const Color primaryLighter = Color(0xFFffedd5);
  static const Color violet = Color(0xFF7A07CD);

  // ========== Background Colors ==========
  // Light mode
  static const Color backgroundLight = Color(0xFFf9fafb);
  static const Color surfaceLight = Color(0xFFffffff);
  static const Color cardLight = Color(0xFFffffff);

  // Dark mode
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1f2937);
  static const Color cardDark = Color(0xFF1f2937);

  // ========== Text Colors ==========
  // Light mode
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF4B5563);
  static const Color textTertiaryLight = Color(0xFF9ca3af);

  // Dark mode
  static const Color textPrimaryDark = Color(0xFFf9fafb);
  static const Color textSecondaryDark = Color(0xFF9ca3af);
  static const Color textTertiaryDark = Color(0xFF4B5563);

  // ========== Border Colors ==========
  static const Color borderLight = Color(0xFFe5e7eb);
  static const Color borderDark = Color(0xFF374151); // gray-700

  // ========== Semantic Colors ==========
  // Success (Green)
  static const Color success = Color(0xFF10b981); // emerald-500
  static const Color successLight = Color(0xFF34d399); // emerald-400
  static const Color successDark = Color(0xFF059669); // emerald-600
  static const Color successBg = Color(0xFFd1fae5); // emerald-100
  static const Color successBgDark = Color(0xFF064e3b); // emerald-900

  // Error (Red)
  static const Color error = Color(0xFFef4444); // red-500
  static const Color errorLight = Color(0xFFf87171); // red-400
  static const Color errorDark = Color(0xFFdc2626); // red-600
  static const Color errorBg = Color(0xFFfee2e2); // red-100
  static const Color errorBgDark = Color(0xFF7f1d1d); // red-900

  // Warning (Yellow)
  static const Color warning = Color(0xFFf59e0b); // amber-500
  static const Color warningLight = Color(0xFFfbbf24); // amber-400
  static const Color warningDark = Color(0xFFd97706); // amber-600
  static const Color warningBg = Color(0xFFfef3c7); // amber-100
  static const Color warningBgDark = Color(0xFF78350f); // amber-900

  // Info (Blue)
  static const Color info = Color(0xFF3b82f6); // blue-500
  static const Color infoLight = Color(0xFF60a5fa); // blue-400
  static const Color infoDark = Color(0xFF2563eb); // blue-600
  static const Color infoBg = Color(0xFFdbeafe); // blue-100
  static const Color infoBgDark = Color(0xFF1e3a8a); // blue-900

  // ========== Status Colors ==========
  static const Color statusActive = success;
  static const Color statusInactive = error;
  static const Color statusMaintenance = warning;
  static const Color statusStandby = Color(0xFF8b5cf6); // violet-500
  static const Color statusDelayed = error;

  // ========== Component Colors ==========
  static const Color hoverLight = Color(0xFFf3f4f6);
  static const Color hoverDark = Color(0xFF374151);

  static const Color shadowLight = Color(0x1a000000); // black with 10% opacity
  static const Color shadowDark = Color(0x00000000);

  static const Color overlay = Color(0x80000000);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [Color(0xFFad47ff), Color(0xFF9911fb)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Color> chartColors = [
    Color(0xFF3b82f6), // blue
    Color(0xFF10b981), // emerald
    Color(0xFFf59e0b), // amber
    Color(0xFF8b5cf6), // violet
    Color(0xFFef4444), // red
    Color(0xFF06b6d4), // cyan
    Color(0xFFec4899), // pink
  ];

  static Color getTextColor(bool isDark, {bool isPrimary = true}) {
    if (isDark) {
      return isPrimary ? textPrimaryDark : textSecondaryDark;
    }
    return isPrimary ? textPrimaryLight : textSecondaryLight;
  }

  static Color getBackgroundColor(bool isDark) {
    return isDark ? backgroundDark : backgroundLight;
  }

  static Color getSurfaceColor(bool isDark) {
    return isDark ? surfaceDark : surfaceLight;
  }

  static Color getBorderColor(bool isDark) {
    return isDark ? borderDark : borderLight;
  }

  static Color getHoverColor(bool isDark) {
    return isDark ? hoverDark : hoverLight;
  }
}
