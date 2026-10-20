import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class VpChip extends StatelessWidget {
  final int? amount;
  final bool isRadianite;
  final double fontSize;
  final bool compact;

  const VpChip({
    super.key,
    this.amount,
    this.isRadianite = false,
    this.fontSize = 13,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final formatted = amount == null ? '--' : formatter.format(amount!);
    final color = isRadianite ? AppColors.radianite : AppColors.vpGold;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs + 2 : AppSpacing.sm,
        vertical: compact ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.roundedSm,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isRadianite ? Icons.hexagon_outlined : Icons.monetization_on_outlined,
            size: fontSize + 1,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isRadianite ? '$formatted RP' : '$formatted VP',
            style: AppTextStyles.statValue(
              color: color,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
