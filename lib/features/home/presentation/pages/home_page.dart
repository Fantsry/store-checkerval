import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_cubit.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_state.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_cubit.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_state.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_cubit.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_state.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/agent_avatar.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/countdown_timer_widget.dart';
import 'package:valorant_store_tracker/ui/widgets/rank_badge.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/shimmer_loading.dart';
import 'package:valorant_store_tracker/ui/widgets/skin_preview_dialog.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_badge.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_box.dart';
import 'package:valorant_store_tracker/ui/widgets/vp_chip.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    context.read<ProfileCubit>().loadProfile();
    context.read<StoreCubit>().fetchStore();
    context.read<CareerCubit>().loadCareer();
    context.read<BattlepassCubit>().loadBattlepass();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.red,
          backgroundColor: AppColors.card,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHero(),
                const SizedBox(height: AppSpacing.xl),
                _buildLiveMatchBanner(),
                const SizedBox(height: AppSpacing.xl),
                _buildDailyStoreSpotlight(),
                const SizedBox(height: AppSpacing.xl),
                _buildRecentFormAndMatch(),
                const SizedBox(height: AppSpacing.xl),
                _buildMissionsPreview(),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHero() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        if (profileState is ProfileLoading) {
          return const ShimmerBox(height: 180, borderRadius: AppRadius.xl);
        }

        final UserProfile? profile =
            profileState is ProfileLoaded ? profileState.profile : null;

        return BlocBuilder<CareerCubit, CareerState>(
          builder: (context, careerState) {
            final career = careerState is CareerLoaded ? careerState.overview : null;
            final rankName = career?.currentTierName ?? 'Unrated';
            final currentRR = career?.currentRankRating ?? 0;
            final tier = career?.currentTier;
            final tierIcon = career?.currentTierIcon;

            return AscendCard(
              padding: EdgeInsets.zero,
              borderRadius: AppRadius.xl,
              child: Stack(
                children: [
                  // Wide Art Background
                  if (profile?.cardWideArt != null && profile!.cardWideArt!.isNotEmpty)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: AppRadius.roundedXl,
                        child: ShaderMask(
                          shaderCallback: (rect) => LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.card.withValues(alpha: 0.95),
                            ],
                          ).createShader(rect),
                          blendMode: BlendMode.darken,
                          child: CachedNetworkImage(
                            imageUrl: profile.cardWideArt!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  // Overlay Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.roundedXl,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.background.withValues(alpha: 0.5),
                            AppColors.card.withValues(alpha: 0.92),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: ID, Level, Region
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Small Player Card Avatar
                            if (profile?.cardSmallArt != null)
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.roundedMd,
                                  border: Border.all(color: AppColors.border, width: 1.5),
                                ),
                                child: ClipRRect(
                                  borderRadius: AppRadius.roundedMd,
                                  child: CachedNetworkImage(
                                    imageUrl: profile!.cardSmallArt!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          profile?.gameName.toUpperCase() ?? 'VALORANT AGENT',
                                          style: AppTextStyles.h3(color: AppColors.textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (profile?.tagLine != null && profile!.tagLine.isNotEmpty)
                                        Text(
                                          ' #${profile.tagLine}',
                                          style: AppTextStyles.h4(color: AppColors.textSecondary),
                                        ),
                                    ],
                                  ),
                                  if (profile?.titleText != null && profile!.titleText!.isNotEmpty)
                                    Text(
                                      profile.titleText!.toUpperCase(),
                                      style: AppTextStyles.caption(color: AppColors.cyan),
                                    ),
                                ],
                              ),
                            ),
                            // Region & Level Pill
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                StatBadge(
                                  text: profile?.region.toUpperCase() ?? 'AP',
                                  color: AppColors.cyan,
                                  outlined: true,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'LVL ${profile?.accountLevel ?? 1}',
                                  style: AppTextStyles.statLabel(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Middle row: Rank badge + RR progress
                        RankBadge(
                          tierName: rankName,
                          rankedRating: currentRR,
                          tier: tier,
                          iconUrl: tierIcon,
                          iconSize: 42,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Bottom row: Wallet balances (VP, RP, KC)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.8),
                            borderRadius: AppRadius.roundedMd,
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildWalletItem(
                                icon: Icons.monetization_on_outlined,
                                color: AppColors.vpGold,
                                label: 'VP',
                                amount: profile?.valorantPoints ?? 0,
                              ),
                              Container(width: 1, height: 24, color: AppColors.border),
                              _buildWalletItem(
                                icon: Icons.hexagon_outlined,
                                color: AppColors.radianite,
                                label: 'RP',
                                amount: profile?.radianitePoints ?? 0,
                              ),
                              Container(width: 1, height: 24, color: AppColors.border),
                              _buildWalletItem(
                                icon: Icons.token_outlined,
                                color: AppColors.cyan,
                                label: 'KC',
                                amount: profile?.kingdomCredits ?? 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWalletItem({
    required IconData icon,
    required Color color,
    required String label,
    required int amount,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$amount',
          style: AppTextStyles.statValue(color: color, fontSize: 14),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.caption(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildLiveMatchBanner() {
    return BlocBuilder<LiveMatchCubit, LiveMatchState>(
      builder: (context, state) {
        final isInMatch = state is LiveMatchLoaded && state.matchData.isInMatch;

        return AscendCard(
          onTap: () => context.push('/live-match'),
          hasGlow: isInMatch,
          glowColor: AppColors.red,
          borderColor: isInMatch ? AppColors.red : AppColors.border,
          gradient: isInMatch
              ? const LinearGradient(
                  colors: [Color(0x33FF4655), Color(0x11FF4655)],
                )
              : null,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (isInMatch ? AppColors.red : AppColors.cyan).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isInMatch ? Icons.radar_rounded : Icons.track_changes_rounded,
                  color: isInMatch ? AppColors.red : AppColors.cyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isInMatch ? 'ACTIVE LIVE MATCH' : 'LIVE MATCH TRACKER',
                          style: AppTextStyles.h4(
                            color: isInMatch ? AppColors.red : AppColors.textPrimary,
                          ),
                        ),
                        if (isInMatch) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isInMatch
                          ? 'Track live players, ACS, KAST% & winrates'
                          : 'Scan real-time pregame & live match lobbies',
                      style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyStoreSpotlight() {
    return BlocBuilder<StoreCubit, StoreState>(
      builder: (context, state) {
        if (state is StoreLoading) {
          return const ShimmerBox(height: 220, borderRadius: AppRadius.xl);
        }

        if (state is! StoreLoaded) {
          return const SizedBox.shrink();
        }

        final store = state.store;
        final skins = store.featuredOffers;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'DAILY ROTATION',
              actionLabel: 'VIEW STORE',
              onActionTap: () => context.go('/store'),
              trailing: CountdownTimerWidget(
                initialRemainingSeconds: store.remainingDurationSeconds,
                compact: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: skins.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final skin = skins[index];
                  return _buildStoreSkinCard(skin);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStoreSkinCard(SkinItem skin) {
    final tierColor = AppColors.getTierColor(skin.tierName);

    return GestureDetector(
      onTap: () => SkinPreviewSheet.show(context, skin),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.roundedLg,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: tierColor.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (skin.tierName != null)
                  StatBadge(
                    text: skin.tierName!,
                    color: tierColor,
                    fontSize: 8,
                  ),
                VpChip(amount: skin.cost, fontSize: 11, compact: true),
              ],
            ),
            const Spacer(),
            Center(
              child: skin.displayIcon != null && skin.displayIcon!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: skin.displayIcon!,
                      height: 60,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.shield_outlined,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                    )
                  : const Icon(
                      Icons.shield_outlined,
                      size: 40,
                      color: AppColors.textMuted,
                    ),
            ),
            const Spacer(),
            Text(
              skin.displayName.toUpperCase(),
              style: AppTextStyles.h4(color: AppColors.textPrimary).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (skin.weaponName != null)
              Text(
                skin.weaponName!.toUpperCase(),
                style: AppTextStyles.caption(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFormAndMatch() {
    return BlocBuilder<CareerCubit, CareerState>(
      builder: (context, state) {
        if (state is CareerLoading) {
          return const ShimmerBox(height: 180, borderRadius: AppRadius.xl);
        }

        if (state is! CareerLoaded) {
          return const SizedBox.shrink();
        }

        final career = state.overview;
        final lastMatch = career.matches.isNotEmpty ? career.matches.first : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'CAREER OVERVIEW',
              actionLabel: 'VIEW ALL',
              onActionTap: () => context.go('/tracker'),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Quick 3 stats row
            Row(
              children: [
                Expanded(
                  child: StatBox(
                    label: 'WIN RATE',
                    value: '${career.winRate.toStringAsFixed(1)}%',
                    subtitle: '${career.totalWins}W / ${career.totalLosses}L',
                    valueColor: career.winRate >= 50 ? AppColors.winGreen : AppColors.lossRed,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatBox(
                    label: 'AVG ACS',
                    value: '${career.avgCombatScore}',
                    subtitle: 'Score / Round',
                    valueColor: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatBox(
                    label: 'AVG K/D',
                    value: career.avgKdRatio.toStringAsFixed(2),
                    subtitle: '${career.avgHeadshotPct.toStringAsFixed(0)}% HS',
                    valueColor: career.avgKdRatio >= 1.0 ? AppColors.winGreen : AppColors.lossRed,
                  ),
                ),
              ],
            ),
            if (lastMatch != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildRecentMatchCard(lastMatch),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRecentMatchCard(MatchSummary match) {
    final isWon = match.won ?? false;
    final isDraw = match.isDraw;
    final outcomeColor = isDraw
        ? AppColors.drawAmber
        : isWon
            ? AppColors.winGreen
            : AppColors.lossRed;

    return AscendCard(
      onTap: () {
        context.push('/match-detail', extra: match);
      },
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: isDraw
          ? null
          : (isWon ? AppColors.winGradient : AppColors.lossGradient),
      borderColor: outcomeColor.withValues(alpha: 0.35),
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
                          ).copyWith(fontWeight: FontWeight.w600),
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
              ],
            ),
          ),
          // KDA & ACS
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
                style: AppTextStyles.caption(color: AppColors.cyan),
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
    );
  }

  Widget _buildMissionsPreview() {
    return BlocBuilder<BattlepassCubit, BattlepassState>(
      builder: (context, state) {
        if (state is! BattlepassLoaded) {
          return const SizedBox.shrink();
        }

        final missions = state.overview.dailyMissions;
        if (missions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'DAILY MISSIONS',
              subtitle: 'Active XP Challenges',
            ),
            const SizedBox(height: AppSpacing.sm),
            ...missions.take(3).map((m) {
              final progress = m.progressToComplete > 0
                  ? (m.currentProgress / m.progressToComplete).clamp(0.0, 1.0)
                  : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Icon(
                      m.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: m.isCompleted ? AppColors.winGreen : AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.title,
                            style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: AppRadius.roundedPill,
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.card,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                m.isCompleted ? AppColors.winGreen : AppColors.cyan,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '+${m.xpReward} XP',
                      style: AppTextStyles.statLabel(color: AppColors.vpGold),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
