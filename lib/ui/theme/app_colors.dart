import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0C0B);
  static const Color surface = Color(0xFF111412);
  static const Color card = Color(0xFF151A17);
  static const Color cardElevated = Color(0xFF1B211D);
  static const Color border = Color(0xFF29312B);
  static const Color borderSubtle = Color(0x142E3A31);

  static const Color accent = Color(0xFF48C878);
  static const Color accentStrong = Color(0xFF2F9D57);
  static const Color accentSoft = Color(0xFF7BE3A7);
  static const Color onAccent = Color(0xFF06110A);

  static const Color red = accent;
  static const Color redDark = accentStrong;
  static const Color redLight = accentSoft;
  static const Color cyan = accentSoft;
  static const Color cyanDark = accentStrong;
  static const Color purple = Color(0xFF8BA696);

  static const Color winGreen = Color(0xFF48C878);
  static const Color winGreenDark = Color(0xFF2F9D57);
  static const Color lossRed = Color(0xFFFF5C5C);
  static const Color drawAmber = Color(0xFFE3B341);

  static const Color textPrimary = Color(0xFFF2F5F1);
  static const Color textSecondary = Color(0xFF9AA49C);
  static const Color textMuted = Color(0xFF667169);

  static const Color vpGold = Color(0xFFE6C66A);
  static const Color radianite = Color(0xFF7BE3A7);

  static const Color tierSelect = Color(0xFF6AA6D8);
  static const Color tierDeluxe = Color(0xFF4CC38A);
  static const Color tierPremium = Color(0xFFC96A9E);
  static const Color tierUltra = Color(0xFFD8C46A);
  static const Color tierExclusive = Color(0xFFE06B5E);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentSoft, accentSoft],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [card, card],
  );

  static const LinearGradient winGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1F48C878), Color(0x0048C878)],
  );

  static const LinearGradient lossGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1FFF5C5C), Color(0x00FF5C5C)],
  );

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
