import 'package:flutter/material.dart';

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color primary;
  final Color accent;
  final Color accentLight;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textLight;
  final Color textOnDark;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color error;
  final Color errorLight;
  final Color info;
  final Color infoLight;
  final Color border;
  final Color divider;
  final LinearGradient primaryGradient;
  final LinearGradient accentGradient;
  final LinearGradient heroGradient;

  const AppThemeColors({
    required this.primary,
    required this.accent,
    required this.accentLight,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textLight,
    required this.textOnDark,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.error,
    required this.errorLight,
    required this.info,
    required this.infoLight,
    required this.border,
    required this.divider,
    required this.primaryGradient,
    required this.accentGradient,
    required this.heroGradient,
  });

  @override
  AppThemeColors copyWith({
    Color? primary,
    Color? accent,
    Color? accentLight,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? textLight,
    Color? textOnDark,
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? error,
    Color? errorLight,
    Color? info,
    Color? infoLight,
    Color? border,
    Color? divider,
    LinearGradient? primaryGradient,
    LinearGradient? accentGradient,
    LinearGradient? heroGradient,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textLight: textLight ?? this.textLight,
      textOnDark: textOnDark ?? this.textOnDark,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      accentGradient: accentGradient ?? this.accentGradient,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      textOnDark: Color.lerp(textOnDark, other.textOnDark, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primaryGradient: primaryGradient, // Not interpolating gradients for simplicity
      accentGradient: accentGradient,
      heroGradient: heroGradient,
    );
  }

  // Pre-defined static themes

  /// Light theme — kept for system-level compatibility but the app forces dark.
  static const AppThemeColors light = AppThemeColors(
    primary: Color(0xFF0A1628), // Deep Navy
    accent: Color(0xFF00C853), // Tesla Green
    accentLight: Color(0xFF69F0AE),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F5F9),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textLight: Color(0xFF94A3B8),
    textOnDark: Color(0xFFFFFFFF),
    success: Color(0xFF00C853),
    successLight: Color(0xFFB9F6CA),
    warning: Color(0xFFF59E0B),
    warningLight: Color(0xFFFEF3C7),
    error: Color(0xFFEF4444),
    errorLight: Color(0xFFFEE2E2),
    info: Color(0xFF3B82F6),
    infoLight: Color(0xFFEFF6FF),
    border: Color(0xFFE2E8F0),
    divider: Color(0xFFF1F5F9),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A1628), Color(0xFF1E293B)],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
    ),
    heroGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Color(0xFF000000)],
    ),
  );

  /// Dark theme — Tesla-inspired: true black, charcoal surfaces, vivid green accents.
  static const AppThemeColors dark = AppThemeColors(
    primary: Color(0xFF000000), // True black — default background
    accent: Color(0xFF00C853), // Tesla vivid green
    accentLight: Color(0xFF69F0AE), // Lighter green glow
    background: Color(0xFF000000), // Pure black
    surface: Color(0xFF151515), // Elevated card surface (Tesla charcoal)
    surfaceVariant: Color(0xFF1E1E1E), // Slightly lighter for inputs / variants
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF9E9E9E),
    textLight: Color(0xFF616161),
    textOnDark: Color(0xFFFFFFFF),
    success: Color(0xFF00C853), // Green = success too
    successLight: Color(0xFF1A3A2A), // Dark green tint for backgrounds
    warning: Color(0xFFFFC107),
    warningLight: Color(0xFF2A220A),
    error: Color(0xFFFF5252),
    errorLight: Color(0xFF2A0A0A),
    info: Color(0xFF448AFF),
    infoLight: Color(0xFF0A1A2A),
    border: Color(0xFF2A2A2A), // Subtle dark border
    divider: Color(0xFF1A1A1A),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0D0D0D), Color(0xFF000000)],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
    ),
    heroGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Color(0xFF000000)],
    ),
  );
}

extension AppThemeColorsExtension on BuildContext {
  AppThemeColors get colors => Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.dark;
}
