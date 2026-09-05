/// Valorant-themed dark UI theme.
///
/// Color palette inspired by Valorant's brand:
/// - Primary Red: #FF4655 (Valorant red)
/// - Background: #0F1923 (deep dark blue)
/// - Surface: #1B2733 (card background)
/// - Accent: #BD3944 (darker red for accents)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Brand Colors ───────────────────────────────────────────
  static const Color valorantRed = Color(0xFFFF4655);
  static const Color valorantDarkRed = Color(0xFFBD3944);
  static const Color valorantCyan = Color(0xFF17DEE6);

  static const Color backgroundDark = Color(0xFF0F1923);
  static const Color backgroundColor = backgroundDark;
  static const Color surfaceDark = Color(0xFF1B2733);
  static const Color surfaceColor = surfaceDark;
  static const Color surfaceLight = Color(0xFF253340);
  static const Color cardDark = Color(0xFF1E2D3B);

  static const Color textPrimary = Color(0xFFECE8E1);
  static const Color textSecondary = Color(0xFF8B978F);
  static const Color textMuted = Color(0xFF5A6B5F);

  // ─── Skin Tier Colors ───────────────────────────────────────
  static const Color tierSelect = Color(0xFF5A9FE1);
  static const Color tierDeluxe = Color(0xFF00C4A8);
  static const Color tierPremium = Color(0xFFD1548D);
  static const Color tierUltra = Color(0xFFF5D662);
  static const Color tierExclusive = Color(0xFFFF4655);

  // ─── VP (Valorant Points) ───────────────────────────────────
  static const Color vpGold = Color(0xFFEAD085);

  // ─── Gradients ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [valorantRed, valorantDarkRed],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F1923), Color(0xFF0A1018)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2D3B), Color(0xFF152230)],
  );

  // ─── Theme Data ─────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: valorantRed,
        secondary: valorantCyan,
        surface: surfaceDark,
        error: Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onError: Colors.black,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 1.2,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: valorantRed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: valorantRed,
          side: const BorderSide(color: valorantRed, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        hintStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: valorantRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: valorantRed,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: valorantRed.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceDark,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.05),
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: valorantRed,
      ),
    );
  }

  /// Get color for skin tier.
  static Color getTierColor(String? tier) {
    return switch (tier?.toLowerCase()) {
      'select' => tierSelect,
      'deluxe' => tierDeluxe,
      'premium' => tierPremium,
      'ultra' => tierUltra,
      'exclusive' => tierExclusive,
      _ => textSecondary,
    };
  }
}
