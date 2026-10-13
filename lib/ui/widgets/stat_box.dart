import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final Color? subtitleColor;
  final Widget? trailing;
  final bool compact;
  final Color? backgroundColor;

  const StatBox({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.subtitleColor,
    this.trailing,
    this.compact = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface.withValues(alpha: 0.6),
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTextStyles.statLabel(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTextStyles.statValue(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: compact ? 15 : 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTextStyles.caption(
                color: subtitleColor ?? AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
