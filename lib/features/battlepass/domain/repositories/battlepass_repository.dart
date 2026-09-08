import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/battlepass_overview.dart';

abstract class BattlepassRepository {
  Future<Result<BattlepassOverview>> getBattlepassOverview({
    bool forceRefresh = false,
  });
}
