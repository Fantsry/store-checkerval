import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/battlepass_overview.dart';

class BattlepassProgressCard extends StatelessWidget {
  final BattlepassOverview overview;

  const BattlepassProgressCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final tierProgress = overview.tierProgressFraction;
    final overallProgress = overview.overallProgressFraction;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentMagenta.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentMagenta.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Act Title & Tier Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overview.battlepassName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'OVERALL ACT PROGRESS: ${(overallProgress * 100).toInt()}%',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accentMagenta,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  overview.currentTier == 0
                      ? 'TIER 1 (START)'
                      : 'TIER ${overview.currentTier}',
                  style: GoogleFonts.rajdhani(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tier XP Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                overview.currentTier >= overview.maxTier
                    ? 'BATTLEPASS COMPLETED'
                    : 'TIER ${overview.currentTier + 1} PROGRESS',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${overview.currentTierXp} / ${overview.tierXpRequired} XP',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFE5B94E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: tierProgress,
              minHeight: 8,
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentMagenta),
            ),
          ),
          const SizedBox(height: 12),

          // Total XP stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL EARNED: ${overview.totalXpEarned} XP',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                'MAX TIER: ${overview.maxTier}',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          // Upcoming Rewards Preview
          if (overview.nextRewards.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),
            const SizedBox(height: 12),
            const Text(
              'UPCOMING TIER REWARDS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 85,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: overview.nextRewards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final reward = overview.nextRewards[index];
                  return Container(
                    width: 115,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: reward.isFree
                            ? AppTheme.accentMagenta.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TIER ${reward.tier}',
                              style: GoogleFonts.rajdhani(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (reward.isFree)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentMagenta.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'FREE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.accentMagenta,
                                  ),
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
                                      size: 20,
                                      color: AppTheme.textSecondary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.card_giftcard_rounded,
                                    size: 20,
                                    color: AppTheme.textSecondary,
                                  ),
                          ),
                        ),
                        Text(
                          reward.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
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
