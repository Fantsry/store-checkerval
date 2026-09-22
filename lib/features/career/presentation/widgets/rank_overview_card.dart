import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';

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
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Gem Rank Icon + Name + Peak Rank ──────────
          Row(
            children: [
              // Official Valorant Rank Icon (large)
              ValorantRankIcon(
                iconUrl: overview.currentTierIcon,
                tier: overview.currentTier,
                tierName: overview.currentTierName,
                size: 52,
                showGlow: true,
                isCurrent: true,
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
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (overview.currentTier > 0 ||
                            overview.currentRankRating > 0)
                          Text(
                            '${overview.currentRankRating} RR',
                            style: AppTheme.statLarge(
                              color: AppTheme.accentMagenta,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // RR Progress Bar (magenta)
                    if (overview.currentTier > 0 ||
                        overview.currentRankRating > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: rrProgress,
                          minHeight: 5,
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.accentMagenta,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Peak Rank with gem icon inline
                    if (overview.peakTierName != null &&
                        overview.peakTierName!.isNotEmpty &&
                        overview.peakTierName != 'Unrated')
                      Row(
                        children: [
                          ValorantRankIcon(
                            iconUrl: overview.peakTierIcon,
                            tier: overview.peakTier,
                            tierName: overview.peakTierName!,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Peak: ${overview.peakTierName}',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Recent Competitive Performance',
                        style: GoogleFonts.inter(
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
            color: Colors.white.withValues(alpha: 0.06),
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
                      ? AppTheme.winGreen
                      : AppTheme.loseRed,
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
                      ? AppTheme.winGreen
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
                      ? AppTheme.accentMagenta
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
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subValue,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
