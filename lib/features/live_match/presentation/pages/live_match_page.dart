import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: BlocBuilder<LiveMatchCubit, LiveMatchState>(
            builder: (context, state) {
              return RefreshIndicator(
                color: AppTheme.valorantRed,
                backgroundColor: AppTheme.surfaceDark,
                onRefresh: () async {
                  await context.read<LiveMatchCubit>().scanLiveMatch();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'LIVE RADAR',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(letterSpacing: 2),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.valorantRed,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pre-game & in-match lobby tracker',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  context.read<LiveMatchCubit>().scanLiveMatch();
                                },
                                icon: const Icon(
                                  Icons.radar_rounded,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (state is LiveMatchLoading)
                      SliverFillRemaining(
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
                                        color: AppTheme.valorantRed.withValues(
                                          alpha: 1.0 - _radarController.value,
                                        ),
                                        width: 2 + (_radarController.value * 4),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.radar_rounded,
                                        color: AppTheme.valorantRed,
                                        size: 36,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Scanning Valorant game servers...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Checking pre-game and core-game states',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (state is LiveMatchError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 40,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.valorantRed
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.valorantRed
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.error_outline_rounded,
                                    size: 48,
                                    color: AppTheme.valorantRed,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Radar Scan Failed',
                                  style: TextStyle(
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
                                  style: const TextStyle(
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
                                        context
                                            .read<LiveMatchCubit>()
                                            .scanLiveMatch();
                                      },
                                      icon: const Icon(Icons.radar_rounded),
                                      label: const Text('RETRY SCAN'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          context.pushNamed('login'),
                                      icon: const Icon(Icons.login_rounded),
                                      label: const Text('SIGN IN WITH RIOT'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (state is LiveMatchLoaded) ...[
                      if (!state.matchData.isInMatch)
                        // No Match (In Lobby)
                        SliverFillRemaining(
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
                                      color: AppTheme.surfaceDark,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.sports_esports_outlined,
                                      size: 56,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'No Active Match Detected',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'You are currently not in Agent Select or a Live Match. Join a game in Valorant on PC, then tap below to view live player ranks and agents!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
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
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.05),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 16,
                                          color: AppTheme.textSecondary,
                                        ),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Tip: Riot servers register matches 2–5s after loading starts.',
                                            style: TextStyle(
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
                                      context
                                          .read<LiveMatchCubit>()
                                          .scanLiveMatch();
                                    },
                                    icon: const Icon(Icons.radar_rounded),
                                    label: const Text('SCAN RADAR NOW'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else ...[
                        // Active Match Banner
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.valorantRed
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: state.matchData.mapSplash != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  state.matchData.mapSplash!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.map_rounded,
                                            color: AppTheme.textSecondary,
                                          ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: state.matchData.phase ==
                                                    LiveMatchPhase.preGame
                                                ? const Color(0xFFE5B94E)
                                                    .withValues(alpha: 0.2)
                                                : AppTheme.valorantRed
                                                    .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            state.matchData.phase ==
                                                    LiveMatchPhase.preGame
                                                ? 'AGENT SELECT (PRE-GAME)'
                                                : 'LIVE MATCH (CORE-GAME)',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: state.matchData.phase ==
                                                      LiveMatchPhase.preGame
                                                  ? const Color(0xFFE5B94E)
                                                  : AppTheme.valorantRed,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          state.matchData.mapName.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          state.matchData.modeName,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Blue Team / Allies
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF00E5FF),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.matchData.phase == LiveMatchPhase.preGame
                                      ? 'YOUR TEAM (${state.matchData.blueTeam.length})'
                                      : 'YOUR TEAM / ALLIES (${state.matchData.blueTeam.length})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: Color(0xFF00E5FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: LivePlayerCard(
                                  player: state.matchData.blueTeam[index],
                                  isEnemy: false,
                                ),
                              ),
                              childCount: state.matchData.blueTeam.length,
                            ),
                          ),
                        ),

                        // Red Team / Enemies (if core-game)
                        if (state.matchData.redTeam.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.valorantRed,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ENEMY TEAM (${state.matchData.redTeam.length})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      color: AppTheme.valorantRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: LivePlayerCard(
                                    player: state.matchData.redTeam[index],
                                    isEnemy: true,
                                  ),
                                ),
                                childCount: state.matchData.redTeam.length,
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
      ),
    );
  }
}
