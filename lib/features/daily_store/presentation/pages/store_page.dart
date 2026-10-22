import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/widgets/accessory_store_section.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/widgets/bundle_card.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/widgets/night_market_section.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/countdown_timer_widget.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/shimmer_loading.dart';
import 'package:valorant_store_tracker/ui/widgets/skin_preview_dialog.dart';
import 'package:valorant_store_tracker/ui/widgets/vp_chip.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
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
        title: Text(
          'Store',
          style: AppTextStyles.h2(color: AppColors.textPrimary),
        ),
        actions: [
          BlocBuilder<WishlistCubit, WishlistState>(
            builder: (context, state) {
              final count = state is WishlistLoaded ? state.items.length : 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => context.push('/wishlist'),
                    tooltip: 'Wishlist',
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '$count',
                          style: AppTextStyles.mono(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onAccent,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _fetchStoreData(forceRefresh: true),
            tooltip: 'Refresh store',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _fetchStoreData(forceRefresh: true),
          color: AppColors.accent,
          backgroundColor: AppColors.card,
          child: BlocBuilder<StoreCubit, StoreState>(
            builder: (context, state) {
              if (state is StoreLoading) {
                return _buildLoadingState();
              }

              if (state is StoreError) {
                final isAuthError =
                    state.message.toLowerCase().contains('session') ||
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
                          final reauthResult = await getIt<AuthRepository>()
                              .silentReauth();
                          if (reauthResult.isSuccess) {
                            _fetchStoreData(forceRefresh: true);
                          } else if (context.mounted) {
                            context.push('/login');
                          }
                        }
                      : null,
                );
              }

              if (state is StoreLoaded) {
                return Stack(
                  children: [
                    _buildStoreContent(state),
                    if (state.isRefreshing)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          key: Key('store-refresh-progress'),
                          minHeight: 2,
                          color: AppColors.accent,
                          backgroundColor: AppColors.border,
                        ),
                      ),
                  ],
                );
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
          ShimmerBox(height: 56, borderRadius: AppRadius.lg),
          SizedBox(height: AppSpacing.lg),
          ShimmerBox(height: 220, borderRadius: AppRadius.lg),
          SizedBox(height: AppSpacing.lg),
          ShimmerBox(height: 300, borderRadius: AppRadius.lg),
        ],
      ),
    );
  }

  Widget _buildStoreContent(StoreLoaded state) {
    final store = state.store;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWalletAndTimerBar(store, state.wallet),
          const SizedBox(height: AppSpacing.xl),
          if (store.bundle != null) ...[
            const SectionHeader(index: '01', title: 'FEATURED BUNDLE'),
            const SizedBox(height: AppSpacing.sm),
            BundleCard(bundle: store.bundle!),
            const SizedBox(height: AppSpacing.xxl),
          ],
          _buildDailyOffersSection(store.featuredOffers),
          if (store.nightMarket != null &&
              store.nightMarket!.offers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            NightMarketSection(
              index: store.bundle != null ? '03' : '02',
              nightMarket: store.nightMarket!,
            ),
          ],
          if (store.accessoryOffers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            AccessoryStoreSection(
              index:
                  store.nightMarket != null &&
                      store.nightMarket!.offers.isNotEmpty
                  ? '04'
                  : (store.bundle != null ? '03' : '02'),
              items: store.accessoryOffers,
            ),
          ],
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildWalletAndTimerBar(DailyStore store, UserWallet wallet) {
    return DataPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: CountdownTimerWidget(
              initialRemainingSeconds: store.currentRemainingSeconds,
              onTimerExpired: () => _fetchStoreData(forceRefresh: true),
              compact: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          VpChip(amount: wallet.valorantPoints, fontSize: 11, compact: true),
          const SizedBox(width: AppSpacing.xs),
          VpChip(
            amount: wallet.radianitePoints,
            isRadianite: true,
            fontSize: 11,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyOffersSection(List<SkinItem> skins) {
    if (skins.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          index: '02',
          title: 'DAILY ROTATION',
          subtitle: '${skins.length} skins available today',
          trailing: Text(
            '${(_currentSkinIndex + 1).toString().padLeft(2, '0')} / '
            '${skins.length.toString().padLeft(2, '0')}',
            style: AppTextStyles.statLabel(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 356,
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
                    value = (1 - (value.abs() * 0.06)).clamp(0.0, 1.0);
                  } else {
                    value = index == 0 ? 1.0 : 0.94;
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 356,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(skins.length, (index) {
            final isSelected = index == _currentSkinIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 26 : 6,
              height: 2,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.border,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFeaturedSkinCard(SkinItem skin) {
    final tierColor = AppColors.getTierColor(skin.tierName);
    final cacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: DataPanel(
        onTap: () => SkinPreviewSheet.show(context, skin),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        skin.tierName ?? 'SELECT',
                        style: AppTextStyles.statLabel(color: tierColor),
                      ),
                      if (skin.weaponName != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 1,
                          height: 10,
                          color: AppColors.border,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            skin.weaponName!,
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
                ),
                BlocBuilder<WishlistCubit, WishlistState>(
                  builder: (context, state) {
                    final inWishlist =
                        state is WishlistLoaded &&
                        state.isInWishlist(skin.uuid);
                    return GestureDetector(
                      onTap: () =>
                          context.read<WishlistCubit>().toggleWishlist(skin),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: inWishlist
                              ? AppColors.accent.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: AppRadius.roundedSm,
                          border: Border.all(
                            color: inWishlist
                                ? AppColors.accent
                                : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          inWishlist
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 15,
                          color: inWishlist
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Hero(
                  tag: 'skin_${skin.uuid}',
                  child:
                      skin.displayIcon != null && skin.displayIcon!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: skin.displayIcon!,
                          fit: BoxFit.contain,
                          memCacheWidth: cacheWidth,
                          fadeInDuration: const Duration(milliseconds: 180),
                          fadeInCurve: Curves.easeOut,
                          placeholder: (context, url) =>
                              const SizedBox.shrink(),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.shield_outlined,
                            size: 58,
                            color: AppColors.textMuted,
                          ),
                        )
                      : const Icon(
                          Icons.shield_outlined,
                          size: 58,
                          color: AppColors.textMuted,
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skin.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h2(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'TAP TO PREVIEW VARIANTS',
                        style: AppTextStyles.statLabel(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                VpChip(amount: skin.cost, fontSize: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
