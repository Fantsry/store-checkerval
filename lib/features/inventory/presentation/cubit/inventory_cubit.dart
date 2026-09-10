import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';
import 'package:valorant_store_tracker/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/cubit/inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final InventoryRepository _repository;

  InventoryCubit({required InventoryRepository repository})
      : _repository = repository,
        super(const InventoryInitial());

  Future<void> loadInventory({bool forceRefresh = false}) async {
    if (state is! InventoryLoaded) {
      emit(const InventoryLoading());
    }

    final result =
        await _repository.getInventoryOverview(forceRefresh: forceRefresh);

    result.when(
      success: (overview) {
        final currentTier = (state is InventoryLoaded)
            ? (state as InventoryLoaded).selectedTier
            : null;
        final currentSource = (state is InventoryLoaded)
            ? (state as InventoryLoaded).sourceFilter
            : InventorySourceFilter.all;
        final currentSearch = (state is InventoryLoaded)
            ? (state as InventoryLoaded).searchQuery
            : '';
        final currentSort = (state is InventoryLoaded)
            ? (state as InventoryLoaded).sortOption
            : InventorySortOption.equippedFirst;

        final filtered = _applyFilters(
          overview.ownedSkins,
          currentSource,
          currentTier,
          currentSearch,
          currentSort,
        );

        emit(
          InventoryLoaded(
            overview: overview,
            filteredSkins: filtered,
            selectedTier: currentTier,
            sourceFilter: currentSource,
            searchQuery: currentSearch,
            sortOption: currentSort,
          ),
        );
      },
      failure: (failure) {
        if (state is! InventoryLoaded) {
          emit(InventoryError(message: failure.message));
        }
      },
    );
  }

  void filterBySource(InventorySourceFilter source) {
    if (state is! InventoryLoaded) return;
    final s = state as InventoryLoaded;
    if (s.sourceFilter == source) return;

    final filtered = _applyFilters(
      s.overview.ownedSkins,
      source,
      s.selectedTier,
      s.searchQuery,
      s.sortOption,
    );

    emit(s.copyWith(
      sourceFilter: source,
      filteredSkins: filtered,
    ));
  }

  void filterByTier(String? tier) {
    if (state is! InventoryLoaded) return;
    final s = state as InventoryLoaded;
    final newTier = s.selectedTier == tier ? null : tier;
    final filtered = _applyFilters(
      s.overview.ownedSkins,
      s.sourceFilter,
      newTier,
      s.searchQuery,
      s.sortOption,
    );

    emit(s.copyWith(
      selectedTier: () => newTier,
      filteredSkins: filtered,
    ));
  }

  void searchSkins(String query) {
    if (state is! InventoryLoaded) return;
    final s = state as InventoryLoaded;
    final filtered = _applyFilters(
      s.overview.ownedSkins,
      s.sourceFilter,
      s.selectedTier,
      query,
      s.sortOption,
    );

    emit(s.copyWith(
      searchQuery: query,
      filteredSkins: filtered,
    ));
  }

  void changeSortOption(InventorySortOption sort) {
    if (state is! InventoryLoaded) return;
    final s = state as InventoryLoaded;
    final filtered = _applyFilters(
      s.overview.ownedSkins,
      s.sourceFilter,
      s.selectedTier,
      s.searchQuery,
      sort,
    );

    emit(s.copyWith(
      sortOption: sort,
      filteredSkins: filtered,
    ));
  }

  List<OwnedSkinItem> _applyFilters(
    List<OwnedSkinItem> skins,
    InventorySourceFilter source,
    String? tier,
    String query,
    InventorySortOption sort,
  ) {
    var list = skins.where((item) {
      switch (source) {
        case InventorySourceFilter.all:
          break;
        case InventorySourceFilter.store:
          if (item.isBattlepass) return false;
          break;
        case InventorySourceFilter.battlepass:
          if (!item.isBattlepass) return false;
          break;
      }

      if (tier != null && tier.isNotEmpty) {
        if (item.tierName?.toLowerCase() != tier.toLowerCase()) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final matchesName = item.displayName.toLowerCase().contains(q);
        final matchesWeapon = item.weapon.toLowerCase().contains(q);
        if (!matchesName && !matchesWeapon) return false;
      }
      return true;
    }).toList();

    switch (sort) {
      case InventorySortOption.valueHighToLow:
        list.sort((a, b) => b.cost.compareTo(a.cost));
      case InventorySortOption.valueLowToHigh:
        list.sort((a, b) => a.cost.compareTo(b.cost));
      case InventorySortOption.nameAZ:
        list.sort((a, b) => a.displayName.compareTo(b.displayName));
      case InventorySortOption.equippedFirst:
        list.sort((a, b) {
          if (a.isEquipped && !b.isEquipped) return -1;
          if (!a.isEquipped && b.isEquipped) return 1;
          return b.cost.compareTo(a.cost);
        });
    }

    return list;
  }
}
