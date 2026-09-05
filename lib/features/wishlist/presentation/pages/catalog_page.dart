import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';

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
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('SKIN CATALOG'),
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          final catalog = state is WishlistLoaded ? state.catalog : <SkinItem>[];
          final isSearching = state is WishlistLoaded && state.isSearching;

          return Column(
            children: [
              // ─── Search Bar ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search skins by name...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textMuted,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppTheme.textMuted,
                            ),
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),

              // ─── Filter Chips ───────────────────────────────
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = filter == _selectedFilter;
                    return ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor:
                          AppTheme.valorantRed.withValues(alpha: 0.25),
                      checkmarkColor: AppTheme.valorantRed,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.valorantRed
                            : AppTheme.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => _onFilterSelected(filter),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ─── Catalog Grid ───────────────────────────────
              Expanded(
                child: isSearching
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.valorantRed,
                        ),
                      )
                    : catalog.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No skins found',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Try adjusting your search or filters',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: catalog.length,
                            itemBuilder: (context, index) {
                              final skin = catalog[index];
                              return _CatalogCard(skin: skin);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final SkinItem skin;

  const _CatalogCard({required this.skin});

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
      builder: (context, state) {
        final isWishlisted =
            state is WishlistLoaded && state.isInWishlist(skin.uuid);

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
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weapon badge & Wishlist button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          skin.weaponName?.toUpperCase() ?? 'SKIN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tierColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.read<WishlistCubit>().toggleWishlist(skin);
                          },
                          child: Icon(
                            isWishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: isWishlisted
                                ? AppTheme.valorantRed
                                : AppTheme.textSecondary,
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
                                placeholder: (_, __) => const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.surfaceLight,
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
                    ),
                    const SizedBox(height: 6),

                    // Skin name
                    Text(
                      skin.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${skin.cost} VP',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (skin.tierName != null)
                          Text(
                            skin.tierName!,
                            style: TextStyle(
                              fontSize: 10,
                              color: tierColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
