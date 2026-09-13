import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/kills_by_round_widget.dart';

class MatchDetailSheet extends StatelessWidget {
  final MatchSummary match;

  const MatchDetailSheet({
    super.key,
    required this.match,
  });

  static void show(BuildContext context, MatchSummary match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MatchDetailSheet(match: match),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winColor = match.won == true
        ? const Color(0xFF00C4A8)
        : (match.isDraw ? Colors.amber : AppTheme.valorantRed);

    final durationMin = match.gameLengthMillis ~/ 60000;
    final durationSec = (match.gameLengthMillis % 60000) ~/ 1000;
    final durationStr = durationMin > 0
        ? '${durationMin}m ${durationSec}s'
        : '${durationSec}s';

    final totalHits = match.headshots + match.bodyshots + match.legshots;
    final hsPct = totalHits > 0 ? (match.headshots / totalHits) * 100 : 0.0;
    final bsPct = totalHits > 0 ? (match.bodyshots / totalHits) * 100 : 0.0;
    final lsPct = totalHits > 0 ? (match.legshots / totalHits) * 100 : 0.0;

    final adr = match.roundsPlayed > 0
        ? (match.damage / match.roundsPlayed).round()
        : 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Map Banner & Result
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        if (match.mapImageUrl != null &&
                            match.mapImageUrl!.isNotEmpty)
                          Image.network(
                            match.mapImageUrl!,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 130,
                              color: AppTheme.surfaceDark,
                            ),
                          )
                        else
                          Container(
                            height: 130,
                            color: AppTheme.surfaceDark,
                          ),

                        // Gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Banner Info
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: winColor.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: winColor.withValues(alpha: 0.6),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      match.resultText.toUpperCase(),
                                      style: TextStyle(
                                        color: winColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    match.mapName.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    '${match.queueDisplayName} • $durationStr',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              // Score
                              Text(
                                match.scoreDisplay,
                                style: TextStyle(
                                  color: winColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 28,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Agent & Rank Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Agent Icon
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.black.withValues(alpha: 0.3),
                          backgroundImage: match.agentIconUrl != null &&
                                  match.agentIconUrl!.isNotEmpty
                              ? NetworkImage(match.agentIconUrl!)
                              : null,
                          child: match.agentIconUrl == null ||
                                  match.agentIconUrl!.isEmpty
                              ? const Icon(Icons.person, color: AppTheme.textMuted)
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Agent & Queue
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.agentName,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${match.roundsPlayed} Rounds Played',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Rank & RR
                        if (match.rankRatingEarned != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (match.rankIconUrl != null &&
                                  match.rankIconUrl!.isNotEmpty) ...[
                                CachedNetworkImage(
                                  imageUrl: match.rankIconUrl!,
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: (match.rankRatingEarned! >= 0
                                          ? const Color(0xFF00C4A8)
                                          : AppTheme.valorantRed)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (match.rankRatingEarned! >= 0
                                            ? const Color(0xFF00C4A8)
                                            : AppTheme.valorantRed)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  '${match.rankRatingEarned! >= 0 ? '+' : ''}${match.rankRatingEarned} RR',
                                  style: TextStyle(
                                    color: match.rankRatingEarned! >= 0
                                        ? const Color(0xFF00C4A8)
                                        : AppTheme.valorantRed,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (match.rankName != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (match.rankIconUrl != null &&
                                  match.rankIconUrl!.isNotEmpty) ...[
                                CachedNetworkImage(
                                  imageUrl: match.rankIconUrl!,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                match.rankName!,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Key Stats Grid
                  const Text(
                    'PERFORMANCE OVERVIEW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      _DetailStatBox(
                        title: 'K / D / A',
                        value: '${match.kills}/${match.deaths}/${match.assists}',
                        valueColor: AppTheme.textPrimary,
                      ),
                      _DetailStatBox(
                        title: 'K/D RATIO',
                        value: match.kdRatio.toStringAsFixed(2),
                        valueColor: match.kdRatio >= 1.0
                            ? const Color(0xFF00C4A8)
                            : AppTheme.valorantRed,
                      ),
                      _DetailStatBox(
                        title: 'COMBAT SCORE',
                        value: '${match.averageCombatScore}',
                        valueColor: AppTheme.valorantCyan,
                      ),
                      _DetailStatBox(
                        title: 'TOTAL DAMAGE',
                        value: '${match.damage}',
                        valueColor: AppTheme.textPrimary,
                      ),
                      _DetailStatBox(
                        title: 'AVG DMG / RND',
                        value: '$adr',
                        valueColor: AppTheme.textPrimary,
                      ),
                      _DetailStatBox(
                        title: 'HEADSHOT %',
                        value: '${match.headshotPercentage.toStringAsFixed(1)}%',
                        valueColor: Colors.amber.shade300,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Accuracy / Hit Distribution
                  const Text(
                    'HIT ACCURACY BREAKDOWN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Stacked Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 12,
                            child: totalHits > 0
                                ? Row(
                                    children: [
                                      if (hsPct > 0)
                                        Expanded(
                                          flex: (hsPct * 10).round(),
                                          child: Container(color: Colors.amber),
                                        ),
                                      if (bsPct > 0)
                                        Expanded(
                                          flex: (bsPct * 10).round(),
                                          child: Container(
                                            color: AppTheme.valorantCyan,
                                          ),
                                        ),
                                      if (lsPct > 0)
                                        Expanded(
                                          flex: (lsPct * 10).round(),
                                          child: Container(
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                    ],
                                  )
                                : Container(color: AppTheme.surfaceLight),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stats Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _HitStat(
                              label: 'HEAD',
                              pct: hsPct,
                              count: match.headshots,
                              color: Colors.amber,
                            ),
                            _HitStat(
                              label: 'BODY',
                              pct: bsPct,
                              count: match.bodyshots,
                              color: AppTheme.valorantCyan,
                            ),
                            _HitStat(
                              label: 'LEGS',
                              pct: lsPct,
                              count: match.legshots,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Teams & Scoreboard Section
                  if (match.teammates.isNotEmpty || match.enemies.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'TEAMS & SCOREBOARD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (match.isDeathmatch)
                      _DeathmatchLeaderboardCard(
                        players: match.allPlayers,
                        matchMvpPuuid: match.matchMvpPuuid,
                      )
                    else ...[
                      if (match.teammates.isNotEmpty)
                        _TeamScoreboardCard(
                          teamTitle: 'YOUR TEAM (ALLIES)',
                          teamScore: match.scoreWon,
                          teamColor: const Color(0xFF00E5FF),
                          isWinner: match.won == true,
                          players: match.teammates,
                          matchMvpPuuid: match.matchMvpPuuid,
                          teamMvpPuuid: match.teamMvpPuuid,
                        ),

                      if (match.enemies.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _TeamScoreboardCard(
                          teamTitle: 'ENEMY TEAM (OPPONENTS)',
                          teamScore: match.scoreLost,
                          teamColor: AppTheme.valorantRed,
                          isWinner: match.won == false,
                          players: match.enemies,
                          matchMvpPuuid: match.matchMvpPuuid,
                          teamMvpPuuid: match.teamMvpPuuid,
                        ),
                      ],
                    ],
                  ],

                  // Round History & Kill Timeline Section (TRN Style)
                  if (match.rounds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    KillsByRoundWidget(match: match),
                  ],

                  const SizedBox(height: 16),

                  // Match ID & Copy
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: match.matchId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Match ID copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                      label: Text(
                        'Match ID: ${match.matchId.length > 16 ? '${match.matchId.substring(0, 16)}...' : match.matchId}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _DetailStatBox({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HitStat extends StatelessWidget {
  final String label;
  final double pct;
  final int count;
  final Color color;

  const _HitStat({
    required this.label,
    required this.pct,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label (${pct.toStringAsFixed(0)}%)',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$count hits',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: teamColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Team Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: teamColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      teamTitle,
                      style: TextStyle(
                        color: teamColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.6,
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
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            color: Colors.black.withValues(alpha: 0.25),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'PLAYER & AGENT',
                    style: TextStyle(
                      fontSize: 9,
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
                      fontSize: 9,
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
                      fontSize: 9,
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
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    'ACS',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 9,
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
              color: Colors.white.withValues(alpha: 0.05),
            ),
            itemBuilder: (context, index) {
              final player = players[index];
              return _PlayerScoreTile(
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: const Row(
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 16, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'DEATHMATCH LEADERBOARD',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.6,
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
              color: Colors.white.withValues(alpha: 0.05),
            ),
            itemBuilder: (context, index) {
              final player = players[index];
              return _PlayerScoreTile(
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

class _PlayerScoreTile extends StatelessWidget {
  final MatchPlayerSummary player;
  final Color teamColor;
  final int? rankPosition;
  final bool isMatchMvp;
  final bool isTeamMvp;

  const _PlayerScoreTile({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isSelf
          ? const Color(0xFFE5B94E).withValues(alpha: 0.08)
          : Colors.transparent,
      child: Row(
        children: [
          // Rank Position (for Deathmatch)
          if (rankPosition != null) ...[
            SizedBox(
              width: 20,
              child: Text(
                '#$rankPosition',
                style: TextStyle(
                  fontSize: 11,
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelf
                    ? const Color(0xFFE5B94E)
                    : teamColor.withValues(alpha: 0.4),
                width: isSelf ? 1.5 : 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: player.agentIconUrl != null &&
                      player.agentIconUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: player.agentIconUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 18,
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
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isSelf
                              ? const Color(0xFFE5B94E)
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 4),
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
                            fontSize: 8,
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
                          color:
                              const Color(0xFF00E5FF).withValues(alpha: 0.2),
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
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Rank Badge + Name
          Expanded(
            flex: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  child: player.rankIconUrl != null &&
                          player.rankIconUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: player.rankIconUrl!,
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                        )
                      : const Icon(
                          Icons.shield_outlined,
                          size: 16,
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
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Combat Stats: KDA
          Expanded(
            flex: 3,
            child: Text(
              player.kdaDisplay,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: player.kdRatio >= 1.0
                    ? const Color(0xFF00C4A8)
                    : AppTheme.textSecondary,
              ),
            ),
          ),

          // ACS
          SizedBox(
            width: 42,
            child: Text(
              '${player.averageCombatScore}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
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
