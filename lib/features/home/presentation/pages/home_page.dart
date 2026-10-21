import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_cubit.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/mission_item.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_state.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_cubit.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_state.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_cubit.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_state.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_state.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/agent_avatar.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/countdown_timer_widget.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/shimmer_loading.dart';
import 'package:valorant_store_tracker/ui/widgets/skin_preview_dialog.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_rail.dart';
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
    context.read<SocialCubit>().loadFriends();
    context.read<LiveMatchCubit>().scanLiveMatch(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.accent,
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
                _buildPageHeader(),
                const SizedBox(height: AppSpacing.md),
                _buildProfileHero(),
                const SizedBox(height: AppSpacing.md),
                _buildStatusRail(),
                const SizedBox(height: AppSpacing.xxl),
                _buildDailyStoreSpotlight(),
                const SizedBox(height: AppSpacing.xxl),
                _buildCareerSnapshot(),
                const SizedBox(height: AppSpacing.xxl),
                _buildMissionsPreview(),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Text(
          'OVERVIEW',
          style: AppTextStyles.sectionLabel(color: AppColors.textMuted),
        ),
        const Spacer(),
        Text(
          DateFormat('EEE, d MMM').format(DateTime.now()).toUpperCase(),
          style: AppTextStyles.statLabel(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildProfileHero() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        if (profileState is ProfileLoading) {
          return const ShimmerBox(height: 220, borderRadius: AppRadius.lg);
        }

        final UserProfile? profile = profileState is ProfileLoaded
            ? profileState.profile
            : null;

        return BlocBuilder<CareerCubit, CareerState>(
          builder: (context, careerState) {
            final career = careerState is CareerLoaded
                ? careerState.overview
                : null;
            final rankName = career?.currentTierName ?? 'Unrated';
            final currentRR = career?.currentRankRating ?? 0;
            final tier = career?.currentTier;
            final tierIcon = career?.currentTierIcon;
            final art = profile?.cardWideArt?.isNotEmpty == true
                ? profile!.cardWideArt
                : profile?.cardLargeArt;
            final matches = career?.matches ?? const <MatchSummary>[];

            return DataPanel(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: AppRadius.roundedLg,
                child: Stack(
                  children: [
                    if (art != null && art.isNotEmpty)
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: art,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.card),
                        ),
                      ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.background.withValues(alpha: 0.42),
                              AppColors.surface.withValues(alpha: 0.94),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIdentityRow(profile),
                          const SizedBox(height: AppSpacing.xl),
                          _buildRankRow(
                            rankName: rankName,
                            currentRR: currentRR,
                            tier: tier,
                            tierIcon: tierIcon,
                            career: career,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildFormTape(matches),
                          const SizedBox(height: AppSpacing.md),
                          _buildWalletStrip(profile),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIdentityRow(UserProfile? profile) {
    final avatar = profile?.cardSmallArt;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (avatar != null && avatar.isNotEmpty)
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: AppRadius.roundedSm,
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.roundedSm,
              child: CachedNetworkImage(imageUrl: avatar, fit: BoxFit.cover),
            ),
          )
        else
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.roundedSm,
              border: Border.all(color: AppColors.border),
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
                      profile?.gameName ?? 'VALORANT AGENT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h3(color: AppColors.textPrimary),
                    ),
                  ),
                  if (profile?.tagLine != null && profile!.tagLine.isNotEmpty)
                    Text(
                      ' #${profile.tagLine}',
                      style: AppTextStyles.mono(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              if (profile?.titleText != null && profile!.titleText!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    profile.titleText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(color: AppColors.accentSoft),
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
              '${profile?.region.toUpperCase() ?? 'AP'} / LVL ${profile?.accountLevel ?? 1}',
              style: AppTextStyles.statLabel(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'ONLINE',
              style: AppTextStyles.statLabel(color: AppColors.accent),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRankRow({
    required String rankName,
    required int currentRR,
    required int? tier,
    required String? tierIcon,
    required CareerOverview? career,
  }) {
    final isPlacement = career?.isPlacement == true;
    final gamesNeeded = career?.gamesNeededForRating;
    final peakTierName = career?.peakTierName;
    final progress = isPlacement ? 0.0 : (currentRR / 100).clamp(0.0, 1.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ValorantRankIcon(
          tier: tier,
          iconUrl: tierIcon,
          tierName: rankName,
          size: 52,
          showGlow: true,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rankName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h2(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    isPlacement ? 'PLACEMENT' : '$currentRR',
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
                  if (isPlacement && gamesNeeded != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '$gamesNeeded LEFT',
                      style: AppTextStyles.statLabel(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
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
            ],
          ),
        ),
        if (peakTierName != null) ...[
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PEAK',
                style: AppTextStyles.statLabel(color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                peakTierName,
                style: AppTextStyles.caption(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFormTape(List<MatchSummary> matches) {
    final recent = matches.take(10).toList().reversed.toList();

    return Row(
      children: [
        Text(
          'FORM',
          style: AppTextStyles.statLabel(color: AppColors.textMuted),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (recent.isEmpty)
          Text(
            'NO MATCHES',
            style: AppTextStyles.statLabel(color: AppColors.textMuted),
          )
        else
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(child: _buildFormBlock(recent[i])),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFormBlock(MatchSummary match) {
    final color = match.isDraw
        ? AppColors.drawAmber
        : (match.won == true ? AppColors.winGreen : AppColors.lossRed);
    final label = match.isDraw ? 'D' : (match.won == true ? 'W' : 'L');

    return Container(
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.mono(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildWalletStrip(UserProfile? profile) {
    final available = profile?.walletAvailable == true;

    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildWalletItem(
              label: 'VP',
              amount: available ? profile!.valorantPoints : null,
              color: AppColors.vpGold,
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.border),
          Expanded(
            child: _buildWalletItem(
              label: 'RP',
              amount: available ? profile!.radianitePoints : null,
              color: AppColors.radianite,
              alignEnd: true,
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.border),
          Expanded(
            child: _buildWalletItem(
              label: 'KC',
              amount: available ? profile!.kingdomCredits : null,
              color: AppColors.accentSoft,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletItem({
    required String label,
    required int? amount,
    required Color color,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.statLabel(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          amount == null ? '--' : NumberFormat('#,###').format(amount),
          style: AppTextStyles.statValue(color: color, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildStatusRail() {
    return DataPanel(
      padding: EdgeInsets.zero,
      tone: PanelTone.surface,
      child: Row(
        children: [
          Expanded(child: _buildLiveStatusCell()),
          Container(width: 1, height: 56, color: AppColors.border),
          Expanded(child: _buildSquadStatusCell()),
        ],
      ),
    );
  }

  Widget _buildLiveStatusCell() {
    return BlocBuilder<LiveMatchCubit, LiveMatchState>(
      builder: (context, state) {
        final isInMatch = state is LiveMatchLoaded && state.matchData.isInMatch;
        return _statusCell(
          label: 'LIVE MATCH',
          value: isInMatch ? 'IN MATCH' : 'STANDBY',
          active: isInMatch,
          onTap: () => context.push('/live-match'),
        );
      },
    );
  }

  Widget _buildSquadStatusCell() {
    return BlocBuilder<SocialCubit, SocialState>(
      builder: (context, state) {
        final playing = state is SocialLoaded ? state.playingCount : 0;
        final total = state is SocialLoaded ? state.totalCount : 0;
        final value = playing > 0
            ? '$playing ONLINE'
            : (total > 0 ? '$total TRACKED' : 'NO FRIENDS');

        return _statusCell(
          label: 'SQUAD',
          value: value,
          active: playing > 0,
          onTap: () => context.push('/social'),
        );
      },
    );
  }

  Widget _statusCell({
    required String label,
    required String value,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.accent.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.statLabel(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (active) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h4(
                            color: active
                                ? AppColors.accent
                                : AppColors.textPrimary,
                          ).copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyStoreSpotlight() {
    return BlocBuilder<StoreCubit, StoreState>(
      builder: (context, state) {
        if (state is StoreLoading) {
          return const ShimmerBox(height: 210, borderRadius: AppRadius.lg);
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
              index: '01',
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
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: skins.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return _buildStoreSkinCard(skins[index]);
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

    return SizedBox(
      width: 146,
      child: DataPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () => SkinPreviewSheet.show(context, skin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    skin.tierName ?? 'SELECT',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.statLabel(color: tierColor),
                  ),
                ),
                VpChip(amount: skin.cost, fontSize: 10, compact: true),
              ],
            ),
            const Spacer(),
            Center(
              child: skin.displayIcon != null && skin.displayIcon!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: skin.displayIcon!,
                      height: 58,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.shield_outlined,
                        size: 38,
                        color: AppColors.textMuted,
                      ),
                    )
                  : const Icon(
                      Icons.shield_outlined,
                      size: 38,
                      color: AppColors.textMuted,
                    ),
            ),
            const Spacer(),
            Text(
              skin.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h4(
                color: AppColors.textPrimary,
              ).copyWith(fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              skin.weaponName ?? 'SKIN',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.statLabel(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerSnapshot() {
    return BlocBuilder<CareerCubit, CareerState>(
      builder: (context, state) {
        if (state is CareerLoading) {
          return const ShimmerBox(height: 190, borderRadius: AppRadius.lg);
        }

        if (state is! CareerLoaded) {
          return const SizedBox.shrink();
        }

        final career = state.overview;
        final lastMatch = career.matches.isNotEmpty
            ? career.matches.first
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              index: '02',
              title: 'CAREER SNAPSHOT',
              actionLabel: 'OPEN TRACKER',
              onActionTap: () => context.go('/tracker'),
            ),
            const SizedBox(height: AppSpacing.sm),
            DataPanel(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  StatRail(
                    items: [
                      StatRailItem(
                        label: 'WIN RATE',
                        value: '${career.winRate.toStringAsFixed(1)}%',
                        subtitle: '${career.totalWins}W ${career.totalLosses}L',
                        valueColor: career.winRate >= 50
                            ? AppColors.winGreen
                            : AppColors.lossRed,
                      ),
                      StatRailItem(
                        label: 'K/D',
                        value: career.avgKdRatio.toStringAsFixed(2),
                        subtitle:
                            '${career.avgHeadshotPct.toStringAsFixed(0)}% HS',
                        valueColor: career.avgKdRatio >= 1
                            ? AppColors.textPrimary
                            : AppColors.lossRed,
                      ),
                      StatRailItem(
                        label: 'AVG ACS',
                        value: '${career.avgCombatScore}',
                        subtitle: '${career.totalMatches} MATCHES',
                      ),
                    ],
                  ),
                  if (lastMatch != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRecentMatchRow(lastMatch),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentMatchRow(MatchSummary match) {
    final outcomeColor = match.isDraw
        ? AppColors.drawAmber
        : (match.won == true ? AppColors.winGreen : AppColors.lossRed);
    final outcome = match.isDraw ? 'D' : (match.won == true ? 'W' : 'L');

    return InkWell(
      onTap: () => context.push('/match-detail', extra: match),
      splashColor: AppColors.accent.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: outcomeColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AgentAvatar(
              imageUrl: match.agentIconUrl,
              agentName: match.agentName,
              size: 38,
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
                      if (match.rankRatingEarned != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          match.rankRatingEarned! > 0
                              ? '+${match.rankRatingEarned} RR'
                              : '${match.rankRatingEarned} RR',
                          style: AppTextStyles.statLabel(
                            color: match.rankRatingEarned! >= 0
                                ? AppColors.winGreen
                                : AppColors.lossRed,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${match.mapName} / ${match.queueDisplayName}',
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
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
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
        final preview = missions.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(index: '03', title: 'DAILY MISSIONS'),
            const SizedBox(height: AppSpacing.sm),
            DataPanel(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < preview.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.border),
                    _buildMissionRow(preview[i]),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMissionRow(MissionItem mission) {
    final progress = mission.progressToComplete > 0
        ? (mission.currentProgress / mission.progressToComplete).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            mission.isCompleted
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: mission.isCompleted ? AppColors.accent : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      mission.isCompleted
                          ? AppColors.accent
                          : AppColors.accentSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '+${mission.xpReward} XP',
            style: AppTextStyles.statLabel(color: AppColors.vpGold),
          ),
        ],
      ),
    );
  }
}
