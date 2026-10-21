import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_cubit.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_state.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/widgets/battlepass_progress_card.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/widgets/missions_section.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/shimmer_loading.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Battlepass',
          style: AppTextStyles.h2(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<BattlepassCubit>().loadBattlepass(forceRefresh: true);
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Refresh battlepass',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<BattlepassCubit, BattlepassState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.card,
              onRefresh: () async {
                await context
                    .read<BattlepassCubit>()
                    .loadBattlepass(forceRefresh: true);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state is BattlepassLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: ShimmerBox(
                          height: 190,
                          borderRadius: AppRadius.lg,
                        ),
                      ),
                    )
                  else if (state is BattlepassError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorStateView(
                        message: state.message,
                        onRetry: () {
                          context
                              .read<BattlepassCubit>()
                              .loadBattlepass(forceRefresh: true);
                        },
                        actionLabel: 'SIGN IN',
                        onAction: () => context.pushNamed('login'),
                      ),
                    )
                  else if (state is BattlepassLoaded) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        child: BattlepassProgressCard(
                          overview: state.overview,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        child: MissionsSection(
                          index: '01',
                          title: 'DAILY CHECKPOINTS',
                          subtitle: 'Resets daily at 00:00 UTC',
                          missions: state.overview.dailyMissions,
                          icon: Icons.today_rounded,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        child: MissionsSection(
                          index: '02',
                          title: 'WEEKLY MISSIONS',
                          subtitle: 'Cumulative act XP',
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
    );
  }
}
