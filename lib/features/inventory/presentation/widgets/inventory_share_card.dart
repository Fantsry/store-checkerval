import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/core/share/share_card_shell.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';

class InventoryShareCard extends StatelessWidget {
  final InventoryOverview overview;
  final String playerName;

  const InventoryShareCard({
    super.key,
    required this.overview,
    this.playerName = '',
  });

  @override
  Widget build(BuildContext context) {
    final tiers = overview.tierBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayName =
        playerName.trim().isEmpty ? 'MY COLLECTION' : playerName.toUpperCase();

    return ShareCardShell(
      eyebrow: 'COLLECTION',
      title: displayName,
      accent: AppColors.vpGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESTIMATED VALUE',
            style: AppTextStyles.statLabel(color: AppColors.textSecondary),
          ),
          Text(
            overview.formattedEstimatedIdr,
            style: AppTextStyles.scoreLarge(color: AppColors.vpGold),
          ),
          Text(
            '${overview.totalVpSpent} VP SPENT',
            style: AppTextStyles.caption(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(width: 44, height: 3, color: AppColors.vpGold),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ShareStat(
                  label: 'TOTAL SKINS',
                  value: '${overview.totalSkinsCount}',
                  color: AppColors.cyan,
                ),
              ),
              Expanded(
                child: _ShareStat(
                  label: 'STORE',
                  value: '${overview.storeSkinsCount}',
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: _ShareStat(
                  label: 'BATTLEPASS',
                  value: '${overview.battlepassSkinsCount}',
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'TOP TIERS',
            style: AppTextStyles.statLabel(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...tiers.take(3).map(
                (tier) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tier.key.toUpperCase(),
                          style: AppTextStyles.caption(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${tier.value} SKINS',
                        style: AppTextStyles.caption(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ShareStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(color: AppColors.textMuted),
        ),
        Text(value, style: AppTextStyles.h3(color: color)),
      ],
    );
  }
}
