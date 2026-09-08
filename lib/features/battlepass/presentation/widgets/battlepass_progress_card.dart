import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2333),
            Color(0xFF0F1923),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.valorantRed.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.valorantRed.withValues(alpha: 0.08),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Overall Act Progress: ${(overallProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.valorantRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'TIER ${overview.currentTier}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tier XP Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Tier Progress',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '${overview.currentTierXp} / ${overview.tierXpRequired} XP',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE5B94E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: tierProgress,
              minHeight: 10,
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.valorantRed),
            ),
          ),
          const SizedBox(height: 14),

          // Total XP stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Earned: ${overview.totalXpEarned} XP',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                'Max Tier: ${overview.maxTier}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          // Upcoming Rewards Preview
          if (overview.nextRewards.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            const SizedBox(height: 14),
            const Text(
              'UPCOMING TIER REWARDS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
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
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: reward.isFree
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.08),
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
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
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
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'FREE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF00E5FF),
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
