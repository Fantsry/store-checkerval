import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/mission_item.dart';

class MissionsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<MissionItem> missions;
  final IconData icon;

  const MissionsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.missions,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Center(
          child: Text(
            'All $title completed! Check back next rotation.',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.valorantRed),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: missions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final m = missions[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: m.isCompleted
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          m.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: m.isCompleted
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                            decoration: m.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: m.isCompleted
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                              : const Color(0xFFE5B94E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (m.isCompleted) ...[
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: Color(0xFF4CAF50),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              '+${m.xpReward} XP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: m.isCompleted
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFE5B94E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: m.progressFraction,
                            minHeight: 6,
                            backgroundColor: Colors.black.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              m.isCompleted
                                  ? const Color(0xFF4CAF50)
                                  : AppTheme.valorantRed,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${m.currentProgress} / ${m.progressToComplete}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
