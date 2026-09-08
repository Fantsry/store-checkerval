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
      child: Row(
        children: [
          // Agent Portrait
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
              child: player.agentIcon != null
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
          const SizedBox(width: 12),

          // Player Name & Agent Pick
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
                          color: const Color(0xFFE5B94E).withValues(alpha: 0.2),
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
                      const SizedBox(width: 6),
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
              ],
            ),
          ),

          // Rank & RR Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (player.rankIcon != null)
                    CachedNetworkImage(
                      imageUrl: player.rankIcon!,
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    player.currentRankTierName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Peak: ${player.peakRankTierName}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
