import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings (Rajdhani)
  static TextStyle h1({Color color = AppColors.textPrimary}) => GoogleFonts.rajdhani(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 0.5,
      );

  static TextStyle h2({Color color = AppColors.textPrimary}) => GoogleFonts.rajdhani(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      );

  static TextStyle h3({Color color = AppColors.textPrimary}) => GoogleFonts.rajdhani(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      );

  static TextStyle h4({Color color = AppColors.textPrimary}) => GoogleFonts.rajdhani(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      );

  // Big Score Display (Oxanium)
  static TextStyle scoreHuge({Color color = AppColors.textPrimary}) => GoogleFonts.oxanium(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.0,
      );

  static TextStyle scoreLarge({Color color = AppColors.textPrimary}) => GoogleFonts.oxanium(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.1,
      );

  static TextStyle scoreMedium({Color color = AppColors.textPrimary}) => GoogleFonts.oxanium(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.1,
      );

  // Body (Inter)
  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  static TextStyle bodyMedium({Color color = AppColors.textPrimary}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle bodySmall({Color color = AppColors.textSecondary}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.3,
      );

  static TextStyle caption({Color color = AppColors.textMuted}) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.2,
      );

  // Stat Numbers (Rajdhani)
  static TextStyle statValue({Color color = AppColors.textPrimary, double fontSize = 16}) =>
      GoogleFonts.rajdhani(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.1,
      );

  static TextStyle statLabel({Color color = AppColors.textSecondary}) =>
      GoogleFonts.rajdhani(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 1.0,
      );

  // Badges & Pills
  static TextStyle badge({Color color = AppColors.textPrimary}) => GoogleFonts.rajdhani(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.8,
      );
}
