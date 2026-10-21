import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/empty_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    final state = context.read<WishlistCubit>().state;
    if (state is WishlistInitial) {
      context.read<WishlistCubit>().loadWishlist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Wishlist',
          style: AppTextStyles.h2(color: AppColors.textPrimary),
        ),
        actions: [
          BlocBuilder<WishlistCubit, WishlistState>(
            builder: (context, state) {
              final hasItems =
                  state is WishlistLoaded && state.items.isNotEmpty;
              return Row(
                children: [
                  if (hasItems)
                    IconButton(
                      onPressed: () => _showClearConfirmation(context),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: 'Clear wishlist',
                    ),
                  IconButton(
                    onPressed: () => context.goNamed('catalog'),
                    icon: const Icon(
                      Icons.add_rounded,
                      color: AppColors.accent,
                    ),
                    tooltip: 'Browse catalog',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<WishlistCubit, WishlistState>(
          builder: (context, state) {
            final storeState = context.watch<StoreCubit>().state;
            final currentStoreUuids = <String>{};
            final nightMarketUuids = <String>{};

            if (storeState is StoreLoaded) {
              for (final skin in storeState.store.featuredOffers) {
                currentStoreUuids.add(skin.uuid.toLowerCase());
              }
              for (final item
                  in storeState.store.nightMarket?.offers ?? const []) {
                nightMarketUuids.add(item.skin.uuid.toLowerCase());
              }
            }

            if (state is WishlistLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }

            if (state is WishlistError) {
              return ErrorStateView(
                message: state.message,
                onRetry: () => context.read<WishlistCubit>().loadWishlist(
                  forceRefresh: true,
                ),
              );
            }

            if (state is WishlistLoaded && state.items.isEmpty) {
              return RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.card,
                onRefresh: () => context.read<WishlistCubit>().loadWishlist(
                  forceRefresh: true,
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: EmptyStateView(
                        icon: Icons.favorite_border_rounded,
                        title: 'No Skins in Wishlist',
                        description:
                            'Add skins from the catalog to get notified when they appear in your store.',
                        buttonText: 'BROWSE CATALOG',
                        onButtonPressed: () => context.goNamed('catalog'),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is! WishlistLoaded) {
              return const SizedBox.shrink();
            }

            final inStoreCount = state.items
                .where((i) => currentStoreUuids.contains(i.uuid.toLowerCase()))
                .length;
            final nightMarketCount = state.items
                .where((i) => nightMarketUuids.contains(i.uuid.toLowerCase()))
                .length;

            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.card,
              onRefresh: () => context.read<WishlistCubit>().loadWishlist(
                forceRefresh: true,
              ),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  _buildSummary(
                    state.items.length,
                    inStoreCount,
                    nightMarketCount,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (var i = 0; i < state.items.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    _WishlistItemCard(
                      item: state.items[i],
                      isInStoreNow: currentStoreUuids.contains(
                        state.items[i].uuid.toLowerCase(),
                      ),
                      isInNightMarket: nightMarketUuids.contains(
                        state.items[i].uuid.toLowerCase(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummary(int total, int inStore, int nightMarket) {
    return DataPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: _summaryCell('TRACKED', '$total')),
          Container(width: 1, height: 30, color: AppColors.border),
          Expanded(
            child: _summaryCell(
              'IN STORE',
              '$inStore',
              color: inStore > 0 ? AppColors.accent : null,
              alignEnd: true,
            ),
          ),
          Container(width: 1, height: 30, color: AppColors.border),
          Expanded(
            child: _summaryCell(
              'NIGHT MARKET',
              '$nightMarket',
              color: nightMarket > 0 ? AppColors.drawAmber : null,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(
    String label,
    String value, {
    Color? color,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.statLabel(color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.statValue(
            color: color ?? AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedLg,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Clear wishlist',
          style: AppTextStyles.h3(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove all skins from your wishlist?',
          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: AppTextStyles.statLabel(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lossRed,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<WishlistCubit>().clearAll();
            },
            child: Text(
              'CLEAR ALL',
              style: AppTextStyles.statValue(
                color: AppColors.background,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistItemCard extends StatelessWidget {
  final WishlistItem item;
  final bool isInStoreNow;
  final bool isInNightMarket;

  const _WishlistItemCard({
    required this.item,
    required this.isInStoreNow,
    this.isInNightMarket = false,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = AppColors.getTierColor(item.tierName);

    return Dismissible(
      key: Key(item.uuid),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.lossRed.withValues(alpha: 0.85),
          borderRadius: AppRadius.roundedLg,
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.background),
      ),
      onDismissed: (_) {
        context.read<WishlistCubit>().toggleWishlist(item.toSkinItem());
      },
      child: DataPanel(
        padding: const EdgeInsets.all(AppSpacing.sm),
        onTap: () {
          context.pushNamed(
            'skinDetail',
            pathParameters: {'skinId': item.uuid},
          );
        },
        child: Row(
          children: [
            Container(
              width: 72,
              height: 56,
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
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    )
                  : const Icon(
                      Icons.sports_esports_outlined,
                      size: 22,
                      color: AppColors.textMuted,
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h4(color: AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        item.cost > 0 ? '${item.cost} VP' : '-- VP',
                        style: AppTextStyles.statValue(
                          color: AppColors.vpGold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        (item.weaponName ?? 'SKIN').toUpperCase(),
                        style: AppTextStyles.statLabel(color: tierColor),
                      ),
                      if (item.tierName != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(width: 1, height: 8, color: AppColors.border),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            item.tierName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.statLabel(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isInStoreNow || isInNightMarket) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 2,
                      children: [
                        if (isInStoreNow)
                          const _StatusTag(
                            label: 'IN STORE',
                            color: AppColors.accent,
                          ),
                        if (isInNightMarket)
                          const _StatusTag(
                            label: 'NIGHT MARKET',
                            color: AppColors.drawAmber,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context.read<WishlistCubit>().toggleWishlist(
                item.toSkinItem(),
              ),
              icon: const Icon(
                Icons.favorite_rounded,
                color: AppColors.accent,
                size: 18,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.statLabel(color: color)),
      ],
    );
  }
}
