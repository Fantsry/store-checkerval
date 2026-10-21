import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/core/share/share_card_shell.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';

class MatchShareCard extends StatelessWidget {
  final MatchSummary match;

  const MatchShareCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final isDraw = match.isDraw;
    final outcomeColor = isDraw
        ? AppColors.drawAmber
        : (match.won == true ? AppColors.winGreen : AppColors.lossRed);

    return ShareCardShell(
      eyebrow: match.queueDisplayName.toUpperCase(),
      title: match.mapName.toUpperCase(),
      accent: outcomeColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            match.resultText,
            style: AppTextStyles.h1(color: outcomeColor).copyWith(fontSize: 40),
          ),
          Text(
            match.scoreDisplay,
            style: AppTextStyles.scoreLarge(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ShareStat(
                  label: 'AGENT',
                  value: match.agentName.toUpperCase(),
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: _ShareStat(
                  label: 'K / D / A',
                  value: '${match.kills} / ${match.deaths} / ${match.assists}',
                  color: AppColors.accentSoft,
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
                  value: '${match.averageCombatScore}',
                  color: AppColors.accentSoft,
                ),
              ),
              Expanded(
                child: _ShareStat(
                  label: 'HEADSHOT',
                  value: '${match.headshotPercentage}%',
                  color: AppColors.vpGold,
                ),
              ),
              Expanded(
                child: _ShareStat(
                  label: 'K/D',
                  value: match.kdRatio.toStringAsFixed(2),
                  color: match.kdRatio >= 1
                      ? AppColors.winGreen
                      : AppColors.lossRed,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            match.rankName?.toUpperCase() ?? 'UNRATED',
            style: AppTextStyles.statLabel(color: AppColors.textSecondary),
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
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.h4(color: color),
        ),
      ],
    );
  }
}
