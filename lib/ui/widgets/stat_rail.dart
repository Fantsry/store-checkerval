import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class StatRailItem {
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;

  const StatRailItem({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
  });
}

class StatRail extends StatelessWidget {
  final List<StatRailItem> items;

  const StatRail({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 38,
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              color: AppColors.border,
            ),
          Expanded(child: _StatCell(item: items[i])),
        ],
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final StatRailItem item;

  const _StatCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.statLabel(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          item.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.statValue(
            color: item.valueColor ?? AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        if (item.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            item.subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
