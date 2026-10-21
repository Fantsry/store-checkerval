import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/core/share/share_card_shell.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';

class RankShareCard extends StatelessWidget {
  final CareerOverview overview;
  final String playerName;

  const RankShareCard({
    super.key,
    required this.overview,
    this.playerName = '',
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        playerName.trim().isEmpty ? 'MY RANK' : playerName.toUpperCase();

    return ShareCardShell(
      eyebrow: 'CAREER',
      title: displayName,
      accent: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overview.currentTierName.toUpperCase(),
            style: AppTextStyles.h1().copyWith(fontSize: 38),
          ),
          Text(
            '${overview.currentRankRating} RR',
            style: AppTextStyles.scoreLarge(color: AppColors.accentSoft),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(width: 44, height: 3, color: AppColors.accent),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ShareStat(
                  label: 'WIN RATE',
                  value: '${overview.winRate.toStringAsFixed(0)}%',
                  color: overview.winRate >= 50
                      ? AppColors.winGreen
                      : AppColors.lossRed,
                ),
              ),
              Expanded(
                child: _ShareStat(
                  label: 'K/D',
                  value: overview.avgKdRatio.toStringAsFixed(2),
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ShareStat(
                  label: 'ACS',
                  value: '${overview.avgCombatScore}',
                  color: AppColors.accentSoft,
                ),
              ),
              Expanded(
                child: _ShareStat(
                  label: 'HEADSHOT',
                  value: '${overview.avgHeadshotPct.toStringAsFixed(0)}%',
                  color: AppColors.vpGold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'PEAK ${(overview.peakTierName ?? 'UNRATED').toUpperCase()}',
            style: AppTextStyles.statLabel(color: AppColors.textSecondary),
          ),
          Text(
            '${overview.totalMatches} MATCHES TRACKED',
            style: AppTextStyles.caption(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ShareStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(color: AppColors.textMuted),
        ),
        Text(value, style: AppTextStyles.h3(color: color)),
      ],
    );
  }
}
