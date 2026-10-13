import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'agent_avatar.dart';

class KillFeedItem extends StatelessWidget {
  final MatchRoundKill kill;

  const KillFeedItem({super.key, required this.kill});

  @override
  Widget build(BuildContext context) {
    final isSelfKiller = kill.isKillerSelf;
    final isSelfVictim = kill.isVictimSelf;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSelfKiller
            ? AppColors.cyan.withValues(alpha: 0.12)
            : isSelfVictim
                ? AppColors.lossRed.withValues(alpha: 0.12)
                : AppColors.surface,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(
          color: isSelfKiller
              ? AppColors.cyan.withValues(alpha: 0.4)
              : isSelfVictim
                  ? AppColors.lossRed.withValues(alpha: 0.4)
                  : AppColors.border.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Killer
          AgentAvatar(
            imageUrl: kill.killerAgentIconUrl,
            agentName: kill.killerAgentName,
            size: 26,
            borderColor: isSelfKiller ? AppColors.cyan : AppColors.border,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              kill.killerName.isNotEmpty ? kill.killerName : kill.killerAgentName,
              style: AppTextStyles.bodySmall(
                color: isSelfKiller ? AppColors.cyan : AppColors.textPrimary,
              ).copyWith(
                fontWeight: isSelfKiller ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Elimination icon / weapon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: isSelfKiller
                  ? AppColors.cyan
                  : isSelfVictim
                      ? AppColors.lossRed
                      : AppColors.textMuted,
            ),
          ),

          // Victim
          Expanded(
            child: Text(
              kill.victimName.isNotEmpty ? kill.victimName : kill.victimAgentName,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall(
                color: isSelfVictim ? AppColors.lossRed : AppColors.textSecondary,
              ).copyWith(
                fontWeight: isSelfVictim ? FontWeight.w700 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AgentAvatar(
            imageUrl: kill.victimAgentIconUrl,
            agentName: kill.victimAgentName,
            size: 26,
            borderColor: isSelfVictim ? AppColors.lossRed : AppColors.border,
          ),
        ],
      ),
    );
  }
}
