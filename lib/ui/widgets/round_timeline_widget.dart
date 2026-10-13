import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class RoundTimelineWidget extends StatelessWidget {
  final List<MatchRoundSummary> rounds;
  final int selectedRoundIndex;
  final ValueChanged<int> onRoundSelected;

  const RoundTimelineWidget({
    super.key,
    required this.rounds,
    required this.selectedRoundIndex,
    required this.onRoundSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rounds.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final round = rounds[index];
          final isSelected = index == selectedRoundIndex;
          final isWon = round.won ?? false;
          final color = isWon ? AppColors.winGreen : AppColors.lossRed;

          return GestureDetector(
            onTap: () => onRoundSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.25)
                    : AppColors.surface,
                borderRadius: AppRadius.roundedSm,
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${round.roundNum}',
                    style: AppTextStyles.statValue(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
