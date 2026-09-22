import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'SKIN CATALOG',
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
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
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search skins by name...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
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
                                size: 16,
                                color: AppTheme.textMuted,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),

              // ─── Filter Chips ───────────────────────────────
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = filter == _selectedFilter;
                    return InkWell(
                      onTap: () => _onFilterSelected(filter),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accentMagenta.withValues(alpha: 0.2)
                              : AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.accentMagenta
                                : Colors.white.withValues(alpha: 0.08),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              letterSpacing: 0.6,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ─── Catalog Grid / States ───────────────────────────────
              if (state is WishlistError)
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
              else
                Expanded(
                  child: RefreshIndicator(
                    color: AppTheme.accentMagenta,
                    backgroundColor: AppTheme.surfaceDark,
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
                              color: AppTheme.accentMagenta,
                            ),
                          )
                        : catalog.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                            0.5,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.search_off_rounded,
                                            size: 48,
                                            color: AppTheme.textMuted,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No skins found',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Try adjusting your search or filters',
                                            style: TextStyle(
                                                color: AppTheme.textSecondary),
                                          ),
                                          const SizedBox(height: 16),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              _searchController.clear();
                                              _onFilterSelected('All');
                                            },
                                            icon: const Icon(
                                                Icons.refresh_rounded),
                                            label: const Text('RESET FILTERS'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 0.78,
                                ),
                                itemCount: catalog.length,
                                itemBuilder: (context, index) {
                                  final skin = catalog[index];
                                  return _CatalogCard(skin: skin);
                                },
                              ),
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
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isWishlisted
                    ? AppTheme.accentMagenta.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.08),
                width: isWishlisted ? 1.5 : 1.0,
              ),
              boxShadow: isWishlisted
                  ? [
                      BoxShadow(
                        color: AppTheme.accentMagenta.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
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
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
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
                                ? AppTheme.accentMagenta
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
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFE5B94E),
                          ),
                        ),
                        if (skin.tierName != null)
                          Text(
                            skin.tierName!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
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
