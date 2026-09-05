import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';

abstract class StoreRepository {
  /// Fetches daily store (4 skins + countdown + featured bundle).
  Future<Result<DailyStore>> getDailyStore({bool forceRefresh = false});

  /// Fetches user's current VP and Radianite balances.
  Future<Result<UserWallet>> getUserWallet();

  /// Gets single skin metadata by UUID.
  Future<Result<SkinItem>> getSkinDetail(String skinUuid);

  /// Fetches all weapon skins catalog from valorant-api.com (with local cache).
  Future<Result<List<SkinItem>>> getAllCatalogSkins();
}
