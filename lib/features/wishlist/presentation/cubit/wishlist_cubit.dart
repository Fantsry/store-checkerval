import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  final WishlistRepository _wishlistRepository;

  WishlistCubit({required WishlistRepository wishlistRepository})
      : _wishlistRepository = wishlistRepository,
        super(const WishlistInitial());

  Future<void> loadWishlist() async {
    emit(const WishlistLoading());
    final result = await _wishlistRepository.getWishlist();
    final catalogResult = await _wishlistRepository.searchCatalog();

    result.when(
      success: (items) {
        emit(
          WishlistLoaded(
            items: items,
            catalog: catalogResult.valueOrNull ?? [],
          ),
        );
      },
      failure: (failure) => emit(WishlistError(failure.message)),
    );
  }

  Future<void> toggleWishlist(SkinItem skin) async {
    final currentState = state;
    if (currentState is WishlistLoaded) {
      final exists = currentState.isInWishlist(skin.uuid);
      if (exists) {
        await _wishlistRepository.removeFromWishlist(skin.uuid);
        final updatedItems = currentState.items
            .where((i) => i.uuid.toLowerCase() != skin.uuid.toLowerCase())
            .toList();
        emit(currentState.copyWith(items: updatedItems));
      } else {
        final newItem = WishlistItem.fromSkinItem(skin);
        await _wishlistRepository.addToWishlist(newItem);
        final updatedItems = [newItem, ...currentState.items];
        emit(currentState.copyWith(items: updatedItems));
      }
    }
  }

  Future<void> searchCatalog({String? query, String? weapon}) async {
    final currentState = state;
    if (currentState is WishlistLoaded) {
      emit(currentState.copyWith(
        isSearching: true,
        searchQuery: query ?? currentState.searchQuery,
        selectedWeapon: weapon ?? currentState.selectedWeapon,
      ));

      final result = await _wishlistRepository.searchCatalog(
        query: query ?? currentState.searchQuery,
        weaponType: weapon ?? currentState.selectedWeapon,
      );

      emit(
        currentState.copyWith(
          isSearching: false,
          searchQuery: query ?? currentState.searchQuery,
          selectedWeapon: weapon ?? currentState.selectedWeapon,
          catalog: result.valueOrNull ?? currentState.catalog,
        ),
      );
    }
  }

  Future<void> clearAll() async {
    await _wishlistRepository.clearWishlist();
    if (state is WishlistLoaded) {
      emit((state as WishlistLoaded).copyWith(items: []));
    }
  }
}
