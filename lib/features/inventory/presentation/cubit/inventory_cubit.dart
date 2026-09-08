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
        final currentSearch = (state is InventoryLoaded)
            ? (state as InventoryLoaded).searchQuery
            : '';
        final currentSort = (state is InventoryLoaded)
            ? (state as InventoryLoaded).sortOption
            : InventorySortOption.equippedFirst;

        final filtered = _applyFilters(
          overview.ownedSkins,
          currentTier,
          currentSearch,
          currentSort,
        );

        emit(
          InventoryLoaded(
            overview: overview,
            filteredSkins: filtered,
            selectedTier: currentTier,
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

  void filterByTier(String? tier) {
    if (state is! InventoryLoaded) return;
    final s = state as InventoryLoaded;
    final newTier = s.selectedTier == tier ? null : tier;
    final filtered = _applyFilters(
      s.overview.ownedSkins,
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
    String? tier,
    String query,
    InventorySortOption sort,
  ) {
    var list = skins.where((item) {
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
