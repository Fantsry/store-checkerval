export 'package:valorant_store_tracker/ui/theme/app_colors.dart';
export 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
export 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
export 'package:valorant_store_tracker/ui/theme/app_radius.dart';
export 'package:valorant_store_tracker/ui/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/theme/app_theme.dart';

class AppTheme {
  AppTheme._();

  static const Color accentMagenta = AppColors.accent;
  static const Color accentPurple = AppColors.purple;
  static const Color winGreen = AppColors.winGreen;
  static const Color loseRed = AppColors.lossRed;
  static const Color selfHighlight = AppColors.accentSoft;

  static const Color backgroundDark = AppColors.background;
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceDark = AppColors.surface;
  static const Color surfaceColor = AppColors.surface;
  static const Color surfaceLight = AppColors.cardElevated;
  static const Color cardDark = AppColors.card;

  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textMuted;

  static const Color valorantRed = AppColors.accent;
  static const Color valorantDarkRed = AppColors.accentStrong;
  static const Color valorantCyan = AppColors.accentSoft;

  static const Color tierSelect = AppColors.tierSelect;
  static const Color tierDeluxe = AppColors.tierDeluxe;
  static const Color tierPremium = AppColors.tierPremium;
  static const Color tierUltra = AppColors.tierUltra;
  static const Color tierExclusive = AppColors.tierExclusive;

  static const Color vpGold = AppColors.vpGold;

  static const LinearGradient primaryGradient = AppColors.primaryGradient;
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.background, AppColors.background],
  );
  static const LinearGradient cardGradient = AppColors.cardGradient;

  static TextStyle statLarge({Color color = textPrimary}) =>
      AppTextStyles.statValue(color: color, fontSize: 18);

  static TextStyle statMedium({Color color = textPrimary}) =>
      AppTextStyles.statValue(color: color, fontSize: 15);

  static TextStyle statSmall({Color color = textPrimary}) =>
      AppTextStyles.statValue(color: color, fontSize: 13);

  static TextStyle scoreBig({Color color = textPrimary}) =>
      AppTextStyles.scoreHuge(color: color);

  static TextStyle labelCaption({Color color = textSecondary}) =>
      AppTextStyles.label(color: color);

  static ThemeData get darkTheme => DarkTheme.darkTheme;

  static Color getTierColor(String? tier) => AppColors.getTierColor(tier);

  static Color getRankTierColor(String tierName) => AppColors.getRankColor(tierName);
}
