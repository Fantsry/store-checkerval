import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: BlocBuilder<WishlistCubit, WishlistState>(
            builder: (context, state) {
              final storeState = context.watch<StoreCubit>().state;
              final currentStoreUuids = <String>{};

              if (storeState is StoreLoaded) {
                for (final skin in storeState.store.featuredOffers) {
                  currentStoreUuids.add(skin.uuid.toLowerCase());
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WISHLIST',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(letterSpacing: 2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state is WishlistLoaded
                                  ? '${state.items.length} skins tracked'
                                  : 'Tracking your dream skins',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (state is WishlistLoaded &&
                                state.items.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  _showClearConfirmation(context);
                                },
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppTheme.textMuted,
                                ),
                                tooltip: 'Clear Wishlist',
                              ),
                            const SizedBox(width: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => context.goNamed('catalog'),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: AppTheme.valorantRed,
                                ),
                                tooltip: 'Browse Catalog',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ─── Content ────────────────────────────────
                  if (state is WishlistLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.valorantRed,
                        ),
                      ),
                    )
                  else if (state is WishlistLoaded && state.items.isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  size: 48,
                                  color: AppTheme.valorantRed
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No Skins in Wishlist',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add skins from the catalog to get\nnotified when they appear in your store.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => context.goNamed('catalog'),
                                icon: const Icon(Icons.search_rounded),
                                label: const Text('BROWSE CATALOG'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (state is WishlistLoaded)
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          final isInStore = currentStoreUuids
                              .contains(item.uuid.toLowerCase());

                          return _WishlistItemCard(
                            item: item,
                            isInStoreNow: isInStore,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Clear Wishlist'),
        content: const Text(
          'Are you sure you want to remove all skins from your wishlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<WishlistCubit>().clearAll();
            },
            child: const Text('CLEAR ALL'),
          ),
        ],
      ),
    );
  }
}

class _WishlistItemCard extends StatelessWidget {
  final WishlistItem item;
  final bool isInStoreNow;

  const _WishlistItemCard({
    required this.item,
    required this.isInStoreNow,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.uuid),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.valorantRed.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) {
        context.read<WishlistCubit>().toggleWishlist(item.toSkinItem());
      },
      child: GestureDetector(
        onTap: () {
          context.pushNamed('skinDetail', pathParameters: {'skinId': item.uuid});
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isInStoreNow
                  ? AppTheme.valorantRed
                  : Colors.white.withValues(alpha: 0.06),
              width: isInStoreNow ? 1.8 : 1.0,
            ),
            boxShadow: [
              if (isInStoreNow)
                BoxShadow(
                  color: AppTheme.valorantRed.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              // Skin Icon
              Container(
                width: 72,
                height: 52,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: item.displayIcon != null
                    ? CachedNetworkImage(
                        imageUrl: item.displayIcon!,
                        fit: BoxFit.contain,
                      )
                    : const Icon(
                        Icons.sports_esports_outlined,
                        color: AppTheme.textMuted,
                      ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isInStoreNow) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.valorantRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '🎯 IN STORE TODAY!',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                    Text(
                      item.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 13,
                          color: AppTheme.valorantRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.cost} VP',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (item.tierName != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•  ${item.tierName}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                onPressed: () {
                  context.read<WishlistCubit>().toggleWishlist(item.toSkinItem());
                },
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: AppTheme.valorantRed,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
