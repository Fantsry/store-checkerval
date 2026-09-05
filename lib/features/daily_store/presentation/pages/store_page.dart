import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> with TickerProviderStateMixin {
  late Timer _countdownTimer;
  Duration _timeUntilReset = Duration.zero;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _timeUntilReset = TimezoneHelper.timeUntilReset;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _timeUntilReset = TimezoneHelper.timeUntilReset;
        });
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: BlocBuilder<StoreCubit, StoreState>(
            builder: (context, state) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ─── Header ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DAILY STORE',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(letterSpacing: 2),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your 24-hour rotating offers',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // Wallet balances (if loaded)
                                  if (state is StoreLoaded)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceLight,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppTheme.valorantRed
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.monetization_on_outlined,
                                            size: 15,
                                            color: AppTheme.valorantRed,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${state.wallet.valorantPoints} VP',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Refresh button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      onPressed: () {
                                        context
                                            .read<StoreCubit>()
                                            .fetchStore(forceRefresh: true);
                                      },
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ─── Countdown Timer ─────────────────
                          _CountdownCard(
                            timeRemaining: _timeUntilReset,
                            pulseController: _pulseController,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Store Items Body ────────────────────────
                  if (state is StoreLoading)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _SkinCardPlaceholder(index: index),
                          childCount: 4,
                        ),
                      ),
                    )
                  else if (state is StoreError)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
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
                                    color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => context.pushNamed('login'),
                                    icon: const Icon(Icons.login_rounded),
                                    label: const Text('SIGN IN WITH RIOT'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () {
                                      context.read<StoreCubit>().fetchStore(
                                            forceRefresh: true,
                                          );
                                    },
                                    child: const Text('RETRY'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (state is StoreLoaded) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final skin = state.store.featuredOffers[index];
                            return _SkinCard(skin: skin);
                          },
                          childCount: state.store.featuredOffers.length,
                        ),
                      ),
                    ),

                    // Featured Bundle (if present)
                    if (state.store.bundle != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FEATURED BUNDLE',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(letterSpacing: 1.5),
                              ),
                              const SizedBox(height: 12),
                              _BundleCard(bundle: state.store.bundle!),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Real interactive Skin Card
class _SkinCard extends StatelessWidget {
  final SkinItem skin;

  const _SkinCard({required this.skin});

  Color _parseTierColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF5A9FE2);
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF5A9FE2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _parseTierColor(skin.tierColor);

    return BlocBuilder<WishlistCubit, WishlistState>(
      builder: (context, wishlistState) {
        final isWishlisted = wishlistState is WishlistLoaded &&
            wishlistState.isInWishlist(skin.uuid);

        return GestureDetector(
          onTap: () {
            context.pushNamed('skinDetail', pathParameters: {'skinId': skin.uuid});
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isWishlisted
                    ? AppTheme.valorantRed.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.06),
                width: isWishlisted ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isWishlisted
                      ? AppTheme.valorantRed.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Subtle tier accent light
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tierColor.withValues(alpha: 0.12),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Weapon type badge & Wishlist button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: tierColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: tierColor.withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                skin.weaponName?.toUpperCase() ?? 'VALORANT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: tierColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            // Wishlist Toggle
                            GestureDetector(
                              onTap: () {
                                context.read<WishlistCubit>().toggleWishlist(skin);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isWishlisted
                                      ? AppTheme.valorantRed.withValues(alpha: 0.2)
                                      : AppTheme.surfaceLight.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isWishlisted
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 16,
                                  color: isWishlisted
                                      ? AppTheme.valorantRed
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Skin Image
                        Expanded(
                          child: Center(
                            child: skin.displayIcon != null
                                ? CachedNetworkImage(
                                    imageUrl: skin.displayIcon!,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) =>
                                        const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.surfaceLight,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: AppTheme.textMuted,
                                    ),
                                  )
                                : const Icon(
                                    Icons.sports_esports_rounded,
                                    size: 48,
                                    color: AppTheme.textMuted,
                                  ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Skin Name
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
                        const SizedBox(height: 4),

                        // Price Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: AppTheme.valorantRed,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${skin.cost} VP',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              skin.tierName ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color: tierColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Featured Bundle Card
class _BundleCard extends StatelessWidget {
  final FeaturedBundle bundle;

  const _BundleCard({required this.bundle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bundle.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.valorantRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${bundle.price} VP',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.valorantRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${bundle.items.length} items in collection',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Countdown card showing time until store reset.
class _CountdownCard extends StatelessWidget {
  final Duration timeRemaining;
  final AnimationController pulseController;

  const _CountdownCard({
    required this.timeRemaining,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.valorantRed.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.valorantRed.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.valorantRed.withValues(
                    alpha: 0.1 + (pulseController.value * 0.1),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timer_rounded,
                  color: AppTheme.valorantRed,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store resets in (00:00 UTC)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  TimezoneHelper.formatDuration(timeRemaining),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: AppTheme.valorantRed,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.valorantRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'LIVE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.valorantRed,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for loading
class _SkinCardPlaceholder extends StatelessWidget {
  final int index;
  const _SkinCardPlaceholder({required this.index});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceLight.withValues(alpha: 0.4),
      highlightColor: AppTheme.surfaceColor,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
