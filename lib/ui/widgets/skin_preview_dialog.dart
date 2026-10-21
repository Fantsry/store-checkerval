import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'stat_badge.dart';
import 'vp_chip.dart';

class SkinPreviewSheet extends StatefulWidget {
  final SkinItem skin;

  const SkinPreviewSheet({super.key, required this.skin});

  static Future<void> show(BuildContext context, SkinItem skin) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SkinPreviewSheet(skin: skin),
    );
  }

  @override
  State<SkinPreviewSheet> createState() => _SkinPreviewSheetState();
}

class _SkinPreviewSheetState extends State<SkinPreviewSheet> {
  int _selectedChromaIndex = 0;

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    final tierColor = AppColors.getTierColor(skin.tierName);

    String? currentImage = skin.displayIcon;
    if (skin.chromas.isNotEmpty &&
        _selectedChromaIndex < skin.chromas.length &&
        skin.chromas[_selectedChromaIndex].fullRender != null) {
      currentImage = skin.chromas[_selectedChromaIndex].fullRender;
    } else if (skin.chromas.isNotEmpty &&
        _selectedChromaIndex < skin.chromas.length &&
        skin.chromas[_selectedChromaIndex].displayIcon != null) {
      currentImage = skin.chromas[_selectedChromaIndex].displayIcon;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.5),
          left: BorderSide(color: AppColors.border, width: 1),
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.roundedPill,
              ),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Category / Tier Badge & Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (skin.tierName != null) ...[
                            StatBadge(
                              text: skin.tierName!,
                              color: tierColor,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          if (skin.weaponName != null)
                            Text(
                              skin.weaponName!.toUpperCase(),
                              style: AppTextStyles.statLabel(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Skin Name Title
                  Text(
                    skin.displayName.toUpperCase(),
                    style: AppTextStyles.h2(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Large Preview Stage with Ambient Glow
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: AppRadius.roundedXl,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: currentImage != null && currentImage.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: CachedNetworkImage(
                                imageUrl: currentImage,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.broken_image_rounded,
                                  size: 48,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : const Icon(Icons.shield_outlined, size: 64, color: AppColors.textMuted),
                    ),
                  ),

                  // Chroma selector if multiple exist
                  if (skin.chromas.length > 1) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'COLOR VARIANTS (${skin.chromas.length})',
                      style: AppTextStyles.statLabel(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 52,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: skin.chromas.length,
                        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final chroma = skin.chromas[index];
                          final isSelected = index == _selectedChromaIndex;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedChromaIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(4),
                              width: 52,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.cardElevated : AppColors.card,
                                borderRadius: AppRadius.roundedMd,
                                border: Border.all(
                                  color: isSelected ? AppColors.accent : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: chroma.displayIcon != null
                                  ? CachedNetworkImage(
                                      imageUrl: chroma.displayIcon!,
                                      fit: BoxFit.contain,
                                    )
                                  : Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: AppTextStyles.statValue(
                                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Upgrade Levels if any
                  if (skin.levels.length > 1) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'LEVEL PROGRESSION (${skin.levels.length} LEVELS)',
                      style: AppTextStyles.statLabel(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Column(
                      children: skin.levels.map((lvl) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: AppRadius.roundedSm,
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.accentSoft),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  lvl.displayName,
                                  style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
                                ),
                              ),
                              if (lvl.levelItem != null)
                                Text(
                                  lvl.levelItem!,
                                  style: AppTextStyles.caption(color: AppColors.accentSoft),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Bottom Action Section: Price & Wishlist Button
                  Row(
                    children: [
                      VpChip(amount: skin.cost, fontSize: 16),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: BlocBuilder<WishlistCubit, WishlistState>(
                          builder: (context, state) {
                            final inWishlist = state is WishlistLoaded && state.isInWishlist(skin.uuid);
                            return ElevatedButton.icon(
                              onPressed: () {
                                context.read<WishlistCubit>().toggleWishlist(skin);
                              },
                              icon: Icon(
                                inWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: AppColors.onAccent,
                                size: 18,
                              ),
                              label: Text(
                                inWishlist ? 'WISHLISTED' : 'ADD TO WISHLIST',
                                style: AppTextStyles.statValue(color: AppColors.onAccent, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: inWishlist ? AppColors.accentStrong : AppColors.accent,
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
