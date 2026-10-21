import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/mission_item.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';

class MissionsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<MissionItem> missions;
  final IconData icon;
  final String? index;

  const MissionsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.missions,
    required this.icon,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          index: index,
          title: title,
          subtitle: subtitle,
          trailing: Icon(icon, size: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (missions.isEmpty)
          DataPanel(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'All missions completed. Check back next rotation.',
              style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
            ),
          )
        else
          DataPanel(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                for (var i = 0; i < missions.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _buildMissionRow(missions[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMissionRow(MissionItem mission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            mission.isCompleted
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: mission.isCompleted
                ? AppColors.accent
                : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mission.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall(
                          color: mission.isCompleted
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ).copyWith(
                          decoration: mission.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '+${mission.xpReward} XP',
                      style: AppTextStyles.statLabel(
                        color: mission.isCompleted
                            ? AppColors.accent
                            : AppColors.vpGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: mission.progressFraction,
                          minHeight: 3,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            mission.isCompleted
                                ? AppColors.accent
                                : AppColors.accentSoft,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${mission.currentProgress} / ${mission.progressToComplete}',
                      style: AppTextStyles.statLabel(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
