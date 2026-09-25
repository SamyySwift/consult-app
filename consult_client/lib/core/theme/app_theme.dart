import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colors = AppThemeColors.light;
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: Brightness.light,
        primary: colors.accent,
        secondary: colors.accent,
        surface: colors.background,
        error: colors.error,
      ),
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: colors.textPrimary),
        displayMedium: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: colors.textPrimary),
        displaySmall: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: colors.textPrimary),
        headlineLarge: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: colors.textPrimary),
        headlineMedium: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: colors.textPrimary),
        headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
        titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary),
        titleSmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: colors.textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: colors.textLight),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: colors.textPrimary, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: colors.surfaceVariant,
          disabledForegroundColor: colors.textLight,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          side: BorderSide(color: colors.accent, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: colors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: colors.textLight, fontSize: 14),
        errorStyle: GoogleFonts.inter(color: colors.error, fontSize: 12),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return colors.accent;
          return colors.textLight;
        }),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: colors.surface,
        contentTextStyle: GoogleFonts.inter(color: colors.textPrimary, fontSize: 14),
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        selectedColor: colors.accent.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accent.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.accent, size: 24);
          }
          return IconThemeData(color: colors.textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: colors.accent);
          }
          return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: colors.textSecondary);
        }),
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shadowColor: colors.border,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.accent;
          return colors.textLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.accent.withValues(alpha: 0.3);
          return colors.border;
        }),
      ),
    );
  }

  // ── Dark Theme — Tesla-inspired ───────────────────────────────────────────
  static ThemeData get darkTheme {
    final colors = AppThemeColors.dark;
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: Brightness.dark,
        primary: colors.accent,
        secondary: colors.accent,
        surface: colors.background,
        error: colors.error,
      ),
      scaffoldBackgroundColor: colors.background, // pure black
      extensions: [colors],
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: colors.textPrimary),
        displayMedium: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: colors.textPrimary),
        displaySmall: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: colors.textPrimary),
        headlineLarge: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: colors.textPrimary),
        headlineMedium: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: colors.textPrimary),
        headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
        titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary),
        titleSmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: colors.textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: colors.textLight),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.1, color: Colors.black),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: colors.textLight),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background, // true black app bar
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: colors.textPrimary, size: 22),
      ),
      // Green CTA buttons with black text (Tesla style)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: colors.surfaceVariant,
          disabledForegroundColor: colors.textLight,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          side: BorderSide(color: colors.accent.withValues(alpha: 0.6), width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: colors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: colors.textLight, fontSize: 14),
        errorStyle: GoogleFonts.inter(color: colors.error, fontSize: 12),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return colors.accent;
          return colors.textLight;
        }),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: colors.surface,
        contentTextStyle: GoogleFonts.inter(color: colors.textPrimary, fontSize: 14),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        selectedColor: colors.accent.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.background,
        indicatorColor: Colors.transparent, // no fill indicator — Tesla-style
        height: 64,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.accent, size: 24);
          }
          return IconThemeData(color: colors.textLight, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: colors.accent);
          }
          return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: colors.textLight);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.accent;
          return colors.textLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.accent.withValues(alpha: 0.3);
          return colors.border;
        }),
      ),
    );
  }
}
