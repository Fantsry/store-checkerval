import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/cubit/inventory_state.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/widgets/account_value_card.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/widgets/equipped_loadout_preview.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/widgets/owned_skin_card.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/widgets/tier_breakdown_card.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _autoRefreshedStale = false;

  void _scrollToSkins() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        const targetOffset = 380.0;
        if (_scrollController.offset < targetOffset) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<InventoryCubit>().loadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: BlocConsumer<InventoryCubit, InventoryState>(
            listener: (context, state) {
              if (state is InventoryLoaded &&
                  state.overview.totalSkinsCount > 3 &&
                  state.overview.battlepassSkinsCount == 0 &&
                  !_autoRefreshedStale) {
                _autoRefreshedStale = true;
                context
                    .read<InventoryCubit>()
                    .loadInventory(forceRefresh: true);
              }
            },
            builder: (context, state) {
              return RefreshIndicator(
                color: AppTheme.accentMagenta,
                backgroundColor: AppTheme.surfaceDark,
                onRefresh: () async {
                  await context
                      .read<InventoryCubit>()
                      .loadInventory(forceRefresh: true);
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                                      'INVENTORY',
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
                                      'ACCOUNT VALUATION & SKINS',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            letterSpacing: 0.8,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
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
                                onPressed: () {
                                  context
                                      .read<InventoryCubit>()
                                      .loadInventory(forceRefresh: true);
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (state is InventoryLoading) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Shimmer.fromColors(
                            baseColor:
                                AppTheme.surfaceLight.withValues(alpha: 0.4),
                            highlightColor: AppTheme.surfaceColor,
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else if (state is InventoryError) ...[
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
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          context.pushNamed('login'),
                                      icon: const Icon(Icons.login_rounded),
                                      label: const Text('SIGN IN WITH RIOT'),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        context
                                            .read<InventoryCubit>()
                                            .loadInventory(forceRefresh: true);
                                      },
                                      child: const Text('RETRY'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else if (state is InventoryLoaded) ...[
                      // Account Value Summary Card
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                          child: AccountValueCard(
                            overview: state.overview,
                            onOwnedSkinsTap: () {
                              context
                                  .read<InventoryCubit>()
                                  .filterBySource(InventorySourceFilter.all);
                              context
                                  .read<InventoryCubit>()
                                  .filterByTier(null);
                              _scrollToSkins();
                            },
                          ),
                        ),
                      ),

                      // Tier Breakdown
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: TierBreakdownCard(
                            tierBreakdown: state.overview.tierBreakdown,
                            selectedTier: state.selectedTier,
                            onTierSelected: (tier) {
                              context
                                  .read<InventoryCubit>()
                                  .filterByTier(tier);
                              _scrollToSkins();
                            },
                          ),
                        ),
                      ),

                      // Equipped Loadout Preview
                      if (state.overview.equippedWeapons.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: EquippedLoadoutPreview(
                              equippedWeapons: state.overview.equippedWeapons,
                            ),
                          ),
                        ),

                      // Search & Filter Controls
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Search Bar
                                  Expanded(
                                    child: Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardDark,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.08),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (q) {
                                          context
                                              .read<InventoryCubit>()
                                              .searchSkins(q);
                                        },
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Search owned skins...',
                                          hintStyle: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.search_rounded,
                                            size: 18,
                                            color: AppTheme.textSecondary,
                                          ),
                                          suffixIcon: _searchController
                                                  .text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(
                                                    Icons.clear_rounded,
                                                    size: 16,
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    context
                                                        .read<InventoryCubit>()
                                                        .searchSkins('');
                                                  },
                                                )
                                              : null,
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Sort Options Popup
                                  PopupMenuButton<InventorySortOption>(
                                    icon: Container(
                                      height: 44,
                                      width: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardDark,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.08),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.sort_rounded,
                                        size: 20,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    color: AppTheme.cardDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      side: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.08),
                                      ),
                                    ),
                                    onSelected: (sort) {
                                      context
                                          .read<InventoryCubit>()
                                          .changeSortOption(sort);
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value:
                                            InventorySortOption.equippedFirst,
                                        child: Text('Equipped First'),
                                      ),
                                      const PopupMenuItem(
                                        value:
                                            InventorySortOption.valueHighToLow,
                                        child: Text('Value: High to Low'),
                                      ),
                                      const PopupMenuItem(
                                        value:
                                            InventorySortOption.valueLowToHigh,
                                        child: Text('Value: Low to High'),
                                      ),
                                      const PopupMenuItem(
                                        value: InventorySortOption.nameAZ,
                                        child: Text('Name (A-Z)'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Source Filter Bar: ALL | STORE | BATTLEPASS
                              Row(
                                children: [
                                  _buildSourceFilterChip(
                                    label: 'ALL',
                                    count: state.overview.ownedSkins.length,
                                    icon: Icons.apps_rounded,
                                    isSelected: state.sourceFilter ==
                                        InventorySourceFilter.all,
                                    onTap: () {
                                      context
                                          .read<InventoryCubit>()
                                          .filterBySource(
                                              InventorySourceFilter.all);
                                      _scrollToSkins();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSourceFilterChip(
                                    label: 'STORE',
                                    count: state.overview.storeSkinsCount,
                                    icon: Icons.shopping_bag_outlined,
                                    isSelected: state.sourceFilter ==
                                        InventorySourceFilter.store,
                                    onTap: () {
                                      context
                                          .read<InventoryCubit>()
                                          .filterBySource(
                                              InventorySourceFilter.store);
                                      _scrollToSkins();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSourceFilterChip(
                                    label: 'BATTLEPASS',
                                    count: state.overview.battlepassSkinsCount,
                                    icon: Icons.military_tech_rounded,
                                    isSelected: state.sourceFilter ==
                                        InventorySourceFilter.battlepass,
                                    selectedColor: const Color(0xFFFFB300),
                                    onTap: () {
                                      context
                                          .read<InventoryCubit>()
                                          .filterBySource(
                                              InventorySourceFilter.battlepass);
                                      _scrollToSkins();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Tier Filter Chips
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildTierChip(
                                      label: 'ALL',
                                      isSelected: state.selectedTier == null,
                                      onTap: () {
                                        context
                                            .read<InventoryCubit>()
                                            .filterByTier(null);
                                        _scrollToSkins();
                                      },
                                    ),
                                    ...[
                                      'Exclusive',
                                      'Ultra',
                                      'Premium',
                                      'Deluxe',
                                      'Select',
                                    ].map((tier) {
                                       return _buildTierChip(
                                         label: tier.toUpperCase(),
                                         isSelected: state.selectedTier != null &&
                                             state.selectedTier!.toLowerCase() ==
                                                 tier.toLowerCase(),
                                         onTap: () {
                                           context
                                               .read<InventoryCubit>()
                                               .filterByTier(tier);
                                           _scrollToSkins();
                                         },
                                       );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Active Filters & Results Counter Bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Builder(
                            builder: (context) {
                              final hasActiveFilter = state.selectedTier != null ||
                                  state.sourceFilter != InventorySourceFilter.all ||
                                  state.searchQuery.isNotEmpty;
                              final filterParts = <String>[];
                              if (state.sourceFilter != InventorySourceFilter.all) {
                                filterParts.add(state.sourceFilter.name.toUpperCase());
                              }
                              if (state.selectedTier != null) {
                                filterParts.add(state.selectedTier!.toUpperCase());
                              }
                              if (state.searchQuery.isNotEmpty) {
                                filterParts.add('"${state.searchQuery}"');
                              }
                              final activeFilterLabel = filterParts.join(' • ');

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: hasActiveFilter
                                        ? AppTheme.accentMagenta.withValues(alpha: 0.35)
                                        : Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.filter_list_rounded,
                                      size: 14,
                                      color: hasActiveFilter
                                          ? AppTheme.accentMagenta
                                          : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            'SHOWING ${state.filteredSkins.length} OF ${state.overview.totalSkinsCount} SKINS',
                                            style: GoogleFonts.rajdhani(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          if (hasActiveFilter) ...[
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accentMagenta
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: AppTheme.accentMagenta
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  activeFilterLabel,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppTheme.accentMagenta,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (hasActiveFilter) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          _searchController.clear();
                                          context
                                              .read<InventoryCubit>()
                                              .searchSkins('');
                                          context
                                              .read<InventoryCubit>()
                                              .filterByTier(null);
                                          context
                                              .read<InventoryCubit>()
                                              .filterBySource(
                                                  InventorySourceFilter.all);
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.close_rounded,
                                                size: 13,
                                                color: AppTheme.accentMagenta,
                                              ),
                                              SizedBox(width: 2),
                                              Text(
                                                'RESET',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.accentMagenta,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ],
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

                      // Skins Grid
                      if (state.filteredSkins.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'No skins match your filter',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final skin = state.filteredSkins[index];
                                return OwnedSkinCard(skin: skin);
                              },
                              childCount: state.filteredSkins.length,
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

  Widget _buildSourceFilterChip({
    required String label,
    required int count,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? selectedColor,
  }) {
    final activeColor = selectedColor ?? AppTheme.accentMagenta;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.18)
                : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? activeColor : AppTheme.textSecondary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? activeColor : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentMagenta
                : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentMagenta
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
