import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_match_data.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_player_info.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_cubit.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_state.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/live_match_hud_header.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/live_player_card.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/custom_tab_bar.dart';
import 'package:valorant_store_tracker/ui/widgets/empty_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';

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
                        child: LiveMatchHudHeader(matchData: state.matchData),
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
