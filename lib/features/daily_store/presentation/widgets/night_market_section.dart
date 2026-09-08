import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';

class NightMarketSection extends StatelessWidget {
  final NightMarket nightMarket;

  const NightMarketSection({super.key, required this.nightMarket});

  Color _parseTierColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFE5B94E);
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFFE5B94E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Night Market Banner Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1F1D36),
                Color(0xFF0F1923),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5B94E).withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE5B94E).withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5B94E).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: Color(0xFFE5B94E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NIGHT.MARKET',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Color(0xFFE5B94E),
                        ),
                      ),
                      Text(
                        'Exclusive limited discounts',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (nightMarket.remainingDurationSeconds > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE5B94E).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    TimezoneHelper.formatDuration(
                      Duration(seconds: nightMarket.remainingDurationSeconds),
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE5B94E),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Grid of 6 Night Market items
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.74,
          ),
          itemCount: nightMarket.offers.length,
          itemBuilder: (context, index) {
            final offer = nightMarket.offers[index];
            final skin = offer.skin;
            final tierColor = _parseTierColor(skin.tierColor);

            return BlocBuilder<WishlistCubit, WishlistState>(
              builder: (context, wishlistState) {
                final isWishlisted = wishlistState is WishlistLoaded &&
                    wishlistState.isInWishlist(skin.uuid);

                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF181B2B),
                        Color(0xFF0F121C),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5B94E).withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE5B94E).withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Card Content
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Discount % tag
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5B94E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '-${offer.discountPercent}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isWishlisted
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 18,
                                    color: isWishlisted
                                        ? AppTheme.valorantRed
                                        : AppTheme.textSecondary,
                                  ),
                                  onPressed: () {
                                    context
                                        .read<WishlistCubit>()
                                        .toggleWishlist(skin);
                                  },
                                ),
                              ],
                            ),

                            // Skin Image
                            Expanded(
                              child: Center(
                                child: skin.displayIcon != null
                                    ? Hero(
                                        tag: 'nm_${skin.uuid}',
                                        child: CachedNetworkImage(
                                          imageUrl: skin.displayIcon!,
                                          fit: BoxFit.contain,
                                          placeholder: (_, __) => const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFFE5B94E),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) =>
                                              const Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 28,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.image_outlined,
                                        size: 32,
                                        color: AppTheme.textSecondary,
                                      ),
                              ),
                            ),

                            // Skin Name & Tier
                            Text(
                              skin.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              skin.tierName ?? 'Exclusive',
                              style: TextStyle(
                                fontSize: 10,
                                color: tierColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Price Row: Strikethrough original and Discounted Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${offer.originalCost} VP',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.monetization_on_outlined,
                                      size: 13,
                                      color: Color(0xFFE5B94E),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${offer.discountedCost} VP',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFE5B94E),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
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
