import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/empty_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Vandal',
    'Phantom',
    'Operator',
    'Sheriff',
    'Melee',
    'Ghost',
    'Spectre',
    'Classic',
    'Marshal',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<WishlistCubit>().state;
    if (state is! WishlistLoaded || state.catalog.isEmpty) {
      context.read<WishlistCubit>().loadWishlist();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<WishlistCubit>().searchCatalog(
      query: query,
      weapon: _selectedFilter,
    );
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    context.read<WishlistCubit>().searchCatalog(
      query: _searchController.text,
      weapon: filter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Catalog',
          style: AppTextStyles.h2(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<WishlistCubit, WishlistState>(
          builder: (context, state) {
            final catalog = state is WishlistLoaded
                ? state.catalog
                : <SkinItem>[];
            final isSearching = state is WishlistLoaded && state.isSearching;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search skins or weapons',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                            )
                          : null,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = filter == _selectedFilter;
                      return GestureDetector(
                        onTap: () => _onFilterSelected(filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.1)
                                : AppColors.surface,
                            borderRadius: AppRadius.roundedSm,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            filter.toUpperCase(),
                            style: AppTextStyles.statLabel(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state is WishlistLoaded)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${catalog.length} SKINS',
                          style: AppTextStyles.statLabel(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedFilter != 'All' ||
                            _searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _onFilterSelected('All');
                            },
                            child: Text(
                              'RESET',
                              style: AppTextStyles.statLabel(
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                if (state is WishlistError)
                  Expanded(
                    child: ErrorStateView(
                      message: state.message,
                      onRetry: () => context.read<WishlistCubit>().loadWishlist(
                        forceRefresh: true,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.accent,
                      backgroundColor: AppColors.card,
                      onRefresh: () async {
                        await context.read<WishlistCubit>().searchCatalog(
                          query: _searchController.text,
                          weapon: _selectedFilter,
                          forceRefresh: true,
                        );
                      },
                      child: isSearching
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                              ),
                            )
                          : catalog.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: EmptyStateView(
                                    icon: Icons.search_off_rounded,
                                    title: 'No skins found',
                                    description:
                                        'Try adjusting your search or filters.',
                                    buttonText: 'RESET FILTERS',
                                    onButtonPressed: () {
                                      _searchController.clear();
                                      _onFilterSelected('All');
                                    },
                                  ),
                                ),
                              ],
                            )
                          : GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                0,
                                AppSpacing.lg,
                                AppSpacing.xxl,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: AppSpacing.sm,
                                    crossAxisSpacing: AppSpacing.sm,
                                    childAspectRatio: 0.78,
                                  ),
                              itemCount: catalog.length,
                              itemBuilder: (context, index) {
                                return _CatalogCard(skin: catalog[index]);
                              },
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final SkinItem skin;

  const _CatalogCard({required this.skin});

  @override
  Widget build(BuildContext context) {
    final tierColor = AppColors.getTierColor(skin.tierName);

    return BlocBuilder<WishlistCubit, WishlistState>(
      builder: (context, state) {
        final isWishlisted =
            state is WishlistLoaded && state.isInWishlist(skin.uuid);

        return DataPanel(
          padding: const EdgeInsets.all(AppSpacing.sm),
          onTap: () {
            context.pushNamed(
              'skinDetail',
              pathParameters: {'skinId': skin.uuid},
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (skin.weaponName ?? 'SKIN').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.statLabel(color: tierColor),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<WishlistCubit>().toggleWishlist(skin);
                    },
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
                  child: skin.displayIcon != null
                      ? CachedNetworkImage(
                          imageUrl: skin.displayIcon!,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            size: 26,
                            color: AppColors.textMuted,
                          ),
                        )
                      : const Icon(
                          Icons.sports_esports_outlined,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      skin.tierName ?? 'SELECT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.statLabel(color: tierColor),
                    ),
                  ),
                  Text(
                    skin.cost > 0 ? '${skin.cost} VP' : '-- VP',
                    style: AppTextStyles.statValue(
                      color: AppColors.vpGold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
