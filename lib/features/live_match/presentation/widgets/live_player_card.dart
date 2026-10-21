import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_player_info.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';

class LivePlayerCard extends StatefulWidget {
  final LivePlayerInfo player;
  final bool isEnemy;

  const LivePlayerCard({super.key, required this.player, this.isEnemy = false});

  @override
  State<LivePlayerCard> createState() => _LivePlayerCardState();
}

class _LivePlayerCardState extends State<LivePlayerCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final isEnemy = widget.isEnemy;
    final isSelf = player.isSelf;
    final accent = isEnemy ? AppColors.lossRed : AppColors.accent;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.roundedLg,
          border: Border.all(
            color: isSelf
                ? AppColors.accent.withValues(alpha: 0.6)
                : AppColors.border,
          ),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.roundedLg,
          child: Stack(
            children: [
              if (player.cardWideArt != null &&
                  player.cardWideArt!.isNotEmpty) ...[
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: player.cardWideArt!,
                    fit: BoxFit.cover,
                    alignment: isEnemy
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: isEnemy
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        end: isEnemy
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        colors: [
                          AppColors.background.withValues(alpha: 0.94),
                          AppColors.background.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              Positioned(
                top: 0,
                bottom: 0,
                left: isEnemy ? null : 0,
                right: isEnemy ? 0 : null,
                child: Container(width: 3, color: accent),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isEnemy ? AppSpacing.md : AppSpacing.md + 3,
                  AppSpacing.sm,
                  isEnemy ? AppSpacing.md + 3 : AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildAgentAvatar(player, accent),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      player.gameName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyMedium(
                                        color: AppColors.textPrimary,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (player.tagLine.isNotEmpty)
                                    Text(
                                      '#${player.tagLine}',
                                      style: AppTextStyles.caption(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  if (isSelf) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'YOU',
                                      style: AppTextStyles.statLabel(
                                        color: AppColors.accent,
                                      ).copyWith(fontSize: 8),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  ValorantRankIcon(
                                    tierName: player.currentRankTierName,
                                    iconUrl: player.rankIcon,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      player.currentRankTierName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '${player.currentRr} RR',
                                    style: AppTextStyles.statLabel(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildOutcomeTape(player.recentMatchOutcomes),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'PEAK ${player.peakRankTierName}',
                                  style: AppTextStyles.caption(
                                    color: AppColors.textMuted,
                                  ).copyWith(fontSize: 9),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _expanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: AppSpacing.xs),
                      _buildStatRow(player),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgentAvatar(LivePlayerInfo player, Color accent) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm - 1),
        child: player.agentIcon != null && player.agentIcon!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: player.agentIcon!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              )
            : const Icon(
                Icons.person_search_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
      ),
    );
  }

  Widget _buildOutcomeTape(List<bool> outcomes) {
    if (outcomes.isEmpty) {
      return Text(
        'NO RECENT',
        style: AppTextStyles.statLabel(
          color: AppColors.textMuted,
        ).copyWith(fontSize: 8),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final won in outcomes.take(5))
          Container(
            width: 13,
            height: 14,
            margin: const EdgeInsets.only(left: 2),
            color: won ? AppColors.winGreen : AppColors.lossRed,
            alignment: Alignment.center,
            child: Text(
              won ? 'W' : 'L',
              style: AppTextStyles.mono(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: AppColors.background,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatRow(LivePlayerInfo player) {
    final win = player.winPercentage;
    final kd = player.kdRatio;
    final acs = player.averageCombatScore;

    return Row(
      children: [
        _StatCell(
          label: 'ACT',
          value: player.lastNActScore?.toString() ?? '—',
          color: AppColors.vpGold,
        ),
        _StatCell(
          label: 'WIN',
          value: win == null ? '—' : '${win.toStringAsFixed(0)}%',
          color: win != null && win >= 50 ? AppColors.accent : null,
        ),
        _StatCell(
          label: 'K/D',
          value: kd == null ? '—' : kd.toStringAsFixed(2),
          color: kd != null && kd >= 1 ? AppColors.accent : null,
        ),
        _StatCell(
          label: 'KAST',
          value: player.kastPercentage == null
              ? '—'
              : '${player.kastPercentage!.toStringAsFixed(0)}%',
        ),
        _StatCell(
          label: 'KDA',
          value: player.kda == null ? '—' : player.kda!.toStringAsFixed(2),
        ),
        _StatCell(
          label: 'ACS',
          value: acs == null ? '—' : acs.toStringAsFixed(0),
          color: AppColors.accent,
        ),
        _StatCell(
          label: 'HS',
          value: player.headshotPercentage == null
              ? '—'
              : '${player.headshotPercentage!.toStringAsFixed(0)}%',
        ),
        _StatCell(
          label: 'ADR',
          value: player.averageDamageRound == null
              ? '—'
              : player.averageDamageRound!.toStringAsFixed(0),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatCell({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.statValue(
                color: value == '—'
                    ? AppColors.textMuted
                    : (color ?? AppColors.textPrimary),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppTextStyles.statLabel(
              color: AppColors.textMuted,
            ).copyWith(fontSize: 7),
          ),
        ],
      ),
    );
  }
}
