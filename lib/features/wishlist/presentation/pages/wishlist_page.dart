import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';

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
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 38,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.accentMagenta,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WISHLIST',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        letterSpacing: 2.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  state is WishlistLoaded
                                      ? '${state.items.length} skins tracked'
                                      : 'TRACKING YOUR DREAM SKINS',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    letterSpacing: 0.8,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (state is WishlistLoaded &&
                                state.items.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    _showClearConfirmation(context);
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppTheme.textMuted,
                                  ),
                                  tooltip: 'Clear Wishlist',
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: IconButton(
                                onPressed: () => context.goNamed('catalog'),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color: AppTheme.accentMagenta,
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
                          color: AppTheme.accentMagenta,
                        ),
                      ),
                    )
                  else if (state is WishlistError)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: AppTheme.valorantRed,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context
                                      .read<WishlistCubit>()
                                      .loadWishlist(forceRefresh: true);
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('RETRY'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (state is WishlistLoaded && state.items.isEmpty)
                    Expanded(
                      child: RefreshIndicator(
                        color: AppTheme.valorantRed,
                        onRefresh: () => context
                            .read<WishlistCubit>()
                            .loadWishlist(forceRefresh: true),
                        child: ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add skins from the catalog to get\nnotified when they appear in your store.',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            context.goNamed('catalog'),
                                        icon: const Icon(Icons.search_rounded),
                                        label: const Text('BROWSE CATALOG'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (state is WishlistLoaded)
                    Expanded(
                      child: RefreshIndicator(
                        color: AppTheme.accentMagenta,
                        backgroundColor: AppTheme.surfaceDark,
                        onRefresh: () => context
                            .read<WishlistCubit>()
                            .loadWishlist(forceRefresh: true),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: state.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
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
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        title: const Text('CLEAR WISHLIST'),
        content: const Text(
          'Are you sure you want to remove all skins from your wishlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentMagenta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
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
          color: AppTheme.accentMagenta.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
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
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isInStoreNow
                  ? AppTheme.accentMagenta
                  : Colors.white.withValues(alpha: 0.08),
              width: isInStoreNow ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (isInStoreNow)
                BoxShadow(
                  color: AppTheme.accentMagenta.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
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
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: item.displayIcon != null
                    ? CachedNetworkImage(
                        imageUrl: item.displayIcon!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accentMagenta,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppTheme.textMuted,
                        ),
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
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentMagenta,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'IN STORE TODAY!',
                          style: TextStyle(
                            fontSize: 8,
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
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on_outlined,
                          size: 13,
                          color: Color(0xFFE5B94E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.cost} VP',
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFE5B94E),
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
                  color: AppTheme.accentMagenta,
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
