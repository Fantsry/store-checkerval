import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_cubit.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_state.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/match_card.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/rank_overview_card.dart';

class CareerPage extends StatefulWidget {
  const CareerPage({super.key});

  @override
  State<CareerPage> createState() => _CareerPageState();
}

class _CareerPageState extends State<CareerPage> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<CareerCubit>();
    if (cubit.state is CareerInitial) {
      cubit.loadCareer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 8,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.valorantRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'CAREER & TRACKER',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<CareerCubit, CareerState>(
            builder: (context, state) {
              final isLoading = state is CareerLoading;
              return IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.valorantRed,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.textPrimary,
                      ),
                onPressed: isLoading
                    ? null
                    : () => context.read<CareerCubit>().refresh(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CareerCubit, CareerState>(
        builder: (context, state) {
          if (state is CareerLoading && state.cachedOverview == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.valorantRed),
                  SizedBox(height: 16),
                  Text(
                    'Loading career & match stats...',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (state is CareerError && state.cachedOverview == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppTheme.valorantRed,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.valorantRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => context.read<CareerCubit>().loadCareer(forceRefresh: true),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final overview = switch (state) {
            CareerLoaded(:final overview) => overview,
            CareerLoading(:final cachedOverview) => cachedOverview,
            CareerError(:final cachedOverview) => cachedOverview,
            _ => null,
          };

          if (overview == null) {
            return const SizedBox.shrink();
          }

          final currentFilter = state is CareerLoaded
              ? state.selectedQueueFilter
              : 'all';

          final matches = state is CareerLoaded
              ? state.filteredMatches
              : overview.matches;

          return RefreshIndicator(
            color: AppTheme.valorantRed,
            backgroundColor: AppTheme.surfaceDark,
            onRefresh: () => context.read<CareerCubit>().refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const SizedBox(height: 8),

                // Rank & Overview Card
                RankOverviewCard(overview: overview),

                const SizedBox(height: 8),

                // Match History Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MATCH HISTORY',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${matches.length} Matches',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All Modes',
                        isSelected: currentFilter == 'all',
                        onTap: () => context.read<CareerCubit>().filterQueue('all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Competitive',
                        isSelected: currentFilter == 'competitive',
                        onTap: () => context.read<CareerCubit>().filterQueue('competitive'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Unrated',
                        isSelected: currentFilter == 'unrated',
                        onTap: () => context.read<CareerCubit>().filterQueue('unrated'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Deathmatch',
                        isSelected: currentFilter == 'deathmatch',
                        onTap: () => context.read<CareerCubit>().filterQueue('deathmatch'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Spike Rush',
                        isSelected: currentFilter == 'spikerush',
                        onTap: () => context.read<CareerCubit>().filterQueue('spikerush'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Match List or Empty State
                if (matches.isEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.sports_esports_outlined,
                          color: AppTheme.textMuted,
                          size: 40,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No matches found for this filter',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Play more matches or select another mode above.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...matches.map((match) => MatchCard(match: match)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.valorantRed
              : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.valorantRed
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
