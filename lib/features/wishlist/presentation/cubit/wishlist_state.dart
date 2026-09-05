import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';

sealed class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {
  const WishlistInitial();
}

class WishlistLoading extends WishlistState {
  const WishlistLoading();
}

class WishlistLoaded extends WishlistState {
  final List<WishlistItem> items;
  final List<SkinItem> catalog;
  final String searchQuery;
  final String selectedWeapon;
  final bool isSearching;

  const WishlistLoaded({
    required this.items,
    this.catalog = const [],
    this.searchQuery = '',
    this.selectedWeapon = 'All',
    this.isSearching = false,
  });

  bool isInWishlist(String skinUuid) {
    return items.any((i) => i.uuid.toLowerCase() == skinUuid.toLowerCase());
  }

  WishlistLoaded copyWith({
    List<WishlistItem>? items,
    List<SkinItem>? catalog,
    String? searchQuery,
    String? selectedWeapon,
    bool? isSearching,
  }) {
    return WishlistLoaded(
      items: items ?? this.items,
      catalog: catalog ?? this.catalog,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedWeapon: selectedWeapon ?? this.selectedWeapon,
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props => [
        items,
        catalog,
        searchQuery,
        selectedWeapon,
        isSearching,
      ];
}

class WishlistError extends WishlistState {
  final String message;
  const WishlistError(this.message);

  @override
  List<Object?> get props => [message];
}
