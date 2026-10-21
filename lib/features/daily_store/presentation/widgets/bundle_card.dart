import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';

class BundleCard extends StatelessWidget {
  final FeaturedBundle bundle;

  const BundleCard({super.key, required this.bundle});

  @override
  Widget build(BuildContext context) {
    final banner = bundle.bannerImageUrl;

    return DataPanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.roundedLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (banner != null && banner.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: banner,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.card,
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.card,
                        child: const Icon(
                          Icons.collections_outlined,
                          color: AppColors.textMuted,
                          size: 36,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.surface.withValues(alpha: 0.9),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.7),
                          borderRadius: AppRadius.roundedSm,
                          border: Border.all(color: AppColors.accent),
                        ),
                        child: Text(
                          'FEATURED COLLECTION',
                          style: AppTextStyles.statLabel(
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    if (bundle.remainingDurationSeconds > 0)
                      Positioned(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.7),
                            borderRadius: AppRadius.roundedSm,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            TimezoneHelper.formatDuration(
                              Duration(
                                seconds: bundle.remainingDurationSeconds,
                              ),
                            ),
                            style: AppTextStyles.statLabel(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bundle.displayName,
                              style: AppTextStyles.h2(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bundle.items.isNotEmpty
                                  ? '${bundle.items.length} items in collection'
                                  : 'Featured store collection',
                              style: AppTextStyles.caption(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        bundle.price > 0 ? '${bundle.price} VP' : '-- VP',
                        style: AppTextStyles.statValue(
                          color: AppColors.accent,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (bundle.items.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: 54,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: bundle.items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = bundle.items[index];
                          return InkWell(
                            onTap: () => _showBundleItemsModal(context),
                            borderRadius: AppRadius.roundedSm,
                            child: Container(
                              width: 78,
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: AppRadius.roundedSm,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: item.displayIcon != null
                                  ? CachedNetworkImage(
                                      imageUrl: item.displayIcon!,
                                      fit: BoxFit.contain,
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 16,
                                        color: AppColors.textMuted,
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        item.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.caption(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => _showBundleItemsModal(context),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'VIEW COLLECTION',
                                style: AppTextStyles.label(
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBundleItemsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 34,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bundle.displayName,
                              style: AppTextStyles.h2(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${bundle.items.length} items included',
                              style: AppTextStyles.caption(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        bundle.price > 0 ? '${bundle.price} VP' : '-- VP',
                        style: AppTextStyles.statValue(
                          color: AppColors.accent,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: bundle.items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final item = bundle.items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: AppRadius.roundedSm,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: item.displayIcon != null
                                    ? CachedNetworkImage(
                                        imageUrl: item.displayIcon!,
                                        fit: BoxFit.contain,
                                      )
                                    : const Icon(
                                        Icons.image_outlined,
                                        size: 18,
                                        color: AppColors.textMuted,
                                      ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyMedium(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (item.tierName != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.tierName!,
                                        style: AppTextStyles.statLabel(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (item.cost > 0)
                                Text(
                                  '${item.cost} VP',
                                  style: AppTextStyles.statValue(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
