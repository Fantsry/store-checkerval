import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_player_info.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';

/// Esports HUD style player card for live match.
/// Features:
/// - Player Card Landscape Wide Art banner in background with dark cinematic gradient mask
/// - Agent avatar with border
/// - Player name + tag + YOU tag
/// - 5-match W/L outcome squares
/// - CURRENT + PEAK gem rank icons with Episode/Act code
/// - Mirrored Enemy layout facing inward towards the center
/// - Sporty stat columns (ACT, WIN, K/D, KAST, KDA, ACS, HS%, ADR)
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

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141721),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelf
                ? AppTheme.accentMagenta.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelf ? 1.5 : 1,
          ),
          boxShadow: isSelf
              ? [
                  BoxShadow(
                    color: AppTheme.accentMagenta.withValues(alpha: 0.2),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            children: [
              // ─── 1. Landscape Wide Art Banner Background ──────────────
              if (player.cardWideArt != null &&
                  player.cardWideArt!.isNotEmpty) ...[
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: player.cardWideArt!,
                    fit: BoxFit.cover,
                    alignment:
                        isEnemy ? Alignment.centerRight : Alignment.centerLeft,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                // Gradient mask to ensure 100% text readability while keeping banner visible
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: isEnemy
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        end: isEnemy
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        stops: const [0.0, 0.45, 0.8, 1.0],
                        colors: isEnemy
                            ? [
                                Colors.black.withValues(alpha: 0.88),
                                Colors.black.withValues(alpha: 0.55),
                                Colors.black.withValues(alpha: 0.65),
                                Colors.black.withValues(alpha: 0.82),
                              ]
                            : [
                                Colors.black.withValues(alpha: 0.88),
                                Colors.black.withValues(alpha: 0.55),
                                Colors.black.withValues(alpha: 0.65),
                                Colors.black.withValues(alpha: 0.82),
                              ],
                      ),
                    ),
                  ),
                ),
                // Dark vertical bottom overlay for stats contrast
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.4, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // ─── 2. Accent Bar Indicator ─────────────────────────────
              Positioned(
                top: 0,
                bottom: 0,
                left: isEnemy ? null : 0,
                right: isEnemy ? 0 : null,
                child: Container(
                  width: 3.5,
                  decoration: BoxDecoration(
                    color: accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),

              // ─── 3. Card Foregound Content ───────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isEnemy ? 10 : 12,
                  8,
                  isEnemy ? 12 : 10,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Row: Agent Avatar, Name/Tag, W/L squares, Ranks
                    if (isEnemy)
                      _buildEnemyTopRow(player, accentColor)
                    else
                      _buildAllyTopRow(player, accentColor, isSelf),

                    // Expandable Sporty Stats Row
                    if (_expanded) ...[
                      const SizedBox(height: 7),
                      _SportyStatRow(player: player, isEnemy: isEnemy),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Ally Top Row (Avatar on Left, Ranks on Right) ───────────────
  Widget _buildAllyTopRow(
    LivePlayerInfo player,
    Color accentColor,
    bool isSelf,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Agent Avatar
        _AgentAvatar(player: player, accentColor: accentColor),
        const SizedBox(width: 8),

        // Name + Tag + W/L squares
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Player name row
              Row(
                children: [
                  Flexible(
                    child: Text(
                      player.gameName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (player.tagLine.isNotEmpty) ...[
                    Text(
                      '#${player.tagLine}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isSelf) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentMagenta,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentMagenta.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        'YOU',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),

              // Recent Match Outcomes (W/L squares)
              _WinLossSquares(outcomes: player.recentMatchOutcomes),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Ranks Section (CURRENT + PEAK)
        _RankSectionAlly(player: player),
      ],
    );
  }

  // ─── Enemy Top Row (Mirrored: Ranks on Left, Avatar on Right) ────
  Widget _buildEnemyTopRow(LivePlayerInfo player, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ranks Section (PEAK + CURRENT)
        _RankSectionEnemy(player: player),
        const SizedBox(width: 8),

        // Name + Tag + W/L squares (Right aligned)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Player name row (aligned right)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      player.gameName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (player.tagLine.isNotEmpty) ...[
                    Text(
                      '#${player.tagLine}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),

              // Recent Match Outcomes (W/L squares, aligned right)
              _WinLossSquares(
                outcomes: player.recentMatchOutcomes,
                alignRight: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Agent Avatar on far right
        _AgentAvatar(player: player, accentColor: accentColor),
      ],
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
          ),
        ],
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
  final bool alignRight;

  const _WinLossSquares({
    required this.outcomes,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outcomes.isEmpty) {
      return Text(
        'No recent matches',
        style: GoogleFonts.inter(
          fontSize: 9,
          color: AppTheme.textMuted,
        ),
      );
    }

    final children = outcomes.take(5).map((isWin) {
      final color = isWin ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
      return Container(
        width: 15,
        height: 15,
        margin: EdgeInsets.only(
          right: alignRight ? 0 : 3,
          left: alignRight ? 3 : 0,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Text(
            isWin ? 'W' : 'L',
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      );
    }).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: children,
    );
  }
}

// ─── Rank Section (Ally: CURRENT then PEAK) ───────────────────────

class _RankSectionAlly extends StatelessWidget {
  final LivePlayerInfo player;

  const _RankSectionAlly({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CURRENT Rank
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CURRENT',
              style: GoogleFonts.inter(
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 1),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PEAK',
              style: GoogleFonts.inter(
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 1),
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

// ─── Rank Section (Enemy Mirrored: PEAK then CURRENT) ─────────────

class _RankSectionEnemy extends StatelessWidget {
  final LivePlayerInfo player;

  const _RankSectionEnemy({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PEAK Rank (on left for enemy)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PEAK',
              style: GoogleFonts.inter(
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 1),
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
        const SizedBox(width: 8),

        // CURRENT Rank (on right for enemy)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CURRENT',
              style: GoogleFonts.inter(
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 1),
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
      ],
    );
  }
}

// ─── Sporty Stat Row (Supports Ally & Enemy Mirrored HUD) ──────────

class _SportyStatRow extends StatelessWidget {
  final LivePlayerInfo player;
  final bool isEnemy;

  const _SportyStatRow({
    required this.player,
    required this.isEnemy,
  });

  @override
  Widget build(BuildContext context) {
    final lastCount = player.lastNMatchCount ?? 15;
    final actScoreText = player.lastNActScore != null
        ? '${player.lastNActScore}..'
        : '—';

    // Build the 7 core stat items
    final winItem = _StatItem(
      value: player.winPercentage != null
          ? '${player.winPercentage!.toStringAsFixed(0)}%'
          : '—',
      label: 'WIN',
      color: player.winPercentage != null && player.winPercentage! >= 50
          ? const Color(0xFF22C55E)
          : AppTheme.textPrimary,
    );

    final kdItem = _StatItem(
      value: player.kdRatio != null ? player.kdRatio!.toStringAsFixed(2) : '—',
      label: 'K/D',
      color: player.kdRatio != null && player.kdRatio! >= 1.0
          ? const Color(0xFF22C55E)
          : AppTheme.textPrimary,
    );

    final kastItem = _StatItem(
      value: player.kastPercentage != null
          ? '${player.kastPercentage!.toStringAsFixed(0)}%'
          : '—',
      label: 'KAST',
    );

    final kdaItem = _StatItem(
      value: player.kda != null ? player.kda!.toStringAsFixed(2) : '—',
      label: 'KDA',
    );

    final acsItem = _StatItem(
      value: player.averageCombatScore != null
          ? player.averageCombatScore!.toStringAsFixed(0)
          : '—',
      label: 'ACS',
      color: const Color(0xFF4ADE80),
      bold: true,
    );

    final hsItem = _StatItem(
      value: player.headshotPercentage != null
          ? '${player.headshotPercentage!.toStringAsFixed(0)}%'
          : '—',
      label: 'HS%',
    );

    final adrItem = _StatItem(
      value: player.averageDamageRound != null
          ? player.averageDamageRound!.toStringAsFixed(0)
          : '—',
      label: 'ADR',
    );

    final actItem = _ActStatItem(
      lastCount: lastCount,
      actScoreText: actScoreText,
    );

    // Ally order: ACT | WIN | K/D | KAST | KDA | ACS | HS% | ADR
    // Enemy order (Mirrored from screenshot): ADR | HS% | ACS | KDA | KAST | K/D | WIN | ACT
    final List<Widget> items = isEnemy
        ? [adrItem, hsItem, acsItem, kdaItem, kastItem, kdItem, winItem, actItem]
        : [actItem, winItem, kdItem, kastItem, kdaItem, acsItem, hsItem, adrItem];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.8,
        ),
      ),
      child: Row(
        children: items,
      ),
    );
  }
}

// ─── Stat Item (Value on top, Label on bottom) ────────────────────

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
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                color: value == '—' ? AppTheme.textMuted : color,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Act Score Item (With LAST 15 Header) ─────────────────────────

class _ActStatItem extends StatelessWidget {
  final int lastCount;
  final String actScoreText;

  const _ActStatItem({
    required this.lastCount,
    required this.actScoreText,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LAST $lastCount',
            style: GoogleFonts.inter(
              fontSize: 6.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.2,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              actScoreText,
              style: GoogleFonts.rajdhani(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: actScoreText == '—'
                    ? AppTheme.textMuted
                    : AppTheme.textPrimary,
                height: 1.1,
              ),
            ),
          ),
          Text(
            'ACT',
            style: GoogleFonts.inter(
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
