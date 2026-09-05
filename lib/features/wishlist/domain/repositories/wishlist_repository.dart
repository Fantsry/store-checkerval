import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';

abstract class WishlistRepository {
  /// Gets all wishlisted items.
  Future<Result<List<WishlistItem>>> getWishlist();

  /// Adds a skin to wishlist.
  Future<Result<void>> addToWishlist(WishlistItem item);

  /// Removes a skin from wishlist by UUID.
  Future<Result<void>> removeFromWishlist(String skinUuid);

  /// Checks if a skin is currently in wishlist.
  bool isInWishlist(String skinUuid);

  /// Clears all wishlist items.
  Future<Result<void>> clearWishlist();

  /// Searches skin catalog with optional query, weapon filter, and tier filter.
  Future<Result<List<SkinItem>>> searchCatalog({
    String? query,
    String? weaponType,
    String? tier,
  });
}
