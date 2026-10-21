import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_match_data.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_player_info.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_cubit.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_state.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/live_player_card.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/custom_tab_bar.dart';
import 'package:valorant_store_tracker/ui/widgets/empty_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_badge.dart';

class LiveMatchPage extends StatefulWidget {
  const LiveMatchPage({super.key});

  @override
  State<LiveMatchPage> createState() => _LiveMatchPageState();
}

class _LiveMatchPageState extends State<LiveMatchPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  int _mobileTab = 0;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    context.read<LiveMatchCubit>().scanLiveMatch();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Live match',
          style: AppTextStyles.h2(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Scan now',
            onPressed: () {
              context.read<LiveMatchCubit>().scanLiveMatch();
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<LiveMatchCubit, LiveMatchState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.card,
              onRefresh: () async {
                await context.read<LiveMatchCubit>().scanLiveMatch();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state is LiveMatchLoading)
                    _buildLoadingState()
                  else if (state is LiveMatchError)
                    _buildErrorState(state)
                  else if (state is LiveMatchLoaded) ...[
                    if (state.matchData.phase == LiveMatchPhase.transitioning)
                      _buildTransitioningState()
                    else if (!state.matchData.isInMatch)
                      _buildInLobbyState()
                    else ...[
                      SliverToBoxAdapter(
                        child: _buildHudHeader(state.matchData),
                      ),
                      SliverToBoxAdapter(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 720) {
                              return _buildWideLayout(state.matchData);
                            }
                            return _buildMobileLayout(state.matchData);
                          },
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout(LiveMatchData matchData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildTeamSection(
              index: '01',
              title: 'MY TEAM',
              subtitle: matchData.playerSide,
              players: matchData.blueTeam,
              isEnemy: false,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: _buildTeamSection(
              index: '02',
              title: 'ENEMY',
              subtitle: _enemySide(matchData.playerSide),
              players: matchData.redTeam,
              isEnemy: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(LiveMatchData matchData) {
    final hasEnemies = matchData.redTeam.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasEnemies) ...[
            CustomTabBar(
              tabs: [
                'MY TEAM ${matchData.blueTeam.length}',
                'ENEMY ${matchData.redTeam.length}',
                'BOTH',
              ],
              selectedIndex: _mobileTab,
              onTabSelected: (index) {
                setState(() => _mobileTab = index);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_mobileTab == 0 || !hasEnemies)
            _buildTeamSection(
              index: '01',
              title: 'MY TEAM',
              subtitle: matchData.playerSide,
              players: matchData.blueTeam,
              isEnemy: false,
            )
          else if (_mobileTab == 1)
            _buildTeamSection(
              index: '01',
              title: 'ENEMY',
              subtitle: _enemySide(matchData.playerSide),
              players: matchData.redTeam,
              isEnemy: true,
            )
          else ...[
            _buildTeamSection(
              index: '01',
              title: 'MY TEAM',
              subtitle: matchData.playerSide,
              players: matchData.blueTeam,
              isEnemy: false,
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildTeamSection(
              index: '02',
              title: 'ENEMY',
              subtitle: _enemySide(matchData.playerSide),
              players: matchData.redTeam,
              isEnemy: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamSection({
    required String index,
    required String title,
    required String? subtitle,
    required List<LivePlayerInfo> players,
    required bool isEnemy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          index: index,
          title: title,
          subtitle: subtitle ?? (isEnemy ? 'Opponent roster' : 'Your roster'),
          accentColor: isEnemy ? AppColors.lossRed : AppColors.accent,
          trailing: Text(
            '${players.length} PLAYERS',
            style: AppTextStyles.statLabel(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (players.isEmpty)
          DataPanel(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Waiting for player data',
              style: AppTextStyles.caption(color: AppColors.textMuted),
            ),
          )
        else
          for (var i = 0; i < players.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            LivePlayerCard(player: players[i], isEnemy: isEnemy),
          ],
      ],
    );
  }

  Widget _buildHudHeader(LiveMatchData matchData) {
    final isPreGame = matchData.phase == LiveMatchPhase.preGame;
    final hasScore = matchData.blueScore != null && matchData.redScore != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.roundedLg,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              if (matchData.mapSplash != null)
                Positioned.fill(
                  child: Image.network(
                    matchData.mapSplash!,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.background.withValues(alpha: 0.92),
                        AppColors.background.withValues(alpha: 0.72),
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
                    Row(
                      children: [
                        _LiveDot(
                          color: isPreGame
                              ? AppColors.drawAmber
                              : AppColors.accent,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          isPreGame ? 'AGENT SELECT' : 'LIVE',
                          style: AppTextStyles.statLabel(
                            color: isPreGame
                                ? AppColors.drawAmber
                                : AppColors.accent,
                          ),
                        ),
                        const Spacer(),
                        if (matchData.playerSide != null)
                          StatBadge(
                            text: matchData.playerSide!,
                            color: AppColors.accent,
                            outlined: true,
                            fontSize: 9,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      matchData.mapName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h1(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      matchData.modeName,
                      style: AppTextStyles.statLabel(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (hasScore)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _ScoreBlock(
                            label: 'ALLY',
                            score: matchData.blueScore!,
                            color: AppColors.accent,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              '–',
                              style: AppTextStyles.scoreHuge(
                                color: AppColors.textMuted,
                              ).copyWith(fontSize: 40),
                            ),
                          ),
                          _ScoreBlock(
                            label: 'ENEMY',
                            score: matchData.redScore!,
                            color: AppColors.lossRed,
                          ),
                        ],
                      )
                    else
                      Text(
                        isPreGame
                            ? 'Waiting for agents to lock in'
                            : 'Live score pending',
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.textSecondary,
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

  Widget _buildLoadingState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withValues(
                        alpha: 1 - _radarController.value,
                      ),
                      width: 1 + (_radarController.value * 3),
                    ),
                  ),
                  child: const Icon(
                    Icons.radar_rounded,
                    color: AppColors.accent,
                    size: 30,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Scanning for a live match',
              style: AppTextStyles.h3(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Checking pre-game and core-game states',
              style: AppTextStyles.caption(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(LiveMatchError state) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: ErrorStateView(
        message: state.message,
        onRetry: () => context.read<LiveMatchCubit>().scanLiveMatch(),
        actionLabel: 'SIGN IN',
        onAction: () => context.pushNamed('login'),
      ),
    );
  }

  Widget _buildTransitioningState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: DataPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sports_esports_rounded,
                  color: AppColors.drawAmber,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Match starting',
                  style: AppTextStyles.h3(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Agent select has ended. Radar will reconnect to live stats in a few seconds.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.drawAmber,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<LiveMatchCubit>().scanLiveMatch();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('CHECK NOW'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInLobbyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: EmptyStateView(
        icon: Icons.sports_esports_outlined,
        title: 'No active match detected',
        description:
            'Join Agent Select or a live game in Valorant on PC, then scan again.',
        buttonText: 'SCAN NOW',
        onButtonPressed: () {
          context.read<LiveMatchCubit>().scanLiveMatch();
        },
      ),
    );
  }

  String? _enemySide(String? allySide) {
    if (allySide == 'Attack') return 'Defense';
    if (allySide == 'Defense') return 'Attack';
    return null;
  }
}

class _ScoreBlock extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _ScoreBlock({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.statLabel(color: color)),
        Text(
          '$score',
          style: AppTextStyles.scoreHuge(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _LiveDot extends StatefulWidget {
  final Color color;

  const _LiveDot({required this.color});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(
              alpha: 0.45 + (_controller.value * 0.55),
            ),
          ),
        );
      },
    );
  }
}
