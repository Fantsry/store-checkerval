import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';

abstract class CareerRepository {
  /// Fetches player career stats, MMR/Rank, and recent match history.
  Future<Result<CareerOverview>> getCareerOverview({bool forceRefresh = false});

  /// Fetches detailed match data for a single match.
  Future<Result<MatchSummary>> getMatchDetail(String matchId);
}
