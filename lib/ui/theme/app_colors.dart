import 'package:flutter/material.dart';

/// Esports HUD Design System – Color Palette
/// Clean, high-contrast dark theme inspired by Valorant broadcasts.
class AppColors {
  AppColors._();

  // Background & Surfaces
  static const Color background = Color(0xFF0F1923);
  static const Color surface = Color(0xFF141E28);
  static const Color card = Color(0xFF182330);
  static const Color cardElevated = Color(0xFF1E2D3D);
  static const Color border = Color(0xFF263647);
  static const Color borderSubtle = Color(0x1AFFFFFF);

  // Brand Accents
  static const Color red = Color(0xFFFF4655);
  static const Color redDark = Color(0xFFBD2835);
  static const Color redLight = Color(0xFFFF727E);
  static const Color cyan = Color(0xFF00F5D4);
  static const Color cyanDark = Color(0xFF00BFA5);
  static const Color purple = Color(0xFF9D4EDD);

  // Status & Outcomes
  static const Color winGreen = Color(0xFF00E676);
  static const Color winGreenDark = Color(0xFF00897B);
  static const Color lossRed = Color(0xFFFF4655);
  static const Color drawAmber = Color(0xFFFFB300);

  // Typography
  static const Color textPrimary = Color(0xFFECE8E1);
  static const Color textSecondary = Color(0xFF8B97A5);
  static const Color textMuted = Color(0xFF505E6D);

  // Currencies & Tiers
  static const Color vpGold = Color(0xFFFFD700);
  static const Color radianite = Color(0xFF00E5FF);

  static const Color tierSelect = Color(0xFF5A9FE1);
  static const Color tierDeluxe = Color(0xFF00E676);
  static const Color tierPremium = Color(0xFFD1548D);
  static const Color tierUltra = Color(0xFFF5D662);
  static const Color tierExclusive = Color(0xFFFF4655);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, redDark],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, cyanDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF182330), Color(0xFF121B24)],
  );

  static const LinearGradient winGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x2E00E676), Color(0x0500E676)],
  );

  static const LinearGradient lossGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x2EFF4655), Color(0x05FF4655)],
  );

  /// Helper to get tier color
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

  /// Helper to get rank color
  static Color getRankColor(String? rankName) {
    final lower = rankName?.toLowerCase() ?? '';
    if (lower.contains('iron')) return const Color(0xFF6E6E6E);
    if (lower.contains('bronze')) return const Color(0xFFB47742);
    if (lower.contains('silver')) return const Color(0xFFB0B0B0);
    if (lower.contains('gold')) return const Color(0xFFE5B94E);
    if (lower.contains('platinum')) return const Color(0xFF32C8B0);
    if (lower.contains('diamond')) return const Color(0xFF4AA4F8);
    if (lower.contains('ascendant')) return const Color(0xFF2DCD70);
    if (lower.contains('immortal')) return const Color(0xFFFF4655);
    if (lower.contains('radiant')) return const Color(0xFFFFFACD);
    return textSecondary;
  }
}
