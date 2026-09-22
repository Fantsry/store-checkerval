import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_player_info.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';

/// Ascend Companion style player card for live match.
/// Features: left accent bar, agent avatar, name/tag, W/L squares,
/// gem rank icons (CURRENT + PEAK), stat row (ACT, WIN, K/D, KAST, KDA, ACS, HS%, ADR).
class LivePlayerCard extends StatefulWidget {
  final LivePlayerInfo player;
  final bool isEnemy;

  const LivePlayerCard({
    super.key,
    required this.player,
    this.isEnemy = false,
  });

  @override
  State<LivePlayerCard> createState() => _LivePlayerCardState();
}

class _LivePlayerCardState extends State<LivePlayerCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final isEnemy = widget.isEnemy;
    final accentColor =
        isEnemy ? AppTheme.accentPurple : AppTheme.accentMagenta;

    final isSelf = player.isSelf;
    final cardBg = isSelf ? const Color(0xFF1E1F28) : AppTheme.cardDark;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(6),
          border: isSelf
              ? Border.all(
                  color: AppTheme.selfHighlight.withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
          boxShadow: isSelf
              ? [
                  BoxShadow(
                    color: AppTheme.selfHighlight.withValues(alpha: 0.1),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Left Accent Bar (3px) ──────────────────────────
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
              ),

              // ─── Card Content ──────────────────────────────────
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar + Name/WL + Rank Icons
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Agent Avatar
                          _AgentAvatar(
                            player: player,
                            accentColor: accentColor,
                          ),
                          const SizedBox(width: 8),

                          // Name + W/L boxes
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name row
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        player.gameName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (player.tagLine.isNotEmpty) ...[
                                      Text(
                                        '#${player.tagLine}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                    if (isSelf) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentMagenta
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          'YOU',
                                          style: GoogleFonts.inter(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.accentMagenta,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // W/L Squares
                                _WinLossSquares(
                                  outcomes: player.recentMatchOutcomes,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Rank Icons (CURRENT + PEAK)
                          _RankSection(player: player),
                        ],
                      ),

                      // ─── Stat Row (expandable) ────────────────────
                      if (_expanded) ...[
                        const SizedBox(height: 8),
                        _StatRow(player: player),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Agent Avatar ─────────────────────────────────────────────────

class _AgentAvatar extends StatelessWidget {
  final LivePlayerInfo player;
  final Color accentColor;

  const _AgentAvatar({required this.player, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: player.agentIcon != null && player.agentIcon!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: player.agentIcon!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppTheme.accentMagenta,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              )
            : const Icon(
                Icons.person_search_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
      ),
    );
  }
}

// ─── W/L Squares ──────────────────────────────────────────────────

class _WinLossSquares extends StatelessWidget {
  final List<bool> outcomes;

  const _WinLossSquares({required this.outcomes});

  @override
  Widget build(BuildContext context) {
    if (outcomes.isEmpty) {
      return Text(
        'No recent data',
        style: GoogleFonts.inter(
          fontSize: 9,
          color: AppTheme.textMuted,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: outcomes.take(5).map((isWin) {
        final color = isWin ? AppTheme.winGreen : AppTheme.loseRed;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: color.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              isWin ? 'W' : 'L',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Rank Section (CURRENT + PEAK) ────────────────────────────────

class _RankSection extends StatelessWidget {
  final LivePlayerInfo player;

  const _RankSection({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CURRENT Rank
        Column(
          children: [
            Text(
              'CURRENT',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            ValorantRankIcon(
              iconUrl: player.rankIcon,
              tierName: player.currentRankTierName,
              size: 24,
              showGlow: true,
              isCurrent: true,
            ),
            if (player.currentRankEpisodeAct != null) ...[
              const SizedBox(height: 1),
              Text(
                player.currentRankEpisodeAct!,
                style: GoogleFonts.inter(
                  fontSize: 7,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(width: 8),

        // PEAK Rank
        Column(
          children: [
            Text(
              'PEAK',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            ValorantRankIcon(
              iconUrl: player.peakRankIcon,
              tierName: player.peakRankTierName,
              size: 24,
              showGlow: false,
              isCurrent: false,
            ),
            if (player.peakRankEpisodeAct != null) ...[
              const SizedBox(height: 1),
              Text(
                player.peakRankEpisodeAct!,
                style: GoogleFonts.inter(
                  fontSize: 7,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── Stat Row ─────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final LivePlayerInfo player;

  const _StatRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LAST N label
          if (player.lastNMatchCount != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    'LAST ${player.lastNMatchCount}',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (player.lastNActScore != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${player.lastNActScore}',
                      style: AppTheme.statMedium(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'ACT',
                      style: AppTheme.labelCaption(),
                    ),
                  ],
                ],
              ),
            ),

          // Stats grid
          Row(
            children: [
              _StatItem(
                value: player.winPercentage != null
                    ? '${player.winPercentage!.toStringAsFixed(0)}%'
                    : '—',
                label: 'WIN',
                color: player.winPercentage != null && player.winPercentage! >= 50
                    ? AppTheme.winGreen
                    : AppTheme.textPrimary,
              ),
              _StatItem(
                value: player.kdRatio != null
                    ? player.kdRatio!.toStringAsFixed(2)
                    : '—',
                label: 'K/D',
                color: player.kdRatio != null && player.kdRatio! >= 1.0
                    ? AppTheme.winGreen
                    : AppTheme.textPrimary,
              ),
              _StatItem(
                value: player.kastPercentage != null
                    ? '${player.kastPercentage!.toStringAsFixed(0)}%'
                    : '—',
                label: 'KAST',
              ),
              _StatItem(
                value: player.kda != null
                    ? player.kda!.toStringAsFixed(2)
                    : '—',
                label: 'KDA',
              ),
              _StatItem(
                value: player.averageCombatScore != null
                    ? player.averageCombatScore!.toStringAsFixed(0)
                    : '—',
                label: 'ACS',
                color: AppTheme.winGreen,
                bold: true,
              ),
              _StatItem(
                value: player.headshotPercentage != null
                    ? '${player.headshotPercentage!.toStringAsFixed(0)}%'
                    : '—',
                label: 'HS%',
              ),
              _StatItem(
                value: player.averageDamageRound != null
                    ? player.averageDamageRound!.toStringAsFixed(0)
                    : '—',
                label: 'ADR',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool bold;

  const _StatItem({
    required this.value,
    required this.label,
    this.color = AppTheme.textPrimary,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: value == '—' ? AppTheme.textMuted : color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
