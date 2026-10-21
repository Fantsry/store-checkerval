import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_match_data.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/player_banner.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_badge.dart';

class LiveMatchHudHeader extends StatelessWidget {
  final LiveMatchData matchData;

  const LiveMatchHudHeader({super.key, required this.matchData});

  @override
  Widget build(BuildContext context) {
    final isPreGame = matchData.phase == LiveMatchPhase.preGame;
    final hasScore = matchData.blueScore != null && matchData.redScore != null;
    final self = [...matchData.blueTeam, ...matchData.redTeam]
        .where((player) => player.isSelf)
        .firstOrNull;
    final selfArt = resolveBannerArtUrl(
      wideArt: self?.cardWideArt,
      largeArt: self?.cardLargeArt,
      smallArt: self?.cardSmallArt,
    );
    final heroArt = selfArt ?? matchData.mapSplash;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.roundedLg,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: PlayerBannerArt(
                  wideArt: heroArt,
                  showFallbackIcon: heroArt == null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _LiveDot(
                          color: isPreGame
                              ? AppColors.drawAmber
                              : AppColors.accent,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          isPreGame ? 'AGENT SELECT' : 'LIVE',
                          style: AppTextStyles.statLabel(
                            color: isPreGame
                                ? AppColors.drawAmber
                                : AppColors.accent,
                          ),
                        ),
                        const Spacer(),
                        if (matchData.playerSide != null)
                          StatBadge(
                            text: matchData.playerSide!,
                            color: AppColors.accent,
                            outlined: true,
                            fontSize: 9,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      matchData.mapName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h1(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      matchData.modeName,
                      style: AppTextStyles.statLabel(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (hasScore)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _ScoreBlock(
                            label: 'ALLY',
                            score: matchData.blueScore!,
                            color: AppColors.accent,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              '–',
                              style: AppTextStyles.scoreHuge(
                                color: AppColors.textMuted,
                              ).copyWith(fontSize: 40),
                            ),
                          ),
                          _ScoreBlock(
                            label: 'ENEMY',
                            score: matchData.redScore!,
                            color: AppColors.lossRed,
                          ),
                        ],
                      )
                    else
                      Text(
                        isPreGame
                            ? 'Waiting for agents to lock in'
                            : 'Live score pending',
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _ScoreBlock({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.statLabel(color: color)),
        Text(
          '$score',
          style: AppTextStyles.scoreHuge(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _LiveDot extends StatefulWidget {
  final Color color;

  const _LiveDot({required this.color});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(
              alpha: 0.45 + (_controller.value * 0.55),
            ),
          ),
        );
      },
    );
  }
}
