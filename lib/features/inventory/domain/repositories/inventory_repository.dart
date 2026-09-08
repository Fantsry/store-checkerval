import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';

abstract class InventoryRepository {
  /// Fetches player owned skins, equipped loadout, and calculates account value.
  Future<Result<InventoryOverview>> getInventoryOverview({
    bool forceRefresh = false,
  });
}
