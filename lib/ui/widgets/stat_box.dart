import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
      padding: EdgeInsets.only(
        top: compact ? AppSpacing.sm : AppSpacing.md,
        bottom: compact ? AppSpacing.xs : AppSpacing.sm,
        left: compact ? 0 : AppSpacing.xs,
        right: compact ? 0 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.statLabel(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.statValue(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: compact ? 17 : 22,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
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
