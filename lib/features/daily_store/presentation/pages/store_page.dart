import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/widgets/accessory_store_section.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/widgets/bundle_card.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/widgets/night_market_section.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/countdown_timer_widget.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/shimmer_loading.dart';
import 'package:valorant_store_tracker/ui/widgets/skin_preview_dialog.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_badge.dart';
import 'package:valorant_store_tracker/ui/widgets/vp_chip.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentSkinIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
  }

  void _fetchStoreData({bool forceRefresh = false}) {
    context.read<StoreCubit>().fetchStore(forceRefresh: forceRefresh);
    context.read<ProfileCubit>().loadProfile(forceRefresh: forceRefresh);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('STORE', style: AppTextStyles.h2(color: AppColors.textPrimary)),
        actions: [
          // Wishlist Shortcut with Badge
          BlocBuilder<WishlistCubit, WishlistState>(
            builder: (context, state) {
              final count = state is WishlistLoaded ? state.items.length : 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded, color: AppColors.red),
                    onPressed: () => context.push('/wishlist'),
                    tooltip: 'Wishlist',
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.cyan,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => _fetchStoreData(forceRefresh: true),
            tooltip: 'Refresh Store',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _fetchStoreData(forceRefresh: true),
          color: AppColors.red,
          backgroundColor: AppColors.card,
          child: BlocBuilder<StoreCubit, StoreState>(
            builder: (context, state) {
              if (state is StoreLoading) {
                return _buildLoadingState();
              }

              if (state is StoreError) {
                final isAuthError = state.message.toLowerCase().contains('session') ||
                    state.message.toLowerCase().contains('unauthorized') ||
                    state.message.toLowerCase().contains('sign in') ||
                    state.message.toLowerCase().contains('login') ||
                    state.message.toLowerCase().contains('re-authenticate');

                return ErrorStateView(
                  message: isAuthError
                      ? 'Sesi login Riot Anda memerlukan pembaruan. Ketuk untuk menyinkronkan rotasi Store.'
                      : state.message,
                  onRetry: () => _fetchStoreData(forceRefresh: true),
                  actionLabel: isAuthError ? 'PERBARUI SESI' : null,
                  onAction: isAuthError
                      ? () async {
                          final reauthResult =
                              await getIt<AuthRepository>().silentReauth();
                          if (reauthResult.isSuccess) {
                            _fetchStoreData(forceRefresh: true);
                          } else {
                            if (context.mounted) {
                              context.push('/login');
                            }
                          }
                        }
                      : null,
                );
              }

              if (state is StoreLoaded) {
                return _buildStoreContent(state.store);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: const [
          ShimmerBox(height: 180, borderRadius: AppRadius.xl),
          SizedBox(height: AppSpacing.lg),
          ShimmerBox(height: 320, borderRadius: AppRadius.xl),
          SizedBox(height: AppSpacing.lg),
          ShimmerBox(height: 200, borderRadius: AppRadius.xl),
        ],
      ),
    );
  }

  Widget _buildStoreContent(DailyStore store) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWalletAndTimerBar(store),
          const SizedBox(height: AppSpacing.lg),
          if (store.bundle != null) ...[
            SectionHeader(
              title: 'FEATURED BUNDLE',
              subtitle: store.bundle!.displayName,
            ),
            const SizedBox(height: AppSpacing.sm),
            BundleCard(bundle: store.bundle!),
            const SizedBox(height: AppSpacing.xl),
          ],
          _buildDailyOffersSection(store.featuredOffers, store.remainingDurationSeconds),
          if (store.nightMarket != null && store.nightMarket!.offers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            NightMarketSection(nightMarket: store.nightMarket!),
          ],
          if (store.accessoryOffers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            AccessoryStoreSection(items: store.accessoryOffers),
          ],
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildWalletAndTimerBar(DailyStore store) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final profile = state is ProfileLoaded ? state.profile : null;

        return AscendCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CountdownTimerWidget(
                initialRemainingSeconds: store.remainingDurationSeconds,
                onTimerExpired: () => _fetchStoreData(forceRefresh: true),
                compact: true,
              ),
              Row(
                children: [
                  VpChip(
                    amount: profile?.valorantPoints ?? 0,
                    fontSize: 13,
                    compact: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  VpChip(
                    amount: profile?.radianitePoints ?? 0,
                    isRadianite: true,
                    fontSize: 13,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyOffersSection(List<SkinItem> skins, int remainingSeconds) {
    if (skins.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'DAILY ROTATION',
          subtitle: '${skins.length} Skins Available Today',
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            itemCount: skins.length,
            onPageChanged: (index) {
              setState(() {
                _currentSkinIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final skin = skins[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index);
                    value = (1 - (value.abs() * 0.12)).clamp(0.0, 1.0);
                  } else {
                    value = index == 0 ? 1.0 : 0.88;
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 380,
                      width: Curves.easeOut.transform(value) * 340,
                      child: child,
                    ),
                  );
                },
                child: _buildFeaturedSkinCard(skin),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(skins.length, (index) {
            final isSelected = index == _currentSkinIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 24 : 8,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.red : AppColors.border,
                borderRadius: AppRadius.roundedPill,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFeaturedSkinCard(SkinItem skin) {
    final tierColor = AppColors.getTierColor(skin.tierName);

    return AscendCard(
      onTap: () => SkinPreviewSheet.show(context, skin),
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.xl,
      hasGlow: true,
      glowColor: tierColor,
      borderColor: tierColor.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Tier badge, Weapon category, Wishlist button
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
              BlocBuilder<WishlistCubit, WishlistState>(
                builder: (context, state) {
                  final inWishlist = state is WishlistLoaded && state.isInWishlist(skin.uuid);
                  return GestureDetector(
                    onTap: () {
                      context.read<WishlistCubit>().toggleWishlist(skin);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: inWishlist
                            ? AppColors.red.withValues(alpha: 0.2)
                            : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: inWishlist ? AppColors.red : AppColors.border,
                        ),
                      ),
                      child: Icon(
                        inWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18,
                        color: inWishlist ? AppColors.red : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // Central Weapon Display Art with Glow
          Expanded(
            child: Center(
              child: Hero(
                tag: 'skin_${skin.uuid}',
                child: skin.displayIcon != null && skin.displayIcon!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: skin.displayIcon!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.shield_outlined,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                      )
                    : const Icon(
                        Icons.shield_outlined,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
              ),
            ),
          ),

          // Bottom Info: Title & VP Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skin.displayName.toUpperCase(),
                      style: AppTextStyles.h3(color: AppColors.textPrimary).copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TAP TO PREVIEW VARIANTS',
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              VpChip(amount: skin.cost, fontSize: 16),
            ],
          ),
        ],
      ),
    );
  }
}
