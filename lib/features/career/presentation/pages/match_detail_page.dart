import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/map_kill_overlay_widget.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/agent_avatar.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/custom_tab_bar.dart';
import 'package:valorant_store_tracker/ui/widgets/kill_feed_item.dart';
import 'package:valorant_store_tracker/ui/widgets/round_timeline_widget.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_badge.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_box.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';

class MatchDetailPage extends StatefulWidget {
  final MatchSummary match;

  const MatchDetailPage({super.key, required this.match});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  int _selectedTabIndex = 0;
  int _selectedRoundIndex = 0;

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isWon = match.won ?? false;
    final isDraw = match.isDraw;
    final outcomeColor = isDraw
        ? AppColors.drawAmber
        : (isWon ? AppColors.winGreen : AppColors.lossRed);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'MATCH DETAILS',
          style: AppTextStyles.h3(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildMatchHeroHeader(match, outcomeColor),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: CustomTabBar(
                tabs: const ['SCOREBOARD', 'ROUNDS', 'PERFORMANCE'],
                selectedIndex: _selectedTabIndex,
                onTabSelected: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _buildScoreboardTab(match),
                  _buildRoundsTab(match),
                  _buildPerformanceTab(match),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchHeroHeader(MatchSummary match, Color outcomeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  StatBadge(
                    text: match.resultText,
                    color: outcomeColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ValorantRankIcon(
                    tier: match.competitiveTier,
                    iconUrl: match.rankIconUrl,
                    tierName: match.rankName ?? 'Unrated',
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match.queueDisplayName.toUpperCase(),
                    style: AppTextStyles.statLabel(color: AppColors.textSecondary),
                  ),
                ],
              ),
              Text(
                match.mapName.toUpperCase(),
                style: AppTextStyles.statLabel(color: AppColors.cyan),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AgentAvatar(
                    imageUrl: match.agentIconUrl,
                    agentName: match.agentName,
                    size: 52,
                    borderColor: outcomeColor,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: outcomeColor.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                      ),
                      child: ValorantRankIcon(
                        tier: match.competitiveTier,
                        iconUrl: match.rankIconUrl,
                        tierName: match.rankName ?? 'Unrated',
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xl),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${match.scoreWon}',
                    style: AppTextStyles.scoreHuge(
                      color: match.scoreWon >= match.scoreLost
                          ? AppColors.winGreen
                          : AppColors.textPrimary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      ':',
                      style: AppTextStyles.scoreHuge(color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    '${match.scoreLost}',
                    style: AppTextStyles.scoreHuge(
                      color: match.scoreLost > match.scoreWon
                          ? AppColors.lossRed
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xl),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.kdaDisplay,
                    style: AppTextStyles.statValue(color: AppColors.textPrimary, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${match.kdRatio.toStringAsFixed(2)} K/D',
                    style: AppTextStyles.caption(
                      color: match.kdRatio >= 1.0 ? AppColors.winGreen : AppColors.lossRed,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: SCOREBOARD ──────────────────────────────────────
  Widget _buildScoreboardTab(MatchSummary match) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Allies
          _buildTeamHeader('FRIENDLY TEAM', AppColors.cyan, match.scoreWon),
          const SizedBox(height: AppSpacing.sm),
          ...match.teammates.map((player) => _buildPlayerRow(player, isAlly: true)),

          const SizedBox(height: AppSpacing.xl),

          // Enemies
          _buildTeamHeader('ENEMY TEAM', AppColors.lossRed, match.scoreLost),
          const SizedBox(height: AppSpacing.sm),
          ...match.enemies.map((player) => _buildPlayerRow(player, isAlly: false)),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(String title, Color teamColor, int score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: teamColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.statLabel(color: teamColor),
            ),
          ],
        ),
        Text(
          '$score ROUNDS',
          style: AppTextStyles.caption(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(MatchPlayerSummary player, {required bool isAlly}) {
    final isSelf = player.isSelf;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isSelf
            ? AppColors.cyan.withValues(alpha: 0.12)
            : AppColors.card,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(
          color: isSelf ? AppColors.cyan.withValues(alpha: 0.5) : AppColors.border,
          width: isSelf ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Agent avatar with rank badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              AgentAvatar(
                imageUrl: player.agentIconUrl,
                agentName: player.agentName,
                size: 38,
                borderColor: isSelf
                    ? AppColors.cyan
                    : (isAlly ? AppColors.cyan.withValues(alpha: 0.3) : AppColors.lossRed.withValues(alpha: 0.3)),
              ),
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelf
                          ? AppColors.cyan
                          : (isAlly ? AppColors.cyan.withValues(alpha: 0.6) : AppColors.lossRed.withValues(alpha: 0.6)),
                      width: 1,
                    ),
                  ),
                  child: ValorantRankIcon(
                    tier: player.competitiveTier,
                    iconUrl: player.rankIconUrl,
                    tierName: player.rankName ?? 'Unrated',
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),

          // Name & Rank
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.gameName.isNotEmpty ? player.gameName : player.agentName,
                        style: AppTextStyles.bodyMedium(
                          color: isSelf ? AppColors.cyan : AppColors.textPrimary,
                        ).copyWith(
                          fontWeight: isSelf ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 4),
                      const StatBadge(
                        text: 'YOU',
                        color: AppColors.cyan,
                        fontSize: 8,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ValorantRankIcon(
                      tier: player.competitiveTier,
                      iconUrl: player.rankIconUrl,
                      tierName: player.rankName ?? 'Unrated',
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        (player.rankName != null && player.rankName!.isNotEmpty
                                ? player.rankName!
                                : 'UNRATED')
                            .toUpperCase(),
                        style: AppTextStyles.caption(color: AppColors.textSecondary).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ACS
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${player.averageCombatScore}',
                  style: AppTextStyles.statValue(color: AppColors.textPrimary, fontSize: 14),
                ),
                Text(
                  'ACS',
                  style: AppTextStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // KDA
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${player.kills}/${player.deaths}/${player.assists}',
                  style: AppTextStyles.statValue(color: AppColors.textPrimary, fontSize: 13),
                ),
                Text(
                  '${player.deaths > 0 ? (player.kills / player.deaths).toStringAsFixed(2) : player.kills} K/D',
                  style: AppTextStyles.caption(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: ROUNDS ──────────────────────────────────────────
  Widget _buildRoundsTab(MatchSummary match) {
    if (match.rounds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Round timeline details are not available for this game mode.',
            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final safeRoundIndex = _selectedRoundIndex.clamp(0, match.rounds.length - 1);
    final selectedRound = match.rounds[safeRoundIndex];
    final isRoundWon = selectedRound.won ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Round timeline scrubber
          SectionHeader(title: 'ROUND TIMELINE', subtitle: 'Select a round to inspect events'),
          const SizedBox(height: AppSpacing.sm),
          RoundTimelineWidget(
            rounds: match.rounds,
            selectedRoundIndex: safeRoundIndex,
            onRoundSelected: (index) {
              setState(() {
                _selectedRoundIndex = index;
              });
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Selected round outcome card
          AscendCard(
            borderColor: isRoundWon ? AppColors.winGreen : AppColors.lossRed,
            gradient: isRoundWon ? AppColors.winGradient : AppColors.lossGradient,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    StatBadge(
                      text: isRoundWon ? 'ROUND WON' : 'ROUND LOST',
                      color: isRoundWon ? AppColors.winGreen : AppColors.lossRed,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'ROUND ${selectedRound.roundNum}',
                      style: AppTextStyles.h4(color: AppColors.textPrimary),
                    ),
                  ],
                ),
                Text(
                  selectedRound.roundResult.toUpperCase(),
                  style: AppTextStyles.statLabel(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Round Kills feed
          SectionHeader(
            title: 'KILL FEED',
            subtitle: '${selectedRound.kills.length} Eliminations in Round ${selectedRound.roundNum}',
          ),
          const SizedBox(height: AppSpacing.sm),
          if (selectedRound.kills.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  'No eliminations recorded in this round',
                  style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...selectedRound.kills.map((k) => KillFeedItem(kill: k)),

          // Minimap kill overlay widget if available
          if (match.hasMinimapData) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'TACTICAL MAP', subtitle: 'Spatial Kill Heatmap'),
            const SizedBox(height: AppSpacing.sm),
            MapKillOverlayWidget(
              match: match,
              selectedRoundIndex: safeRoundIndex,
            ),
          ],
        ],
      ),
    );
  }

  // ─── TAB 3: PERFORMANCE ─────────────────────────────────────
  Widget _buildPerformanceTab(MatchSummary match) {
    final totalShots = match.totalShots;
    final hsPct = match.headshotPercentage;
    final bodyPct = totalShots > 0 ? ((match.bodyshots / totalShots) * 100).round() : 0;
    final legPct = totalShots > 0 ? ((match.legshots / totalShots) * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stat boxes summary
          Row(
            children: [
              Expanded(
                child: StatBox(
                  label: 'COMBAT SCORE',
                  value: '${match.score}',
                  subtitle: '${match.averageCombatScore} ACS',
                  valueColor: AppColors.cyan,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatBox(
                  label: 'TOTAL DAMAGE',
                  value: '${match.damage}',
                  subtitle: match.roundsPlayed > 0
                      ? '${(match.damage / match.roundsPlayed).round()} ADR'
                      : '0 ADR',
                  valueColor: AppColors.vpGold,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Accuracy / Hit breakdown
          AscendCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'SHOT ACCURACY', subtitle: 'Target Distribution'),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAccuracyMetric('HEAD', '$hsPct%', AppColors.red, match.headshots),
                    _buildAccuracyMetric('BODY', '$bodyPct%', AppColors.cyan, match.bodyshots),
                    _buildAccuracyMetric('LEGS', '$legPct%', AppColors.textSecondary, match.legshots),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Visual multi-color bar
                ClipRRect(
                  borderRadius: AppRadius.roundedPill,
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        if (hsPct > 0)
                          Expanded(
                            flex: hsPct,
                            child: Container(color: AppColors.red),
                          ),
                        if (bodyPct > 0)
                          Expanded(
                            flex: bodyPct,
                            child: Container(color: AppColors.cyan),
                          ),
                        if (legPct > 0)
                          Expanded(
                            flex: legPct,
                            child: Container(color: AppColors.border),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Economy & Round Details
          AscendCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'MATCH STATISTICS', subtitle: 'Telemetry Overview'),
                const SizedBox(height: AppSpacing.md),
                _buildStatDetailRow('Rounds Played', '${match.roundsPlayed}'),
                _buildStatDetailRow('Match Duration', '${(match.gameLengthMillis / 60000).round()} min'),
                _buildStatDetailRow('Total Kills', '${match.kills}'),
                _buildStatDetailRow('Total Deaths', '${match.deaths}'),
                _buildStatDetailRow('Total Assists', '${match.assists}'),
                _buildStatDetailRow('K/D Ratio', match.kdRatio.toStringAsFixed(2)),
                if (match.rankRatingEarned != null)
                  _buildStatDetailRow(
                    'Rank Rating Delta',
                    match.rankRatingEarned! >= 0
                        ? '+${match.rankRatingEarned} RR'
                        : '${match.rankRatingEarned} RR',
                    valueColor: match.rankRatingEarned! >= 0 ? AppColors.winGreen : AppColors.lossRed,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildAccuracyMetric(String label, String value, Color color, int count) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2(color: color),
        ),
        Text(
          label,
          style: AppTextStyles.statLabel(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          '$count hits',
          style: AppTextStyles.caption(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildStatDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.statValue(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
