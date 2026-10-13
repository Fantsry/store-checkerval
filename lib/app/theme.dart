/// Ascend Companion Theme Bridge
/// Re-exports modern design tokens and provides backward compatibility.
export 'package:valorant_store_tracker/ui/theme/app_colors.dart';
export 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
export 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
export 'package:valorant_store_tracker/ui/theme/app_radius.dart';
export 'package:valorant_store_tracker/ui/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_theme.dart';

class AppTheme {
  AppTheme._();

  // ─── Ascend Esports Colors ─────────────────────────────────
  static const Color accentMagenta = AppColors.red;
  static const Color accentPurple = AppColors.purple;
  static const Color winGreen = AppColors.winGreen;
  static const Color loseRed = AppColors.lossRed;
  static const Color selfHighlight = AppColors.cyan;

  static const Color backgroundDark = AppColors.background;
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceDark = AppColors.surface;
  static const Color surfaceColor = AppColors.surface;
  static const Color surfaceLight = AppColors.cardElevated;
  static const Color cardDark = AppColors.card;

  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textMuted;

  // ─── Legacy aliases ─────────────────────────────────────────
  static const Color valorantRed = AppColors.red;
  static const Color valorantDarkRed = AppColors.redDark;
  static const Color valorantCyan = AppColors.cyan;

  // ─── Skin Tier Colors ───────────────────────────────────────
  static const Color tierSelect = AppColors.tierSelect;
  static const Color tierDeluxe = AppColors.tierDeluxe;
  static const Color tierPremium = AppColors.tierPremium;
  static const Color tierUltra = AppColors.tierUltra;
  static const Color tierExclusive = AppColors.tierExclusive;

  // ─── VP (Valorant Points) ───────────────────────────────────
  static const Color vpGold = AppColors.vpGold;

  // ─── Gradients ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = AppColors.primaryGradient;
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.background, Color(0xFF080D13)],
  );
  static const LinearGradient cardGradient = AppColors.cardGradient;

  // ─── Stat Typography Helpers (Rajdhani) ─────────────────────
  static TextStyle statLarge({Color color = textPrimary}) =>
      GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.1,
      );

  static TextStyle statMedium({Color color = textPrimary}) =>
      GoogleFonts.rajdhani(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.1,
      );

  static TextStyle statSmall({Color color = textPrimary}) =>
      GoogleFonts.rajdhani(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.1,
      );

  static TextStyle scoreBig({Color color = textPrimary}) =>
      GoogleFonts.oxanium(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.0,
      );

  static TextStyle labelCaption({Color color = textSecondary}) =>
      GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.8,
      );

  static ThemeData get darkTheme => AscendTheme.darkTheme;

  static Color getTierColor(String? tier) => AppColors.getTierColor(tier);

  static Color getRankTierColor(String tierName) => AppColors.getRankColor(tierName);
}
