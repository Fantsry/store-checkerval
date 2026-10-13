import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class RankBadge extends StatelessWidget {
  final String tierName;
  final int? rankedRating;
  final int? tier;
  final String? iconUrl;
  final double iconSize;
  final bool showProgress;
  final bool showLabel;

  const RankBadge({
    super.key,
    required this.tierName,
    this.rankedRating,
    this.tier,
    this.iconUrl,
    this.iconSize = 36,
    this.showProgress = true,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = AppColors.getRankColor(tierName);
    final rr = rankedRating ?? 0;
    final progress = (rr.clamp(0, 100)) / 100.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ValorantRankIcon(
          tierName: tierName,
          tier: tier,
          iconUrl: iconUrl,
          size: iconSize,
          showGlow: true,
        ),
        if (showLabel) ...[
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tierName.toUpperCase(),
                style: AppTextStyles.h4(color: AppColors.textPrimary).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (showProgress) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: AppRadius.roundedPill,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$rr RR',
                      style: AppTextStyles.caption(color: rankColor).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
