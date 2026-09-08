import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_match_data.dart';

abstract class LiveMatchRepository {
  /// Queries GLZ coregame and pregame endpoints to detect active match state and players.
  Future<Result<LiveMatchData>> checkLiveMatch();
}
