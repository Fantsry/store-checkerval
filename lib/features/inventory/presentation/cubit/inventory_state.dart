import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';

enum InventorySortOption {
  valueHighToLow,
  valueLowToHigh,
  nameAZ,
  equippedFirst,
}

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

class InventoryLoaded extends InventoryState {
  final InventoryOverview overview;
  final List<OwnedSkinItem> filteredSkins;
  final String? selectedTier;
  final String searchQuery;
  final InventorySortOption sortOption;

  const InventoryLoaded({
    required this.overview,
    required this.filteredSkins,
    this.selectedTier,
    this.searchQuery = '',
    this.sortOption = InventorySortOption.equippedFirst,
  });

  InventoryLoaded copyWith({
    InventoryOverview? overview,
    List<OwnedSkinItem>? filteredSkins,
    String? Function()? selectedTier,
    String? searchQuery,
    InventorySortOption? sortOption,
  }) {
    return InventoryLoaded(
      overview: overview ?? this.overview,
      filteredSkins: filteredSkins ?? this.filteredSkins,
      selectedTier:
          selectedTier != null ? selectedTier() : this.selectedTier,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  List<Object?> get props => [
        overview,
        filteredSkins,
        selectedTier,
        searchQuery,
        sortOption,
      ];
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
