import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/core/share/share_preview_sheet.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/cubit/inventory_state.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/widgets/inventory_share_card.dart';
import 'package:valorant_store_tracker/l10n/l10n.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/empty_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/shimmer_loading.dart';

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
    final cubit = context.read<InventoryCubit>();
    if (cubit.state is! InventoryLoaded) {
      cubit.loadInventory();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _shareCollection() async {
    final state = context.read<InventoryCubit>().state;
    if (state is! InventoryLoaded) return;

    var playerName = '';
    if (getIt.isRegistered<SecureStorageService>()) {
      final storage = getIt<SecureStorageService>();
      final gameName = await storage.getGameName();
      final tagLine = await storage.getTagLine();
      if (gameName != null && gameName.isNotEmpty) {
        playerName = tagLine != null && tagLine.isNotEmpty
            ? '$gameName#$tagLine'
            : gameName;
      }
    }
    if (!mounted) return;

    final overview = state.overview;
    await showSharePreviewSheet(
      context,
      card: InventoryShareCard(overview: overview, playerName: playerName),
      shareText:
          'My Valorant collection: ${overview.totalSkinsCount} skins worth ${overview.formattedEstimatedIdr} — tracked with Store Checker Val.',
      fileName: 'valorant_collection_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Collection',
          style: AppTextStyles.h2(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.ios_share_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: _shareCollection,
            tooltip: context.l10n.shareCollection,
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () => context.read<InventoryCubit>().loadInventory(
              forceRefresh: true,
            ),
            tooltip: context.l10n.refreshCollection,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              context.read<InventoryCubit>().loadInventory(forceRefresh: true),
          color: AppColors.accent,
          backgroundColor: AppColors.card,
          child: BlocBuilder<InventoryCubit, InventoryState>(
            builder: (context, state) {
              if (state is InventoryLoading) {
                return _buildLoadingSkeleton();
              }

              if (state is InventoryError) {
                return ErrorStateView(
                  message: state.message,
                  onRetry: () => context.read<InventoryCubit>().loadInventory(
                    forceRefresh: true,
                  ),
                );
              }

              if (state is! InventoryLoaded) {
                return const SizedBox.shrink();
              }

              final overview = state.overview;
              final skins = state.filteredSkins;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAccountValueCard(overview),
                          const SizedBox(height: AppSpacing.xl),
                          _buildSearchAndFilters(state),
                          const SizedBox(height: AppSpacing.xl),
                          SectionHeader(
                            index: '01',
                            title: 'ARMORY',
                            subtitle: '${skins.length} skins matching filter',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ),
                    ),
                  ),
                  if (skins.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateView(
                        icon: Icons.shield_outlined,
                        title: 'NO SKINS FOUND',
                        description:
                            'Try adjusting your search query or filter tags.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.8,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildSkinGridItem(skins[index]);
                        }, childCount: skins.length),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxxl),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: const [
          ShimmerBox(height: 150, borderRadius: AppRadius.lg),
          SizedBox(height: AppSpacing.lg),
          ShimmerBox(height: 50, borderRadius: AppRadius.md),
          SizedBox(height: AppSpacing.lg),
          ShimmerGrid(itemCount: 6),
        ],
      ),
    );
  }

  Widget _buildAccountValueCard(InventoryOverview overview) {
    final formatter = NumberFormat('#,###');
    final formattedVp = formatter.format(overview.totalVpSpent);

    return DataPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ACCOUNT VALUATION',
                style: AppTextStyles.statLabel(color: AppColors.textMuted),
              ),
              const Spacer(),
              Text(
                '${overview.totalSkinsCount} SKINS',
                style: AppTextStyles.statLabel(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formattedVp,
                style: AppTextStyles.scoreLarge(color: AppColors.textPrimary),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'VP VALUE',
                style: AppTextStyles.statLabel(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'EST. ${overview.formattedEstimatedIdr}',
            style: AppTextStyles.statLabel(color: AppColors.vpGold),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildValuationStat(
                  'STORE EDITION',
                  '${overview.storeSkinsCount}',
                ),
              ),
              Container(width: 1, height: 26, color: AppColors.border),
              Expanded(
                child: _buildValuationStat(
                  'BATTLE PASS',
                  '${overview.battlepassSkinsCount}',
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValuationStat(
    String label,
    String value, {
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.statLabel(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.statValue(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(InventoryLoaded state) {
    return Column(
      children: [
        // Search Input
        TextField(
          controller: _searchController,
          onChanged: (val) => context.read<InventoryCubit>().searchSkins(val),
          style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search by skin or weapon name...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      context.read<InventoryCubit>().searchSkins('');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Source Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'ALL',
                isSelected: state.sourceFilter == InventorySourceFilter.all,
                onTap: () => context.read<InventoryCubit>().filterBySource(
                  InventorySourceFilter.all,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(
                label: 'STORE ONLY',
                isSelected: state.sourceFilter == InventorySourceFilter.store,
                onTap: () => context.read<InventoryCubit>().filterBySource(
                  InventorySourceFilter.store,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(
                label: 'BATTLEPASS',
                isSelected:
                    state.sourceFilter == InventorySourceFilter.battlepass,
                onTap: () => context.read<InventoryCubit>().filterBySource(
                  InventorySourceFilter.battlepass,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Tier Breakdown Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: state.overview.tierBreakdown.entries.map((entry) {
              final tier = entry.key;
              final isSelected =
                  state.selectedTier?.toLowerCase() == tier.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: GestureDetector(
                  onTap: () =>
                      context.read<InventoryCubit>().filterByTier(tier),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.getTierColor(tier).withValues(alpha: 0.12)
                          : AppColors.surface,
                      borderRadius: AppRadius.roundedSm,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.getTierColor(tier)
                            : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tier,
                      style: AppTextStyles.badge(
                        color: isSelected
                            ? AppColors.getTierColor(tier)
                            : AppColors.textSecondary,
                      ).copyWith(fontSize: 10),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Active Filter Counter Bar with RESET
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SHOWING ${state.filteredSkins.length} OF ${state.overview.totalSkinsCount} SKINS',
              style: AppTextStyles.caption(
                color: AppColors.textSecondary,
              ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
            ),
            if (state.selectedTier != null ||
                state.sourceFilter != InventorySourceFilter.all ||
                state.searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  context.read<InventoryCubit>().filterBySource(
                    InventorySourceFilter.all,
                  );
                  context.read<InventoryCubit>().filterByTier(null);
                  context.read<InventoryCubit>().searchSkins('');
                },
                child: Text(
                  'RESET',
                  style: AppTextStyles.statLabel(
                    color: AppColors.accent,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: AppRadius.roundedSm,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.badge(
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSkinGridItem(OwnedSkinItem skin) {
    final tierColor = AppColors.getTierColor(skin.tierName);

    return DataPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (skin.tierName ?? 'SELECT').toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.statLabel(color: tierColor),
                ),
              ),
              if (skin.isEquipped)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: AppRadius.roundedSm,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    'EQUIPPED',
                    style: AppTextStyles.statLabel(color: AppColors.accent),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Center(
            child: skin.displayIcon != null && skin.displayIcon!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: skin.displayIcon!,
                    height: 62,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.shield_outlined,
                      size: 38,
                      color: AppColors.textMuted,
                    ),
                  )
                : const Icon(
                    Icons.shield_outlined,
                    size: 38,
                    color: AppColors.textMuted,
                  ),
          ),
          const Spacer(),
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
                  skin.weapon,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.statLabel(color: AppColors.textMuted),
                ),
              ),
              if (skin.cost > 0)
                Text(
                  '${skin.cost} VP',
                  style: AppTextStyles.statValue(
                    color: AppColors.textSecondary,
                    fontSize: 10,
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
  }
}
