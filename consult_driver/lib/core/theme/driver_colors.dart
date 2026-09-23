import 'package:flutter/material.dart';

class DriverThemeColors extends ThemeExtension<DriverThemeColors> {
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

  // Job status colours (driver-specific)
  final Color jobAvailable;
  final Color jobActive;
  final Color jobCompleted;
  final Color jobCancelled;

  const DriverThemeColors({
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
    required this.jobAvailable,
    required this.jobActive,
    required this.jobCompleted,
    required this.jobCancelled,
  });

  @override
  DriverThemeColors copyWith({
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
    Color? jobAvailable,
    Color? jobActive,
    Color? jobCompleted,
    Color? jobCancelled,
  }) {
    return DriverThemeColors(
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
      jobAvailable: jobAvailable ?? this.jobAvailable,
      jobActive: jobActive ?? this.jobActive,
      jobCompleted: jobCompleted ?? this.jobCompleted,
      jobCancelled: jobCancelled ?? this.jobCancelled,
    );
  }

  @override
  DriverThemeColors lerp(ThemeExtension<DriverThemeColors>? other, double t) {
    if (other is! DriverThemeColors) return this;
    return DriverThemeColors(
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
      primaryGradient: primaryGradient,
      accentGradient: accentGradient,
      heroGradient: heroGradient,
      jobAvailable: Color.lerp(jobAvailable, other.jobAvailable, t)!,
      jobActive: Color.lerp(jobActive, other.jobActive, t)!,
      jobCompleted: Color.lerp(jobCompleted, other.jobCompleted, t)!,
      jobCancelled: Color.lerp(jobCancelled, other.jobCancelled, t)!,
    );
  }

  // ── Dark theme (Default Tesla-Inspired) ───────────────────────────────────
  static const DriverThemeColors dark = DriverThemeColors(
    primary: Color(0xFF000000),       // Pure Black
    accent: Color(0xFF00C853),        // Emerald Green (Tesla Style)
    accentLight: Color(0xFF00E676),   // Light Emerald Green
    background: Color(0xFF000000),    // Pure Black
    surface: Color(0xFF111111),       // Carbon Card Surface
    surfaceVariant: Color(0xFF161616),// Secondary Carbon
    textPrimary: Color(0xFFFFFFFF),   // Pure White
    textSecondary: Color(0xFFA0A0A0), // Soft Gray
    textLight: Color(0xFF666666),     // Muted Gray
    textOnDark: Color(0xFFFFFFFF),
    success: Color(0xFF00C853),
    successLight: Color(0xFF0A2E14),
    warning: Color(0xFFFFB300),
    warningLight: Color(0xFF332600),
    error: Color(0xFFFF3B30),
    errorLight: Color(0xFF330A08),
    info: Color(0xFF2979FF),
    infoLight: Color(0xFF0A1A33),
    border: Color(0xFF222222),
    divider: Color(0xFF1A1A1A),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF000000), Color(0xFF111111)],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00C853), Color(0xFF00E676)],
    ),
    heroGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Color(0xFF000000)],
    ),
    jobAvailable: Color(0xFF00C853),
    jobActive: Color(0xFF00C853),
    jobCompleted: Color(0xFF00C853),
    jobCancelled: Color(0xFFFF3B30),
  );

  // ── Light theme (Matches dark tone) ──────────────────────────────────────────
  static const DriverThemeColors light = dark;
}

extension DriverThemeColorsExtension on BuildContext {
  DriverThemeColors get colors =>
      Theme.of(this).extension<DriverThemeColors>() ?? DriverThemeColors.dark;
}

/// Backward-compatible shim — maps the static [DriverColors] API to the
/// Tesla dark-theme emerald green colour values.
abstract final class DriverColors {
  static const Color primary       = Color(0xFF000000);
  static const Color primaryLight  = Color(0xFF161616);
  static const Color accent        = Color(0xFF00C853);
  static const Color accentDark    = Color(0xFF009624);
  static const Color accentLight   = Color(0xFF00E676);
  static const Color background    = Color(0xFF000000);
  static const Color surface       = Color(0xFF111111);
  static const Color surfaceVariant = Color(0xFF161616);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textLight     = Color(0xFF666666);
  static const Color success       = Color(0xFF00C853);
  static const Color successLight  = Color(0xFF0A2E14);
  static const Color warning       = Color(0xFFFFB300);
  static const Color warningLight  = Color(0xFF332600);
  static const Color error         = Color(0xFFFF3B30);
  static const Color errorLight    = Color(0xFF330A08);
  static const Color info          = Color(0xFF2979FF);
  static const Color infoLight     = Color(0xFF0A1A33);
  static const Color border        = Color(0xFF222222);
  static const Color divider       = Color(0xFF1A1A1A);
  static const Color jobAvailable  = Color(0xFF00C853);
  static const Color jobActive     = Color(0xFF00C853);
  static const Color jobCompleted  = Color(0xFF00C853);
  static const Color jobCancelled  = Color(0xFFFF3B30);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF000000), Color(0xFF111111)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C853), Color(0xFF00E676)],
  );

  static const LinearGradient earningsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
  );
}
