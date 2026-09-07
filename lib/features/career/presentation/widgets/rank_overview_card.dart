import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';

class RankOverviewCard extends StatelessWidget {
  final CareerOverview overview;

  const RankOverviewCard({
    super.key,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    final rrProgress = (overview.currentRankRating.clamp(0, 100)) / 100.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceDark,
            AppTheme.cardDark.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Rank Icon + Name + Peak Rank ──────────────
          Row(
            children: [
              // Rank Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: overview.currentTierIcon != null &&
                        overview.currentTierIcon!.isNotEmpty
                    ? Image.network(
                        overview.currentTierIcon!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.military_tech_rounded,
                          color: AppTheme.textSecondary,
                          size: 32,
                        ),
                      )
                    : const Icon(
                        Icons.military_tech_rounded,
                        color: AppTheme.textSecondary,
                        size: 32,
                      ),
              ),
              const SizedBox(width: 14),

              // Rank Name & RR
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            overview.currentTierName.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (overview.currentTier > 0)
                          Text(
                            '${overview.currentRankRating} RR',
                            style: const TextStyle(
                              color: AppTheme.valorantCyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // RR Progress Bar
                    if (overview.currentTier > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: rrProgress,
                          minHeight: 6,
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.valorantCyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Peak Rank if available
                    if (overview.peakTierName != null &&
                        overview.peakTierName!.isNotEmpty &&
                        overview.peakTierName != 'Unrated')
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: 13,
                            color: Colors.amber.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Peak: ${overview.peakTierName}',
                            style: TextStyle(
                              color: Colors.amber.shade300,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Recent Competitive Performance',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 14),

          // ─── Tracker Stats Grid ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _TrackerStatItem(
                  label: 'WIN RATE',
                  value: '${overview.winRate.toStringAsFixed(1)}%',
                  subValue: '${overview.totalWins}W ${overview.totalLosses}L',
                  color: overview.winRate >= 50
                      ? const Color(0xFF00C4A8)
                      : AppTheme.valorantRed,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              Expanded(
                child: _TrackerStatItem(
                  label: 'K/D RATIO',
                  value: overview.avgKdRatio.toStringAsFixed(2),
                  subValue: overview.avgKdRatio >= 1.0 ? 'Positive' : 'Negative',
                  color: overview.avgKdRatio >= 1.0
                      ? const Color(0xFF00C4A8)
                      : AppTheme.textSecondary,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              Expanded(
                child: _TrackerStatItem(
                  label: 'AVG ACS',
                  value: '${overview.avgCombatScore}',
                  subValue: 'Score/Rnd',
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              Expanded(
                child: _TrackerStatItem(
                  label: 'HEADSHOT',
                  value: '${overview.avgHeadshotPct.toStringAsFixed(1)}%',
                  subValue: 'Accuracy',
                  color: overview.avgHeadshotPct >= 20
                      ? Colors.amber.shade300
                      : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackerStatItem extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color color;

  const _TrackerStatItem({
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subValue,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
