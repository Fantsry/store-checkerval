import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class StatBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color? textColor;
  final IconData? icon;
  final bool outlined;
  final double fontSize;

  const StatBadge({
    super.key,
    required this.text,
    this.color = AppColors.accent,
    this.textColor,
    this.icon,
    this.outlined = false,
    this.fontSize = 10,
  });

  factory StatBadge.win() => const StatBadge(
        text: 'VICTORY',
        color: AppColors.winGreen,
      );

  factory StatBadge.loss() => const StatBadge(
        text: 'DEFEAT',
        color: AppColors.lossRed,
      );

  factory StatBadge.draw() => const StatBadge(
        text: 'DRAW',
        color: AppColors.drawAmber,
      );

  factory StatBadge.mvp() => const StatBadge(
        text: 'MATCH MVP',
        color: AppColors.vpGold,
        icon: Icons.star_rounded,
      );

  factory StatBadge.teamMvp() => const StatBadge(
        text: 'TEAM MVP',
        color: AppColors.accentSoft,
        icon: Icons.star_border_rounded,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: outlined ? 0.04 : 0.1),
        borderRadius: AppRadius.roundedSm,
        border: Border.all(
          color: color.withValues(alpha: outlined ? 0.55 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: fontSize + 2,
              color: textColor ?? color,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            text.toUpperCase(),
            style: AppTextStyles.badge(color: textColor ?? color).copyWith(
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
