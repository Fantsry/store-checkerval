import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/kills_by_round_widget.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/match_detail_sheet.dart';

class MatchCard extends StatefulWidget {
  final MatchSummary match;
  final bool initiallyExpanded;

  const MatchCard({
    super.key,
    required this.match,
    this.initiallyExpanded = false,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  late bool _isExpanded;
  int _activeTab = 0; // 0: Teams & Scoreboard, 1: Round Kills

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes.clamp(1, 60)}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isWin = match.won == true;
    final isDraw = match.isDraw;
    final outcomeColor = isWin
        ? const Color(0xFF00C4A8)
        : (isDraw ? Colors.amber : AppTheme.valorantRed);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: outcomeColor.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Section (Match Header & User Quick Summary)
            Stack(
              children: [
                // Background Map Splash
                if (match.mapImageUrl != null && match.mapImageUrl!.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      match.mapImageUrl!,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.surfaceDark,
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(color: AppTheme.surfaceDark),
                  ),

                // Gradient Overlay for Readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppTheme.surfaceDark.withValues(alpha: 0.97),
                          AppTheme.surfaceDark.withValues(alpha: 0.90),
                          AppTheme.surfaceDark.withValues(alpha: 0.70),
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),

                // Left Accent Line
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(color: outcomeColor),
                ),

                // Header Content
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Outcome + Map + Score
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        match.resultText.toUpperCase(),
                                        style: TextStyle(
                                          color: outcomeColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        match.scoreDisplay,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    match.mapName.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${match.queueDisplayName} • ${_formatTimeAgo(match.gameStartTime)}',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // User's Agent Icon & Name
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        width: 1.5,
                                      ),
                                      color:
                                          Colors.black.withValues(alpha: 0.4),
                                    ),
                                    child: ClipOval(
                                      child: match.agentIconUrl != null &&
                                              match.agentIconUrl!.isNotEmpty
                                          ? Image.network(
                                              match.agentIconUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.person,
                                                color: AppTheme.textMuted,
                                                size: 20,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              color: AppTheme.textMuted,
                                              size: 20,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    match.agentName,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // User's Personal Stats: K/D/A, ACS, Rank & RR
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // K/D/A
                                  Text(
                                    '${match.kills} / ${match.deaths} / ${match.assists}',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),

                                  // K/D Ratio & ACS
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${match.kdRatio.toStringAsFixed(2)} KD',
                                        style: TextStyle(
                                          color: match.kdRatio >= 1.0
                                              ? const Color(0xFF00C4A8)
                                              : AppTheme.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${match.averageCombatScore} ACS',
                                        style: const TextStyle(
                                          color: AppTheme.valorantCyan,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),

                                  // Rank Badge Image & RR / Rank Name
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (match.rankIconUrl != null &&
                                          match.rankIconUrl!.isNotEmpty) ...[
                                        CachedNetworkImage(
                                          imageUrl: match.rankIconUrl!,
                                          width: 16,
                                          height: 16,
                                          fit: BoxFit.contain,
                                          errorWidget: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      if (match.rankRatingEarned != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (match.rankRatingEarned! >= 0
                                                        ? const Color(
                                                            0xFF00C4A8)
                                                        : AppTheme.valorantRed)
                                                    .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${match.rankRatingEarned! >= 0 ? '+' : ''}${match.rankRatingEarned} RR',
                                            style: TextStyle(
                                              color:
                                                  match.rankRatingEarned! >= 0
                                                      ? const Color(0xFF00C4A8)
                                                      : AppTheme.valorantRed,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        )
                                      else if (match.rankName != null &&
                                          match.rankName != 'Unrated')
                                        Text(
                                          match.rankName!,
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Quick Preview Row & Interactive Expand Pill
                        Row(
                          children: [
                            // Allies Preview
                            if (match.teammates.isNotEmpty) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00E5FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              ...match.teammates.take(5).map(
                                    (p) => _MiniPlayerAvatar(
                                      player: p,
                                      teamColor: const Color(0xFF00E5FF),
                                    ),
                                  ),
                              const SizedBox(width: 6),
                            ],

                            if (!match.isDeathmatch &&
                                match.enemies.isNotEmpty) ...[
                              const Text(
                                'VS',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Enemies Preview
                              ...match.enemies.take(5).map(
                                    (p) => _MiniPlayerAvatar(
                                      player: p,
                                      teamColor: AppTheme.valorantRed,
                                    ),
                                  ),
                              const SizedBox(width: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.valorantRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],

                            const Spacer(),

                            // Expand / Collapse Action Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isExpanded
                                    ? AppTheme.valorantRed.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isExpanded
                                      ? AppTheme.valorantRed
                                          .withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                    color: _isExpanded
                                        ? AppTheme.valorantRed
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _isExpanded
                                        ? 'Hide Teams'
                                        : 'Teams & Kills',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _isExpanded
                                          ? AppTheme.valorantRed
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Expanded Section: Tabs for Scoreboard & Round Kills
            if (_isExpanded) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark.withValues(alpha: 0.95),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Tab Selector: Teams & Scoreboard VS Round Kills
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: Colors.black.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: 'TEAMS & SCOREBOARD',
                              icon: Icons.people_alt_outlined,
                              isSelected: _activeTab == 0,
                              onTap: () => setState(() => _activeTab = 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TabButton(
                              label: match.rounds.isNotEmpty
                                  ? 'ROUND KILLS (${match.rounds.length})'
                                  : 'ROUND KILLS',
                              icon: Icons.military_tech_outlined,
                              isSelected: _activeTab == 1,
                              onTap: () => setState(() => _activeTab = 1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab Body
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                      child: _activeTab == 0
                          ? _buildScoreboardView(match)
                          : _buildRoundKillsView(match),
                    ),

                    // Bottom Bar: Full Details Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tap player row or open full sheet for analysis',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted.withValues(alpha: 0.8),
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                MatchDetailSheet.show(context, match),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.valorantRed
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.valorantRed
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.analytics_outlined,
                                    size: 13,
                                    color: AppTheme.valorantRed,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Full Details',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.valorantRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreboardView(MatchSummary match) {
    if (match.isDeathmatch) {
      return _DeathmatchLeaderboardCard(
        players: match.allPlayers,
        matchMvpPuuid: match.matchMvpPuuid,
      );
    }

    return Column(
      children: [
        if (match.teammates.isNotEmpty)
          _TeamScoreboardCard(
            teamTitle: 'ALLIES (YOUR TEAM)',
            teamScore: match.scoreWon,
            teamColor: const Color(0xFF00E5FF),
            isWinner: match.won == true,
            players: match.teammates,
            matchMvpPuuid: match.matchMvpPuuid,
            teamMvpPuuid: match.teamMvpPuuid,
          ),
        if (match.enemies.isNotEmpty) ...[
          const SizedBox(height: 10),
          _TeamScoreboardCard(
            teamTitle: 'ENEMIES (OPPONENTS)',
            teamScore: match.scoreLost,
            teamColor: AppTheme.valorantRed,
            isWinner: match.won == false,
            players: match.enemies,
            matchMvpPuuid: match.matchMvpPuuid,
            teamMvpPuuid: match.teamMvpPuuid,
          ),
        ],
      ],
    );
  }

  Widget _buildRoundKillsView(MatchSummary match) {
    return KillsByRoundWidget(match: match);
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.valorantRed.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.valorantRed.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamScoreboardCard extends StatelessWidget {
  final String teamTitle;
  final int teamScore;
  final Color teamColor;
  final bool isWinner;
  final List<MatchPlayerSummary> players;
  final String? matchMvpPuuid;
  final String? teamMvpPuuid;

  const _TeamScoreboardCard({
    required this.teamTitle,
    required this.teamScore,
    required this.teamColor,
    required this.isWinner,
    required this.players,
    this.matchMvpPuuid,
    this.teamMvpPuuid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: teamColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Team Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.09),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: teamColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      teamTitle,
                      style: TextStyle(
                        color: teamColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$teamScore Rounds Won',
                  style: TextStyle(
                    color: isWinner
                        ? const Color(0xFF00C4A8)
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Column Headers Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.black.withValues(alpha: 0.25),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'PLAYER & AGENT',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'RANK',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'K / D / A',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    'KD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    'ACS',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Players List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: players.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.04),
            ),
            itemBuilder: (context, index) {
              final player = players[index];
              return _PlayerScoreRow(
                player: player,
                teamColor: teamColor,
                isMatchMvp: player.puuid == matchMvpPuuid,
                isTeamMvp: player.puuid == teamMvpPuuid,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DeathmatchLeaderboardCard extends StatelessWidget {
  final List<MatchPlayerSummary> players;
  final String? matchMvpPuuid;

  const _DeathmatchLeaderboardCard({
    required this.players,
    this.matchMvpPuuid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.09),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: const Row(
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 15, color: Colors.amber),
                SizedBox(width: 6),
                Text(
                  'DEATHMATCH LEADERBOARD',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: players.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.04),
            ),
            itemBuilder: (context, index) {
              final player = players[index];
              return _PlayerScoreRow(
                player: player,
                teamColor: Colors.amber,
                rankPosition: index + 1,
                isMatchMvp: index == 0,
                isTeamMvp: false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlayerScoreRow extends StatelessWidget {
  final MatchPlayerSummary player;
  final Color teamColor;
  final int? rankPosition;
  final bool isMatchMvp;
  final bool isTeamMvp;

  const _PlayerScoreRow({
    required this.player,
    required this.teamColor,
    this.rankPosition,
    this.isMatchMvp = false,
    this.isTeamMvp = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelf = player.isSelf;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: isSelf
          ? const Color(0xFFE5B94E).withValues(alpha: 0.09)
          : Colors.transparent,
      child: Row(
        children: [
          // Rank Position (for Deathmatch)
          if (rankPosition != null) ...[
            SizedBox(
              width: 18,
              child: Text(
                '#$rankPosition',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: rankPosition == 1
                      ? Colors.amber
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],

          // Agent Portrait
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelf
                    ? const Color(0xFFE5B94E)
                    : teamColor.withValues(alpha: 0.4),
                width: isSelf ? 1.4 : 0.8,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: player.agentIconUrl != null &&
                      player.agentIconUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: player.agentIconUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // Player Name & Badges
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelf
                              ? const Color(0xFFE5B94E)
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFE5B94E).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE5B94E),
                          ),
                        ),
                      ),
                    ],
                    if (isMatchMvp) ...[
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'MVP',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ] else if (isTeamMvp) ...[
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'TEAM',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  player.agentName,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Rank Badge + Rank Name
          Expanded(
            flex: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  child: player.rankIconUrl != null &&
                          player.rankIconUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: player.rankIconUrl!,
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                        )
                      : const Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    player.rankName ?? 'Unrated',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // K / D / A
          Expanded(
            flex: 3,
            child: Text(
              player.kdaDisplay,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // KD Ratio
          SizedBox(
            width: 32,
            child: Text(
              player.kdRatio.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: player.kdRatio >= 1.0
                    ? const Color(0xFF00C4A8)
                    : AppTheme.textSecondary,
              ),
            ),
          ),

          // ACS
          SizedBox(
            width: 38,
            child: Text(
              '${player.averageCombatScore}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.valorantCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _MiniPlayerAvatar extends StatelessWidget {
  final MatchPlayerSummary player;
  final Color teamColor;

  const _MiniPlayerAvatar({
    required this.player,
    required this.teamColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelf = player.isSelf;

    return Tooltip(
      message:
          '${player.displayName} (${player.agentName} • ${player.rankName ?? 'Unrated'} • ${player.kdaDisplay})',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.4),
          border: Border.all(
            color: isSelf
                ? const Color(0xFFE5B94E)
                : teamColor.withValues(alpha: 0.45),
            width: isSelf ? 1.3 : 0.9,
          ),
        ),
        child: ClipOval(
          child: player.agentIconUrl != null && player.agentIconUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: player.agentIconUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.person,
                    size: 12,
                    color: AppTheme.textMuted,
                  ),
                )
              : const Icon(
                  Icons.person,
                  size: 12,
                  color: AppTheme.textMuted,
                ),
        ),
      ),
    );
  }
}
