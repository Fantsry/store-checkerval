import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppFonts {
  AppFonts._();

  static const String sans = 'Geist';
  static const String mono = 'GeistMono';
}

class AppTextStyles {
  AppTextStyles._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle display({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 40,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.05,
        letterSpacing: -1.2,
      );

  static TextStyle h1({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.1,
        letterSpacing: -0.8,
      );

  static TextStyle h2({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle h3({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.25,
        letterSpacing: -0.2,
      );

  static TextStyle h4({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static TextStyle scoreHuge({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: 44,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.0,
        letterSpacing: -1.2,
        fontFeatures: _tabular,
      );

  static TextStyle scoreLarge({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.1,
        letterSpacing: -0.6,
        fontFeatures: _tabular,
      );

  static TextStyle scoreMedium({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.1,
        fontFeatures: _tabular,
      );

  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  static TextStyle bodyMedium({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  static TextStyle bodySmall({Color color = AppColors.textSecondary}) =>
      TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle caption({Color color = AppColors.textMuted}) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.3,
      );

  static TextStyle label({Color color = AppColors.textSecondary}) => TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.2,
        letterSpacing: 1.4,
      );

  static TextStyle sectionLabel({Color color = AppColors.textSecondary}) =>
      TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.2,
        letterSpacing: 1.2,
      );

  static TextStyle statValue({
    Color color = AppColors.textPrimary,
    double fontSize = 16,
  }) =>
      TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.1,
        fontFeatures: _tabular,
      );

  static TextStyle statLabel({Color color = AppColors.textSecondary}) =>
      TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 1.2,
        height: 1.2,
      );

  static TextStyle badge({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.8,
        height: 1.2,
      );

  static TextStyle button({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle mono({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        fontFeatures: _tabular,
      );
}
