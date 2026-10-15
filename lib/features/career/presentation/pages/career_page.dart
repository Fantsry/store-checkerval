import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_cubit.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_state.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/agent_avatar.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/custom_tab_bar.dart';
import 'package:valorant_store_tracker/ui/widgets/empty_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/rank_badge.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';
import 'package:valorant_store_tracker/ui/widgets/shimmer_loading.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_box.dart';

class CareerPage extends StatefulWidget {
  const CareerPage({super.key});

  @override
  State<CareerPage> createState() => _CareerPageState();
}

class _CareerPageState extends State<CareerPage> {
  final List<String> _filterTabs = ['ALL', 'COMPETITIVE', 'UNRATED', 'DEATHMATCH'];
  int _currentFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<CareerCubit>();
    if (cubit.state is CareerInitial) {
      cubit.loadCareer();
    } else {
      // Revalidate in background so today's matches appear without waiting for pull-to-refresh
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('TRACKER', style: AppTextStyles.h2(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => context.read<CareerCubit>().refresh(),
            tooltip: 'Refresh Matches',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => context.read<CareerCubit>().refresh(),
          color: AppColors.red,
          backgroundColor: AppColors.card,
          child: BlocBuilder<CareerCubit, CareerState>(
            builder: (context, state) {
              if (state is CareerLoading && state.cachedOverview == null) {
                return _buildLoadingSkeleton();
              }

              if (state is CareerError && state.cachedOverview == null) {
                final isAuthError = state.message.toLowerCase().contains('session') ||
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
                          final reauthResult =
                              await getIt<AuthRepository>().silentReauth();
                          if (reauthResult.isSuccess) {
                            if (context.mounted) {
                              context.read<CareerCubit>().refresh();
                            }
                          } else {
                            if (context.mounted) {
                              context.push('/login');
                            }
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

              final matches = state is CareerLoaded ? state.filteredMatches : overview.matches;

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
                    _buildRankAndPeakCard(overview),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPerformanceStatsGrid(overview),
                    const SizedBox(height: AppSpacing.lg),
                    CustomTabBar(
                      tabs: _filterTabs,
                      selectedIndex: _currentFilterIndex,
                      onTabSelected: _onFilterSelected,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      title: 'MATCH HISTORY',
                      subtitle: '${matches.length} Matches Found',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (matches.isEmpty)
                      const EmptyStateView(
                        icon: Icons.history_rounded,
                        title: 'NO MATCHES RECORDED',
                        description: 'No match history found for the selected filter.',
                      )
                    else
                      ...matches.map((m) => _buildMatchCard(m)),
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

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: const [
          ShimmerBox(height: 140, borderRadius: AppRadius.xl),
          SizedBox(height: AppSpacing.lg),
          ShimmerBox(height: 120, borderRadius: AppRadius.xl),
          SizedBox(height: AppSpacing.lg),
          ShimmerCardList(itemCount: 4, itemHeight: 96),
        ],
      ),
    );
  }

  Widget _buildRankAndPeakCard(CareerOverview overview) {
    return AscendCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.xl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current Rank
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT RANK',
                  style: AppTextStyles.statLabel(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                RankBadge(
                  tierName: overview.currentTierName,
                  rankedRating: overview.currentRankRating,
                  tier: overview.currentTier,
                  iconUrl: overview.currentTierIcon,
                  iconSize: 42,
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: AppColors.border),
          // Peak Rank
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PEAK RATING',
                    style: AppTextStyles.statLabel(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  RankBadge(
                    tierName: overview.peakTierName ?? 'Unrated',
                    tier: overview.peakTier,
                    iconUrl: overview.peakTierIcon,
                    iconSize: 34,
                    showProgress: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStatsGrid(CareerOverview overview) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatBox(
                label: 'WIN RATE',
                value: '${overview.winRate.toStringAsFixed(1)}%',
                subtitle: '${overview.totalWins}W / ${overview.totalLosses}L',
                valueColor: overview.winRate >= 50 ? AppColors.winGreen : AppColors.lossRed,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatBox(
                label: 'K/D RATIO',
                value: overview.avgKdRatio.toStringAsFixed(2),
                subtitle: 'Lifetime Avg',
                valueColor: overview.avgKdRatio >= 1.0 ? AppColors.winGreen : AppColors.lossRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: StatBox(
                label: 'AVG COMBAT SCORE',
                value: '${overview.avgCombatScore}',
                subtitle: 'ACS / Round',
                valueColor: AppColors.cyan,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatBox(
                label: 'HEADSHOT %',
                value: '${overview.avgHeadshotPct.toStringAsFixed(0)}%',
                subtitle: '${overview.totalMatches} Matches',
                valueColor: AppColors.vpGold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchCard(MatchSummary match) {
    final isWon = match.won ?? false;
    final isDraw = match.isDraw;
    final outcomeColor = isDraw
        ? AppColors.drawAmber
        : (isWon ? AppColors.winGreen : AppColors.lossRed);

    final timeFormat = DateFormat('MMM d, HH:mm').format(match.gameStartTime);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AscendCard(
        onTap: () {
          context.push('/match-detail', extra: match);
        },
        padding: const EdgeInsets.all(AppSpacing.md),
        borderColor: outcomeColor.withValues(alpha: 0.35),
        gradient: isDraw ? null : (isWon ? AppColors.winGradient : AppColors.lossGradient),
        child: Row(
          children: [
            // Agent Avatar with Rank Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                AgentAvatar(
                  imageUrl: match.agentIconUrl,
                  agentName: match.agentName,
                  size: 48,
                  borderColor: outcomeColor,
                ),
                if (match.competitiveTier != null ||
                    (match.rankIconUrl != null && match.rankIconUrl!.isNotEmpty) ||
                    (match.rankName != null && match.rankName!.isNotEmpty))
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
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
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),

            // Match Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        match.resultText,
                        style: AppTextStyles.h4(color: outcomeColor),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '• ${match.scoreDisplay}',
                        style: AppTextStyles.h4(color: AppColors.textPrimary),
                      ),
                      if (match.rankRatingEarned != null || match.competitiveTier != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        ValorantRankIcon(
                          tier: match.competitiveTier,
                          iconUrl: match.rankIconUrl,
                          tierName: match.rankName ?? 'Unrated',
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        if (match.rankRatingEarned != null)
                          Text(
                            match.rankRatingEarned! > 0
                                ? '+${match.rankRatingEarned} RR'
                                : '${match.rankRatingEarned} RR',
                            style: AppTextStyles.caption(
                              color: match.rankRatingEarned! > 0
                                  ? AppColors.winGreen
                                  : AppColors.lossRed,
                            ).copyWith(fontWeight: FontWeight.w700),
                          )
                        else if (match.rankName != null)
                          Text(
                            match.rankName!,
                            style: AppTextStyles.caption(
                              color: AppColors.textSecondary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${match.mapName} • ${match.queueDisplayName}',
                    style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeFormat,
                    style: AppTextStyles.caption(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            // Performance numbers (KDA & ACS)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  match.kdaDisplay,
                  style: AppTextStyles.statValue(color: AppColors.textPrimary, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.averageCombatScore} ACS',
                  style: AppTextStyles.caption(color: AppColors.cyan).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.kdRatio.toStringAsFixed(2)} K/D',
                  style: AppTextStyles.caption(
                    color: match.kdRatio >= 1.0 ? AppColors.winGreen : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncErrorBanner(String error) {
    final isAuth = error.toLowerCase().contains('session') ||
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
        color: AppColors.card,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.lossRed.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.lossRed, size: 20),
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
          TextButton(
            onPressed: isAuth
                ? () async {
                    final reauthResult =
                        await getIt<AuthRepository>().silentReauth();
                    if (reauthResult.isSuccess) {
                      if (context.mounted) {
                        context.read<CareerCubit>().refresh();
                      }
                    } else {
                      if (context.mounted) {
                        context.push('/login');
                      }
                    }
                  }
                : () => context.read<CareerCubit>().refresh(),
            child: Text(
              isAuth ? 'PERBARUI' : 'SYNC',
              style: const TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
