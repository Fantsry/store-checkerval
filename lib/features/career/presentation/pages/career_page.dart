import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/core/share/share_preview_sheet.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_cubit.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_state.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/career_trend_charts.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/performance_stats_card.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/rank_share_card.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';
import 'package:valorant_store_tracker/l10n/l10n.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/agent_avatar.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/custom_tab_bar.dart';
import 'package:valorant_store_tracker/ui/widgets/empty_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/shimmer_loading.dart';

class CareerPage extends StatefulWidget {
  const CareerPage({super.key});

  @override
  State<CareerPage> createState() => _CareerPageState();
}

class _CareerPageState extends State<CareerPage> {
  final List<String> _filterTabs = [
    'ALL',
    'COMPETITIVE',
    'UNRATED',
    'DEATHMATCH',
  ];
  int _currentFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<CareerCubit>();
    if (cubit.state is CareerInitial) {
      cubit.loadCareer();
    } else {
      cubit.loadCareer(forceRefresh: true);
    }
  }

  void _onFilterSelected(int index) {
    setState(() {
      _currentFilterIndex = index;
    });
    final queue = switch (index) {
      1 => 'competitive',
      2 => 'unrated',
      3 => 'deathmatch',
      _ => 'all',
    };
    context.read<CareerCubit>().filterQueue(queue);
  }

  Future<void> _shareRankCard() async {
    final state = context.read<CareerCubit>().state;
    if (state is! CareerLoaded) return;

    var playerName = '';
    if (getIt.isRegistered<SecureStorageService>()) {
      final storage = getIt<SecureStorageService>();
      final gameName = await storage.getGameName();
      final tagLine = await storage.getTagLine();
      if (gameName != null && gameName.isNotEmpty) {
        playerName = tagLine != null && tagLine.isNotEmpty
            ? '$gameName#$tagLine'
            : gameName;
      }
    }
    if (!mounted) return;

    final overview = state.overview;
    await showSharePreviewSheet(
      context,
      card: RankShareCard(overview: overview, playerName: playerName),
      shareText:
          'My Valorant rank: ${overview.currentTierName} (${overview.currentRankRating} RR) — tracked with Store Checker Val.',
      fileName: 'valorant_rank_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tracker',
          style: AppTextStyles.h2(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.ios_share_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: _shareRankCard,
            tooltip: context.l10n.shareRankCard,
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () => context.read<CareerCubit>().refresh(),
            tooltip: context.l10n.refreshMatches,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => context.read<CareerCubit>().refresh(),
          color: AppColors.accent,
          backgroundColor: AppColors.card,
          child: BlocBuilder<CareerCubit, CareerState>(
            builder: (context, state) {
              if (state is CareerLoading && state.cachedOverview == null) {
                return _buildLoadingSkeleton();
              }

              if (state is CareerError && state.cachedOverview == null) {
                final isAuthError =
                    state.message.toLowerCase().contains('session') ||
                    state.message.toLowerCase().contains('unauthorized') ||
                    state.message.toLowerCase().contains('sign in') ||
                    state.message.toLowerCase().contains('login') ||
                    state.message.toLowerCase().contains('re-authenticate');
                return ErrorStateView(
                  message: isAuthError
                      ? 'Sesi login Riot Anda memerlukan pembaruan. Ketuk untuk menyinkronkan riwayat pertandingan.'
                      : state.message,
                  onRetry: () => context.read<CareerCubit>().refresh(),
                  actionLabel: isAuthError ? 'PERBARUI SESI' : null,
                  onAction: isAuthError
                      ? () async {
                          final reauthResult = await getIt<AuthRepository>()
                              .silentReauth();
                          if (reauthResult.isSuccess) {
                            if (context.mounted) {
                              context.read<CareerCubit>().refresh();
                            }
                          } else if (context.mounted) {
                            context.push('/login');
                          }
                        }
                      : null,
                );
              }

              final overview = state is CareerLoaded
                  ? state.overview
                  : (state is CareerLoading ? state.cachedOverview : null);

              if (overview == null) {
                return const SizedBox.shrink();
              }

              final matches = state is CareerLoaded
                  ? state.filteredMatches
                  : overview.matches;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state is CareerLoaded && state.syncError != null) ...[
                      _buildSyncErrorBanner(state.syncError!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildRankHero(overview),
                    const SizedBox(height: AppSpacing.md),
                    _buildPerformanceGrid(overview),
                    const SizedBox(height: AppSpacing.xxl),
                    const SectionHeader(index: '01', title: 'TRENDS'),
                    const SizedBox(height: AppSpacing.sm),
                    CareerTrendCharts(overview: overview),
                    const SizedBox(height: AppSpacing.xxl),
                    const SectionHeader(index: '02', title: 'INSIGHTS'),
                    const SizedBox(height: AppSpacing.sm),
                    PerformanceStatsCard(overview: overview),
                    const SizedBox(height: AppSpacing.xxl),
                    const SectionHeader(index: '03', title: 'MATCH HISTORY'),
                    const SizedBox(height: AppSpacing.md),
                    CustomTabBar(
                      tabs: _filterTabs,
                      selectedIndex: _currentFilterIndex,
                      onTabSelected: _onFilterSelected,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Text(
                          '${matches.length} MATCHES',
                          style: AppTextStyles.statLabel(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        if (state is CareerLoading)
                          Text(
                            'SYNCING',
                            style: AppTextStyles.statLabel(
                              color: AppColors.accent,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (matches.isEmpty)
                      const EmptyStateView(
                        icon: Icons.history_rounded,
                        title: 'NO MATCHES RECORDED',
                        description:
                            'No match history found for the selected filter.',
                      )
                    else
                      _buildMatchList(matches),
                    if (state is CareerLoaded && overview.hasMore)
                      _buildLoadMoreButton(state.isLoadingMore),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRankHero(CareerOverview overview) {
    final isPlacement = overview.isPlacement;
    final rr = overview.currentRankRating;
    final progress = isPlacement ? 0.0 : (rr / 100).clamp(0.0, 1.0);

    return DataPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValorantRankIcon(
                tier: overview.currentTier,
                iconUrl: overview.currentTierIcon,
                tierName: overview.currentTierName,
                size: 54,
                showGlow: true,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT RANK',
                      style: AppTextStyles.statLabel(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      overview.currentTierName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h2(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          isPlacement ? 'PLACEMENT' : '$rr',
                          style: AppTextStyles.statValue(
                            color: isPlacement
                                ? AppColors.textSecondary
                                : AppColors.accent,
                            fontSize: 15,
                          ),
                        ),
                        if (!isPlacement) ...[
                          const SizedBox(width: 3),
                          Text(
                            'RR',
                            style: AppTextStyles.statLabel(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        if (isPlacement &&
                            overview.gamesNeededForRating != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${overview.gamesNeededForRating} LEFT',
                            style: AppTextStyles.statLabel(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PEAK',
                    style: AppTextStyles.statLabel(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  ValorantRankIcon(
                    tier: overview.peakTier,
                    iconUrl: overview.peakTierIcon,
                    tierName: overview.peakTierName ?? 'Unrated',
                    size: 28,
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 74,
                    child: Text(
                      overview.peakTierName ?? 'Unrated',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPlacement ? AppColors.textMuted : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat('MATCHES', '${overview.totalMatches}'),
              ),
              Container(width: 1, height: 26, color: AppColors.border),
              Expanded(
                child: _buildMiniStat(
                  'WINS',
                  '${overview.totalWins}',
                  alignEnd: true,
                ),
              ),
              Container(width: 1, height: 26, color: AppColors.border),
              Expanded(
                child: _buildMiniStat(
                  'LOSSES',
                  '${overview.totalLosses}',
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.statLabel(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.statValue(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceGrid(CareerOverview overview) {
    return DataPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCell(
                  'WIN RATE',
                  '${overview.winRate.toStringAsFixed(1)}%',
                  '${overview.totalWins}W / ${overview.totalLosses}L',
                  overview.winRate >= 50
                      ? AppColors.winGreen
                      : AppColors.lossRed,
                ),
              ),
              Container(width: 1, height: 62, color: AppColors.border),
              Expanded(
                child: _buildMetricCell(
                  'K/D RATIO',
                  overview.avgKdRatio.toStringAsFixed(2),
                  'Last 10 avg',
                  overview.avgKdRatio >= 1
                      ? AppColors.textPrimary
                      : AppColors.lossRed,
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
          Row(
            children: [
              Expanded(
                child: _buildMetricCell(
                  'AVG COMBAT SCORE',
                  '${overview.avgCombatScore}',
                  'ACS / round',
                  AppColors.accent,
                ),
              ),
              Container(width: 1, height: 62, color: AppColors.border),
              Expanded(
                child: _buildMetricCell(
                  'HEADSHOT',
                  '${overview.avgHeadshotPct.toStringAsFixed(0)}%',
                  '${overview.totalMatches} matches',
                  AppColors.accentSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCell(
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.statLabel(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.statValue(color: color, fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList(List<MatchSummary> matches) {
    return DataPanel(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          for (var i = 0; i < matches.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _buildMatchRow(matches[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchRow(MatchSummary match) {
    final isWon = match.won ?? false;
    final outcomeColor = match.isDraw
        ? AppColors.drawAmber
        : (isWon ? AppColors.winGreen : AppColors.lossRed);
    final outcome = match.isDraw ? 'D' : (isWon ? 'W' : 'L');
    final rankEarned = match.rankRatingEarned;
    final rankColor = rankEarned == null
        ? AppColors.textMuted
        : (rankEarned > 0
              ? AppColors.winGreen
              : (rankEarned == 0 ? AppColors.drawAmber : AppColors.lossRed));

    return InkWell(
      onTap: () => context.push('/match-detail', extra: match),
      splashColor: AppColors.accent.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: outcomeColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AgentAvatar(
              imageUrl: match.agentIconUrl,
              agentName: match.agentName,
              size: 40,
              borderColor: AppColors.border,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        outcome,
                        style: AppTextStyles.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: outcomeColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        match.scoreDisplay,
                        style: AppTextStyles.statValue(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      if (rankEarned != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        ValorantRankIcon(
                          tier: match.competitiveTier,
                          iconUrl: match.rankIconUrl,
                          tierName: match.rankName ?? 'Unrated',
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            rankEarned > 0
                                ? '+$rankEarned RR'
                                : '$rankEarned RR',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.statLabel(color: rankColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${match.mapName} / ${match.queueDisplayName} / '
                    '${DateFormat('d MMM').format(match.gameStartTime)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  match.kdaDisplay,
                  style: AppTextStyles.statValue(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.averageCombatScore} ACS',
                  style: AppTextStyles.statLabel(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: OutlinedButton(
        onPressed: isLoading
            ? null
            : () => context.read<CareerCubit>().loadMore(),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            : Text(context.l10n.careerLoadMore),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: const [
          ShimmerBox(height: 160, borderRadius: AppRadius.lg),
          SizedBox(height: AppSpacing.md),
          ShimmerBox(height: 130, borderRadius: AppRadius.lg),
          SizedBox(height: AppSpacing.lg),
          ShimmerCardList(itemCount: 4, itemHeight: 82),
        ],
      ),
    );
  }

  Widget _buildSyncErrorBanner(String error) {
    final isAuth =
        error.toLowerCase().contains('session') ||
        error.toLowerCase().contains('unauthorized') ||
        error.toLowerCase().contains('sign in') ||
        error.toLowerCase().contains('login') ||
        error.toLowerCase().contains('re-authenticate');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.lossRed.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.lossRed,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isAuth
                  ? 'Sesi Riot memerlukan pembaruan. Pertandingan terbaru belum tersinkron.'
                  : 'Gagal memperbarui match terbaru: $error',
              style: AppTextStyles.caption(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: isAuth
                ? () async {
                    final reauthResult = await getIt<AuthRepository>()
                        .silentReauth();
                    if (!mounted) return;
                    if (reauthResult.isSuccess) {
                      context.read<CareerCubit>().refresh();
                    } else {
                      context.push('/login');
                    }
                  }
                : () => context.read<CareerCubit>().refresh(),
            behavior: HitTestBehavior.opaque,
            child: Text(
              isAuth ? 'PERBARUI' : 'SYNC',
              style: AppTextStyles.label(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
