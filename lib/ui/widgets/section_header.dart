import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Color accentColor;
  final Widget? trailing;
  final String? index;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
    this.accentColor = AppColors.accent,
    this.trailing,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (index != null) ...[
                Text(
                  index!,
                  style: AppTextStyles.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sectionLabel(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Divider(color: AppColors.border, height: 1),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ] else if (actionLabel != null && onActionTap != null) ...[
                const SizedBox(width: AppSpacing.md),
                GestureDetector(
                  onTap: onActionTap,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    actionLabel!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label(color: accentColor),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: AppTextStyles.caption(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
