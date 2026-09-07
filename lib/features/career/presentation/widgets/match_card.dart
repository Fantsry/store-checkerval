import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/match_detail_sheet.dart';

class MatchCard extends StatelessWidget {
  final MatchSummary match;

  const MatchCard({
    super.key,
    required this.match,
  });

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
    final isWin = match.won == true;
    final isDraw = match.isDraw;
    final outcomeColor = isWin
        ? const Color(0xFF00C4A8)
        : (isDraw ? Colors.amber : AppTheme.valorantRed);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
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
        child: InkWell(
          onTap: () => MatchDetailSheet.show(context, match),
          child: Stack(
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
                        AppTheme.surfaceDark.withValues(alpha: 0.96),
                        AppTheme.surfaceDark.withValues(alpha: 0.88),
                        AppTheme.surfaceDark.withValues(alpha: 0.65),
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

              // Match Content
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
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
                                style: TextStyle(
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

                    // Agent Icon & Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                            child: ClipOval(
                              child: match.agentIconUrl != null &&
                                      match.agentIconUrl!.isNotEmpty
                                  ? Image.network(
                                      match.agentIconUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
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

                    // Stats: K/D/A, ACS, RR
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

                          // RR Tag or Rank
                          if (match.rankRatingEarned != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (match.rankRatingEarned! >= 0
                                        ? const Color(0xFF00C4A8)
                                        : AppTheme.valorantRed)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${match.rankRatingEarned! >= 0 ? '+' : ''}${match.rankRatingEarned} RR',
                                style: TextStyle(
                                  color: match.rankRatingEarned! >= 0
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
