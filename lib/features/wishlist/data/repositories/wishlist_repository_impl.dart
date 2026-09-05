import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/repositories/store_repository.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/repositories/wishlist_repository.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final LocalStoreService _localStore;
  final StoreRepository _storeRepository;

  WishlistRepositoryImpl({
    required LocalStoreService localStore,
    required StoreRepository storeRepository,
  })  : _localStore = localStore,
        _storeRepository = storeRepository;

  @override
  Future<Result<List<WishlistItem>>> getWishlist() async {
    try {
      final items = await _localStore.getWishlist();
      return Result.success(items);
    } catch (e) {
      return Result.failure(CacheFailure(message: 'Failed to load wishlist: $e'));
    }
  }

  @override
  Future<Result<void>> addToWishlist(WishlistItem item) async {
    try {
      await _localStore.addToWishlist(item);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: 'Failed to add to wishlist: $e'));
    }
  }

  @override
  Future<Result<void>> removeFromWishlist(String skinUuid) async {
    try {
      await _localStore.removeFromWishlist(skinUuid);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to remove from wishlist: $e'),
      );
    }
  }

  @override
  bool isInWishlist(String skinUuid) {
    return _localStore.isInWishlist(skinUuid);
  }

  @override
  Future<Result<void>> clearWishlist() async {
    try {
      await _localStore.clearWishlist();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to clear wishlist: $e'),
      );
    }
  }

  @override
  Future<Result<List<SkinItem>>> searchCatalog({
    String? query,
    String? weaponType,
    String? tier,
  }) async {
    try {
      final allResult = await _storeRepository.getAllCatalogSkins();
      if (allResult.isFailure) {
        return allResult;
      }

      var list = allResult.valueOrNull ?? [];

      // Query filter
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        list = list.where((s) => s.displayName.toLowerCase().contains(q)).toList();
      }

      // Weapon filter
      if (weaponType != null &&
          weaponType.trim().isNotEmpty &&
          weaponType.toLowerCase() != 'all') {
        final w = weaponType.trim().toLowerCase();
        list = list.where((s) {
          final skinWeapon = s.weaponName?.toLowerCase() ?? '';
          final skinDisplay = s.displayName.toLowerCase();
          return skinWeapon.contains(w) || skinDisplay.contains(w);
        }).toList();
      }

      // Tier filter
      if (tier != null &&
          tier.trim().isNotEmpty &&
          tier.toLowerCase() != 'all') {
        final t = tier.trim().toLowerCase();
        list = list.where((s) {
          final skinTier = s.tierName?.toLowerCase() ?? '';
          return skinTier.contains(t);
        }).toList();
      }

      return Result.success(list);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Search failed: $e'));
    }
  }
}
