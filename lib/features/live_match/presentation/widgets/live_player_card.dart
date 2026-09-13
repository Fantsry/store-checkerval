import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_player_info.dart';

class LivePlayerCard extends StatelessWidget {
  final LivePlayerInfo player;
  final bool isEnemy;

  const LivePlayerCard({
    super.key,
    required this.player,
    this.isEnemy = false,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = isEnemy
        ? AppTheme.valorantRed
        : const Color(0xFF00E5FF);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: player.isSelf
              ? const Color(0xFFE5B94E).withValues(alpha: 0.8)
              : teamColor.withValues(alpha: 0.25),
          width: player.isSelf ? 1.5 : 1.0,
        ),
        boxShadow: player.isSelf
            ? [
                BoxShadow(
                  color: const Color(0xFFE5B94E).withValues(alpha: 0.15),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Agent Icon + Player Details + Rank Icon & Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Agent Portrait (44x44)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: teamColor.withValues(alpha: 0.4),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: player.agentIcon != null && player.agentIcon!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: player.agentIcon!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppTheme.valorantRed,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: AppTheme.textSecondary,
                            size: 24,
                          ),
                        )
                      : const Icon(
                          Icons.person_search_rounded,
                          color: AppTheme.textSecondary,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 10),

              // Middle: Player Name, Agent Pick, Tagline
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.gameName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: player.isSelf
                                  ? const Color(0xFFE5B94E)
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (player.isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFE5B94E).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE5B94E),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          player.agentName ?? 'Selecting...',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: player.agentName != null
                                ? teamColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                        if (player.tagLine.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Text(
                            '#${player.tagLine}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (player.peakRankTierName.isNotEmpty &&
                        player.peakRankTierName != 'Unranked') ...[
                      const SizedBox(height: 1),
                      Text(
                        'Peak: ${player.peakRankTierName}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right: Rank Section (Photo Rank + Rank Name & RR)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Rank Photo Badge
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Center(
                      child: player.rankIcon != null &&
                              player.rankIcon!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: player.rankIcon!,
                              width: 34,
                              height: 34,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: AppTheme.valorantRed,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.shield_outlined,
                                color: AppTheme.textSecondary,
                                size: 22,
                              ),
                            )
                          : const Icon(
                              Icons.shield_outlined,
                              color: AppTheme.textMuted,
                              size: 22,
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Rank Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        player.currentRankTierName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (player.currentRr > 0) ...[
                        const SizedBox(height: 1),
                        Text(
                          '${player.currentRr} RR',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00C4A8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Bottom Bar: Last 10 Competitive Matches (Win / Loss)
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_esports_outlined,
                  size: 13,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                const Text(
                  '10 Match Comp:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                if (player.recentTotalMatches > 0) ...[
                  // Match outcome indicator dots
                  if (player.recentMatchOutcomes.isNotEmpty) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: player.recentMatchOutcomes.map((isWin) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isWin
                                ? const Color(0xFF00C4A8)
                                : AppTheme.valorantRed,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Wins badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C4A8).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${player.recentWins}W',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00C4A8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Losses badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.valorantRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${player.recentLosses}L',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.valorantRed,
                      ),
                    ),
                  ),
                  if (player.recentWinRate != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${player.recentWinRate!.toStringAsFixed(0)}% WR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: player.recentWinRate! >= 50
                            ? const Color(0xFF00C4A8)
                            : AppTheme.valorantRed,
                      ),
                    ),
                  ],
                ] else ...[
                  const Text(
                    'No recent comp match',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
