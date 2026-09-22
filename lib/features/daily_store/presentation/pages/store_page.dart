import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/widgets/accessory_store_section.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/widgets/bundle_card.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/widgets/night_market_section.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late Timer _countdownTimer;
  Duration _timeUntilReset = Duration.zero;
  late AnimationController _pulseController;
  bool _hasTriggeredResetFetch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timeUntilReset = TimezoneHelper.timeUntilReset;
    _startCountdownTimer();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final currentRemaining = TimezoneHelper.timeUntilReset;
      setState(() {
        _timeUntilReset = currentRemaining;
      });

      // Auto-refresh store when countdown crosses reset (00:00 UTC)
      if (currentRemaining.inSeconds <= 1 && !_hasTriggeredResetFetch) {
        _hasTriggeredResetFetch = true;
        // Wait 3 seconds for Riot servers to rotate store offers
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            context.read<StoreCubit>().fetchStore(forceRefresh: true);
            _hasTriggeredResetFetch = false;
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() {
          _timeUntilReset = TimezoneHelper.timeUntilReset;
        });
        final storeCubit = context.read<StoreCubit>();
        final currentState = storeCubit.state;
        if (currentState is StoreLoaded) {
          final store = currentState.store;
          final elapsed =
              DateTime.now().difference(store.lastFetched).inSeconds;
          if (elapsed >= store.remainingDurationSeconds) {
            storeCubit.fetchStore(forceRefresh: true);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
              return RefreshIndicator(
                color: AppTheme.valorantRed,
                backgroundColor: AppTheme.surfaceDark,
                onRefresh: () async {
                  await context
                      .read<StoreCubit>()
                      .fetchStore(forceRefresh: true);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                  // ─── Header ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BlocBuilder<ProfileCubit, ProfileState>(
                            builder: (context, profileState) {
                              if (profileState is ProfileLoaded) {
                                final profile = profileState.profile;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () => context.goNamed('settings'),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceDark,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.valorantRed
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Builder(
                                            builder: (_) {
                                              final miniArt = (profile.cardSmallArt != null && profile.cardSmallArt!.isNotEmpty)
                                                  ? profile.cardSmallArt!
                                                  : (profile.cardWideArt ?? profile.cardLargeArt);
                                              if (miniArt != null && miniArt.isNotEmpty) {
                                                return ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: CachedNetworkImage(
                                                    imageUrl: miniArt,
                                                    width: 18,
                                                    height: 18,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (_, __, ___) => const Icon(
                                                      Icons.person_rounded,
                                                      size: 16,
                                                      color: AppTheme.valorantRed,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const Icon(
                                                Icons.person_rounded,
                                                size: 16,
                                                color: AppTheme.valorantRed,
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            profile.displayName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceLight,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'LVL ${profile.accountLevel}',
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 3,
                                        height: 20,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentMagenta,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      Text(
                                        'DAILY STORE',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                            ?.copyWith(
                                              letterSpacing: 2,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ],
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
                                        vertical: 5,
                                      ),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardDark,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.08),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.monetization_on_outlined,
                                            size: 14,
                                            color: AppTheme.accentMagenta,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${state.wallet.valorantPoints}',
                                            style: GoogleFonts.rajdhani(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF00E5FF),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${state.wallet.kingdomCredits}',
                                            style: GoogleFonts.rajdhani(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF00E5FF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Refresh button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardDark,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: IconButton(
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        context
                                            .read<StoreCubit>()
                                            .fetchStore(forceRefresh: true);
                                        context
                                            .read<ProfileCubit>()
                                            .loadProfile(forceRefresh: true);
                                      },
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 20,
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

                  // ─── Store Items Body (Horizontal Gun Cards) ──
                  if (state is StoreLoading)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _SkinCardPlaceholder(),
                          ),
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
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final skin = state.store.featuredOffers[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SkinCard(skin: skin),
                            );
                          },
                          childCount: state.store.featuredOffers.length,
                        ),
                      ),
                    ),

                    // Featured Bundles (if present)
                    if (state.store.bundles.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          child: Text(
                            'FEATURED COLLECTIONS',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(letterSpacing: 1.5),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: BundleCard(
                                bundle: state.store.bundles[index],
                              ),
                            ),
                            childCount: state.store.bundles.length,
                          ),
                        ),
                      ),
                    ] else if (state.store.bundle != null) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                              BundleCard(bundle: state.store.bundle!),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Night Market (if active)
                    if (state.store.nightMarket != null &&
                        state.store.nightMarket!.offers.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: NightMarketSection(
                            nightMarket: state.store.nightMarket!,
                          ),
                        ),
                      ),

                    // Accessory Store (Kingdom Credits rotation)
                    if (state.store.accessoryOffers.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: AccessoryStoreSection(
                            items: state.store.accessoryOffers,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  }
}

/// Real interactive Horizontal Skin Card
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
            height: 108,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isWishlisted
                    ? AppTheme.accentMagenta.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.08),
                width: isWishlisted ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isWishlisted
                      ? AppTheme.accentMagenta.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  // Left vertical tier accent stripe
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: 3.5,
                    child: Container(
                      color: isWishlisted ? AppTheme.accentMagenta : tierColor,
                    ),
                  ),

                  // Background subtle tier glow on the right
                  Positioned(
                    right: -20,
                    top: -20,
                    bottom: -20,
                    width: 170,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.centerRight,
                          radius: 0.9,
                          colors: [
                            tierColor.withValues(alpha: 0.16),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content Row: Left info, Right gun image
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                    child: Row(
                      children: [
                        // Left Details Column
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Tag: Weapon Type & Tier
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tierColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: tierColor.withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      skin.weaponName?.toUpperCase() ?? 'VALORANT',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: tierColor,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  if (skin.tierName != null &&
                                      skin.tierName!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        skin.tierName!.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // Skin Name
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  skin.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 0.3,
                                    height: 1.2,
                                  ),
                                ),
                              ),

                              // Price & Wishlist Badge
                              Row(
                                children: [
                                  const Icon(
                                    Icons.monetization_on_outlined,
                                    size: 14,
                                    color: AppTheme.accentMagenta,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${skin.cost} VP',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (isWishlisted) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentMagenta
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: AppTheme.accentMagenta
                                              .withValues(alpha: 0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: const Text(
                                        'WISHLIST',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.accentMagenta,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Right Weapon Gun Image & Wishlist Icon
                        Expanded(
                          flex: 6,
                          child: Stack(
                            children: [
                              // Horizontal Gun Image
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: skin.displayIcon != null
                                      ? Hero(
                                          tag: 'skin_image_${skin.uuid}',
                                          child: CachedNetworkImage(
                                            imageUrl: skin.displayIcon!,
                                            fit: BoxFit.contain,
                                            placeholder: (context, url) =>
                                                const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  color: AppTheme.accentMagenta,
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) =>
                                                const Icon(
                                              Icons.image_not_supported_outlined,
                                              color: AppTheme.textMuted,
                                              size: 32,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.sports_esports_rounded,
                                          size: 40,
                                          color: AppTheme.textMuted,
                                        ),
                                ),
                              ),

                              // Wishlist Toggle
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    context
                                        .read<WishlistCubit>()
                                        .toggleWishlist(skin);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isWishlisted
                                          ? AppTheme.accentMagenta
                                              .withValues(alpha: 0.25)
                                          : AppTheme.surfaceDark
                                              .withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isWishlisted
                                            ? AppTheme.accentMagenta
                                            : Colors.white
                                                .withValues(alpha: 0.08),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Icon(
                                      isWishlisted
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 13,
                                      color: isWishlisted
                                          ? AppTheme.accentMagenta
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentMagenta.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentMagenta.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentMagenta.withValues(
                    alpha: 0.12 + (pulseController.value * 0.1),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.timer_rounded,
                  color: AppTheme.accentMagenta,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STORE RESETS IN (00:00 UTC)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.0,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  TimezoneHelper.formatDuration(timeRemaining),
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppTheme.accentMagenta,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentMagenta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.accentMagenta.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.rajdhani(
                color: AppTheme.accentMagenta,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
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
  const _SkinCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceLight.withValues(alpha: 0.4),
      highlightColor: AppTheme.surfaceColor,
      child: Container(
        height: 108,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
