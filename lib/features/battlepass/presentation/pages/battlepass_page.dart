import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_cubit.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_state.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/widgets/battlepass_progress_card.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/widgets/missions_section.dart';

class BattlepassPage extends StatefulWidget {
  const BattlepassPage({super.key});

  @override
  State<BattlepassPage> createState() => _BattlepassPageState();
}

class _BattlepassPageState extends State<BattlepassPage> {
  @override
  void initState() {
    super.initState();
    context.read<BattlepassCubit>().loadBattlepass();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: BlocBuilder<BattlepassCubit, BattlepassState>(
            builder: (context, state) {
              return RefreshIndicator(
                color: AppTheme.valorantRed,
                backgroundColor: AppTheme.surfaceDark,
                onRefresh: () async {
                  await context
                      .read<BattlepassCubit>()
                      .loadBattlepass(forceRefresh: true);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BATTLEPASS & MISSIONS',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(letterSpacing: 2),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Act progress & active challenges',
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
                                  context
                                      .read<BattlepassCubit>()
                                      .loadBattlepass(forceRefresh: true);
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (state is BattlepassLoading) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Shimmer.fromColors(
                            baseColor:
                                AppTheme.surfaceLight.withValues(alpha: 0.4),
                            highlightColor: AppTheme.surfaceColor,
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else if (state is BattlepassError) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: AppTheme.valorantRed,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          context.pushNamed('login'),
                                      icon: const Icon(Icons.login_rounded),
                                      label: const Text('SIGN IN WITH RIOT'),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        context
                                            .read<BattlepassCubit>()
                                            .loadBattlepass(forceRefresh: true);
                                      },
                                      child: const Text('RETRY'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else if (state is BattlepassLoaded) ...[
                      // Battlepass Progress Card
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          child: BattlepassProgressCard(
                            overview: state.overview,
                          ),
                        ),
                      ),

                      // Daily Missions
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: MissionsSection(
                            title: 'Daily Checkpoints',
                            subtitle: 'Resets daily at 00:00 UTC',
                            missions: state.overview.dailyMissions,
                            icon: Icons.today_rounded,
                          ),
                        ),
                      ),

                      // Weekly Missions
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: MissionsSection(
                            title: 'Weekly Missions',
                            subtitle: 'Cumulative Act XP',
                            missions: state.overview.weeklyMissions,
                            icon: Icons.calendar_view_week_rounded,
                          ),
                        ),
                      ),
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
