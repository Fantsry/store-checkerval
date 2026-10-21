import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';

class NightMarketSection extends StatelessWidget {
  final NightMarket nightMarket;
  final String? index;

  const NightMarketSection({super.key, required this.nightMarket, this.index});

  Color _parseTierColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.drawAmber;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.drawAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          index: index,
          title: 'NIGHT MARKET',
          subtitle: 'Exclusive limited discounts',
          trailing: nightMarket.remainingDurationSeconds > 0
              ? Text(
                  TimezoneHelper.formatDuration(
                    Duration(seconds: nightMarket.remainingDurationSeconds),
                  ),
                  style: AppTextStyles.statLabel(color: AppColors.drawAmber),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.76,
          ),
          itemCount: nightMarket.offers.length,
          itemBuilder: (context, index) {
            final offer = nightMarket.offers[index];
            final skin = offer.skin;
            final tierColor = _parseTierColor(skin.tierColor);

            return BlocBuilder<WishlistCubit, WishlistState>(
              builder: (context, wishlistState) {
                final isWishlisted =
                    wishlistState is WishlistLoaded &&
                    wishlistState.isInWishlist(skin.uuid);

                return DataPanel(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.drawAmber,
                              borderRadius: AppRadius.roundedSm,
                            ),
                            child: Text(
                              '-${offer.discountPercent}%',
                              style: AppTextStyles.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context
                                .read<WishlistCubit>()
                                .toggleWishlist(skin),
                            behavior: HitTestBehavior.opaque,
                            child: Icon(
                              isWishlisted
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: isWishlisted
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child:
                              skin.displayIcon != null &&
                                  skin.displayIcon!.isNotEmpty
                              ? Hero(
                                  tag: 'nm_${skin.uuid}',
                                  child: CachedNetworkImage(
                                    imageUrl: skin.displayIcon!,
                                    fit: BoxFit.contain,
                                    placeholder: (_, __) => const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.drawAmber,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 26,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.image_outlined,
                                  size: 28,
                                  color: AppColors.textMuted,
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        skin.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h4(
                          color: AppColors.textPrimary,
                        ).copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        skin.tierName ?? 'EXCLUSIVE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.statLabel(color: tierColor),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              offer.originalCost > 0
                                  ? '${offer.originalCost} VP'
                                  : '-- VP',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppTextStyles.mono(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                  ).copyWith(
                                    decoration: TextDecoration.lineThrough,
                                  ),
                            ),
                          ),
                          Text(
                            offer.discountedCost > 0
                                ? '${offer.discountedCost} VP'
                                : '-- VP',
                            style: AppTextStyles.statValue(
                              color: AppColors.drawAmber,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
