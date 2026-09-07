import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';

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
                        ] else if (match.rankName != null) ...[
                          Text(
                            match.rankName!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
