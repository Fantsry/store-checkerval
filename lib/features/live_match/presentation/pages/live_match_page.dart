import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_match_data.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_cubit.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_state.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/live_player_card.dart';

class LiveMatchPage extends StatefulWidget {
  const LiveMatchPage({super.key});

  @override
  State<LiveMatchPage> createState() => _LiveMatchPageState();
}

class _LiveMatchPageState extends State<LiveMatchPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

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
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: BlocBuilder<LiveMatchCubit, LiveMatchState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppTheme.accentMagenta,
              backgroundColor: AppTheme.cardDark,
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
                      // ─── HUD Header ────────────────────────────
                      SliverToBoxAdapter(
                        child: _HudHeader(matchData: state.matchData),
                      ),

                      // ─── MY TEAM Section ───────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentMagenta,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'MY TEAM',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppTheme.accentMagenta,
                                ),
                              ),
                              if (state.matchData.playerSide != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  state.matchData.playerSide!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: LivePlayerCard(
                                player:
                                    state.matchData.blueTeam[index],
                                isEnemy: false,
                              ),
                            ),
                            childCount:
                                state.matchData.blueTeam.length,
                          ),
                        ),
                      ),

                      // ─── ENEMY TEAM Section ────────────────────
                      if (state.matchData.redTeam.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentPurple,
                                    borderRadius:
                                        BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ENEMY',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: AppTheme.accentPurple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Defense',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 6),
                                child: LivePlayerCard(
                                  player:
                                      state.matchData.redTeam[index],
                                  isEnemy: true,
                                ),
                              ),
                              childCount:
                                  state.matchData.redTeam.length,
                            ),
                          ),
                        ),
                      ],
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

  // ─── Loading State ──────────────────────────────────────────────

  Widget _buildLoadingState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.accentMagenta.withValues(
                        alpha: 1.0 - _radarController.value,
                      ),
                      width: 2 + (_radarController.value * 4),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.radar_rounded,
                      color: AppTheme.accentMagenta,
                      size: 36,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Scanning Valorant game servers...',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Checking pre-game and core-game states',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error State ────────────────────────────────────────────────

  Widget _buildErrorState(LiveMatchError state) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.loseRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.loseRed.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppTheme.loseRed,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Radar Scan Failed',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<LiveMatchCubit>().scanLiveMatch();
                    },
                    icon: const Icon(Icons.radar_rounded),
                    label: const Text('RETRY SCAN'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.pushNamed('login'),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('SIGN IN WITH RIOT'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Transitioning State ────────────────────────────────────────

  Widget _buildTransitioningState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5B94E).withValues(
                          alpha: 1.0 - _radarController.value,
                        ),
                        width: 2 + (_radarController.value * 4),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sports_esports_rounded,
                        color: Color(0xFFE5B94E),
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Match Starting...',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Agent select has ended! Match is loading on Valorant servers. Radar will auto-connect to live player stats in a few seconds.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE5B94E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFE5B94E)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE5B94E),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Auto-detecting live game...',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE5B94E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<LiveMatchCubit>().scanLiveMatch();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('CHECK NOW'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── In Lobby State ─────────────────────────────────────────────

  Widget _buildInLobbyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.sports_esports_outlined,
                  size: 56,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Active Match Detected',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are currently not in Agent Select or a Live Match. Join a game in Valorant on PC, then tap below to view live player ranks and agents!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tip: Riot servers register matches 2–5s after loading starts.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<LiveMatchCubit>().scanLiveMatch();
                },
                icon: const Icon(Icons.radar_rounded),
                label: const Text('SCAN RADAR NOW'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HUD Header Widget ───────────────────────────────────────────

class _HudHeader extends StatelessWidget {
  final LiveMatchData matchData;

  const _HudHeader({required this.matchData});

  @override
  Widget build(BuildContext context) {
    final isPreGame = matchData.phase == LiveMatchPhase.preGame;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status line: ● In game  Abyss · Competitive · Attack
          Row(
            children: [
              // Animated green dot
              _PulsingDot(
                color: isPreGame
                    ? const Color(0xFFE5B94E)
                    : AppTheme.winGreen,
              ),
              const SizedBox(width: 6),
              Text(
                isPreGame ? 'Agent Select' : 'In game',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isPreGame
                      ? const Color(0xFFE5B94E)
                      : AppTheme.winGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${matchData.mapName} · ${matchData.modeName}${matchData.playerSide != null ? ' · ${matchData.playerSide}' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Score
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${matchData.blueScore}',
                style: AppTheme.scoreBig(color: AppTheme.textPrimary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '–',
                  style: AppTheme.scoreBig(color: AppTheme.textSecondary),
                ),
              ),
              Text(
                '${matchData.redScore}',
                style: AppTheme.scoreBig(color: AppTheme.textPrimary),
              ),
            ],
          ),

          // SCORE label
          Text(
            'SCORE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing Green Dot ────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(
              alpha: 0.5 + (_controller.value * 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}
