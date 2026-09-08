import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<InventoryCubit>().loadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: BlocBuilder<InventoryCubit, InventoryState>(
            builder: (context, state) {
              return RefreshIndicator(
                color: AppTheme.valorantRed,
                backgroundColor: AppTheme.surfaceDark,
                onRefresh: () async {
                  await context
                      .read<InventoryCubit>()
                      .loadInventory(forceRefresh: true);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INVENTORY',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(letterSpacing: 2),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Account valuation & owned skins',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  context
                                      .read<InventoryCubit>()
                                      .loadInventory(forceRefresh: true);
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
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
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
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
                          child: AccountValueCard(overview: state.overview),
                        ),
                      ),

                      // Tier Breakdown
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: TierBreakdownCard(
                            tierBreakdown: state.overview.tierBreakdown,
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
                                        color: AppTheme.surfaceDark,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.1),
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
                                        color: AppTheme.surfaceDark,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.sort_rounded,
                                        size: 20,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    color: AppTheme.surfaceDark,
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
                              const SizedBox(height: 10),

                              // Tier Filter Chips
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildTierChip(
                                      label: 'ALL',
                                      isSelected: state.selectedTier == null,
                                      onTap: () => context
                                          .read<InventoryCubit>()
                                          .filterByTier(null),
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
                                        isSelected: state.selectedTier == tier,
                                        onTap: () => context
                                            .read<InventoryCubit>()
                                            .filterByTier(tier),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
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

  Widget _buildTierChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.valorantRed
                : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.valorantRed
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
