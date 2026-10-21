import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/battlepass_overview.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';

class BattlepassProgressCard extends StatelessWidget {
  final BattlepassOverview overview;

  const BattlepassProgressCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final tierProgress = overview.tierProgressFraction;
    final overallProgress = overview.overallProgressFraction;
    final completed = overview.currentTier >= overview.maxTier;

    return DataPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACT BATTLEPASS',
                      style: AppTextStyles.statLabel(color: AppColors.accent),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      overview.battlepassName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h3(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  'TIER ${overview.currentTier}',
                  style: AppTextStyles.statValue(
                    color: AppColors.onAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(overallProgress * 100).round()}%',
                style: AppTextStyles.scoreHuge(
                  color: AppColors.textPrimary,
                ).copyWith(fontSize: 40),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'ACT PROGRESS',
                  style: AppTextStyles.statLabel(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 3,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completed
                          ? 'BATTLEPASS COMPLETED'
                          : 'TIER ${overview.currentTier + 1} PROGRESS',
                      style: AppTextStyles.statLabel(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${overview.currentTierXp} / ${overview.tierXpRequired} XP',
                      style: AppTextStyles.statValue(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL EARNED',
                    style: AppTextStyles.statLabel(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${overview.totalXpEarned} XP',
                    style: AppTextStyles.statValue(
                      color: AppColors.vpGold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: tierProgress,
              minHeight: 3,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentSoft,
              ),
            ),
          ),
          if (overview.nextRewards.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'UPCOMING REWARDS',
                  style: AppTextStyles.statLabel(color: AppColors.textMuted),
                ),
                const Spacer(),
                Text(
                  'MAX TIER ${overview.maxTier}',
                  style: AppTextStyles.statLabel(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: overview.nextRewards.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final reward = overview.nextRewards[index];
                  return Container(
                    width: 110,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppRadius.roundedSm,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'T${reward.tier}',
                              style: AppTextStyles.statLabel(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const Spacer(),
                            if (reward.isFree)
                              Text(
                                'FREE',
                                style: AppTextStyles.statLabel(
                                  color: AppColors.accent,
                                ),
                              ),
                          ],
                        ),
                        Expanded(
                          child: Center(
                            child: reward.displayIcon != null
                                ? CachedNetworkImage(
                                    imageUrl: reward.displayIcon!,
                                    fit: BoxFit.contain,
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.card_giftcard_rounded,
                                      size: 18,
                                      color: AppColors.textMuted,
                                    ),
                                  )
                                : const Icon(
                                    Icons.card_giftcard_rounded,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                          ),
                        ),
                        Text(
                          reward.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
