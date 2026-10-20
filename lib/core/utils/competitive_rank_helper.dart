/// Resolves the active Competitive act and the rank/RR that belongs to it.
///
/// Riot's MMR payload does NOT expose `Tier` or `RankedRating` directly on
/// `QueueSkills.competitive`. Those legacy fields are absent and reading them
/// yields 0. Current rank lives in
/// `SeasonalInfoBySeasonID[activeActId]`, while `LatestCompetitiveUpdate` and
/// `CompetitiveUpdates` can refer to a previous act after an act reset.
library;

class CompetitiveAct {
  final String id;
  final String displayName;
  final String type;
  final DateTime? startTime;
  final DateTime? endTime;

  const CompetitiveAct({
    required this.id,
    this.displayName = '',
    this.type = '',
    this.startTime,
    this.endTime,
  });
}

class RankedSnapshot {
  final int tier;
  final int rating;
  final bool isRanked;
  final bool isPlacement;
  final int gamesNeededForRating;
  final String? seasonId;
  final bool hasCurrentActData;

  const RankedSnapshot({
    this.tier = 0,
    this.rating = 0,
    this.isRanked = false,
    this.isPlacement = false,
    this.gamesNeededForRating = 0,
    this.seasonId,
    this.hasCurrentActData = false,
  });

  static const empty = RankedSnapshot();

  String get label {
    if (isPlacement) return 'Placement';
    if (!isRanked) return 'Unrated';
    return '';
  }
}

class CompetitiveRankHelper {
  const CompetitiveRankHelper._();

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static bool _isAct(String type) {
    final normalized = type.toUpperCase();
    return normalized.contains('ACT');
  }

  /// Picks the act whose [startTime, endTime) range contains [now].
  ///
  /// valorant-api.com has no `isActive` flag; the only reliable signal is the
  /// UTC time window. Returns null between acts rather than guessing.
  static CompetitiveAct? resolveActiveAct(
    Iterable<Map<String, dynamic>> seasons, {
    DateTime? now,
  }) {
    final at = (now ?? DateTime.now()).toUtc();
    CompetitiveAct? active;

    for (final season in seasons) {
      final type = (season['type'] ?? season['Type'] ?? '').toString();
      if (!_isAct(type)) continue;

      final id = (season['uuid'] ?? season['id'] ?? season['ID'] ?? '')
          .toString()
          .trim();
      final start = _asDate(season['startTime'] ?? season['StartTime']);
      final end = _asDate(season['endTime'] ?? season['EndTime']);
      if (id.isEmpty || start == null || end == null) continue;

      final startUtc = start.toUtc();
      final endUtc = end.toUtc();
      if (!at.isBefore(startUtc) && at.isBefore(endUtc)) {
        if (active == null ||
            (startUtc.isAfter(active.startTime ?? DateTime(0)))) {
          active = CompetitiveAct(
            id: id,
            displayName:
                (season['displayName'] ?? season['DisplayName'] ?? '').toString(),
            type: type,
            startTime: startUtc,
            endTime: endUtc,
          );
        }
      }
    }

    return active;
  }

  static Map<String, dynamic>? competitiveQueue(Map<String, dynamic>? mmr) {
    final queueSkills = mmr?['QueueSkills'];
    if (queueSkills is! Map) return null;
    final competitive = queueSkills['competitive'];
    if (competitive is! Map) return null;
    return Map<String, dynamic>.from(competitive);
  }

  static Map<String, dynamic>? seasonData(
    Map<String, dynamic>? mmr,
    String? seasonId,
  ) {
    if (seasonId == null || seasonId.isEmpty) return null;
    final queue = competitiveQueue(mmr);
    final seasonal = queue?['SeasonalInfoBySeasonID'];
    if (seasonal is! Map) return null;
    final entry = seasonal[seasonId];
    if (entry is! Map) return null;
    return Map<String, dynamic>.from(entry);
  }

  static int? tierFromSeasonData(Map<String, dynamic>? data) {
    if (data == null) return null;
    return _asInt(data['CompetitiveTier']) ??
        _asInt(data['Rank']) ??
        _asInt(data['Tier']);
  }

  static int? ratingFromSeasonData(Map<String, dynamic>? data) {
    if (data == null) return null;
    return _asInt(data['RankedRating']) ??
        _asInt(data['RankRating']) ??
        _asInt(data['Rating']);
  }

  static int? gamesNeededFromSeasonData(Map<String, dynamic>? data) {
    if (data == null) return null;
    return _asInt(data['GamesNeededForRating']) ??
        _asInt(data['GamesNeededForRatingPlacement']);
  }

  static int _updateTimestamp(Map<String, dynamic> update) {
    return _asInt(update['MatchStartTime']) ??
        _asInt(update['MatchStartTimeMillis']) ??
        _asInt(update['StartTime']) ??
        0;
  }

  static String updateSeasonId(Map<String, dynamic> update) {
    return (update['SeasonID'] ??
            update['SeasonId'] ??
            update['seasonId'] ??
            '')
        .toString()
        .trim();
  }

  static int? tierAfterUpdate(Map<String, dynamic> update) {
    return _asInt(update['TierAfterUpdate']) ??
        _asInt(update['tierAfterUpdate']) ??
        _asInt(update['TierAfter']);
  }

  static int? ratingAfterUpdate(Map<String, dynamic> update) {
    return _asInt(update['RankedRatingAfterUpdate']) ??
        _asInt(update['RankRatingAfterUpdate']) ??
        _asInt(update['rankedRatingAfterUpdate']) ??
        _asInt(update['rankRatingAfterUpdate']);
  }

  /// Returns the official RR delta, preserving a real 0.
  ///
  /// The before/after formula is only used when Riot omits
  /// `RankedRatingEarned`; it must account for a tier boundary (100 RR).
  static int? rrEarnedFromUpdate(Map<String, dynamic> update) {
    final direct = _asInt(update['RankedRatingEarned']) ??
        _asInt(update['RankRatingEarned']) ??
        _asInt(update['rankedRatingEarned']) ??
        _asInt(update['rankRatingEarned']);
    if (direct != null) return direct;

    final ratingAfter = ratingAfterUpdate(update);
    final ratingBefore = _asInt(update['RankedRatingBeforeUpdate']) ??
        _asInt(update['RankRatingBeforeUpdate']) ??
        _asInt(update['rankedRatingBeforeUpdate']) ??
        _asInt(update['rankRatingBeforeUpdate']);
    if (ratingAfter == null || ratingBefore == null) return null;

    final tierAfter = tierAfterUpdate(update);
    final tierBefore = _asInt(update['TierBeforeUpdate']) ??
        _asInt(update['tierBeforeUpdate']) ??
        _asInt(update['TierBefore']);
    final tierDiff = (tierAfter != null && tierBefore != null)
        ? tierAfter - tierBefore
        : 0;

    return (tierDiff * 100) + (ratingAfter - ratingBefore);
  }

  /// Reads the current rank only from the active act.
  ///
  /// - SeasonalInfo entry for that act wins (tier/RR/placement).
  /// - Otherwise the newest update explicitly tagged with that act is used.
  /// - Updates from older acts are ignored, so an act reset never shows the
  ///   previous act's RR as the current one.
  static RankedSnapshot resolveCurrentRank({
    required Map<String, dynamic>? mmr,
    required String? activeSeasonId,
    List<Map<String, dynamic>> competitiveUpdates = const [],
  }) {
    final data = seasonData(mmr, activeSeasonId);
    if (data != null) {
      final tier = tierFromSeasonData(data) ?? 0;
      final rating = ratingFromSeasonData(data) ?? 0;
      final gamesNeeded = gamesNeededFromSeasonData(data) ?? 0;
      return RankedSnapshot(
        tier: tier,
        rating: rating,
        isRanked: tier > 0,
        isPlacement: gamesNeeded > 0,
        gamesNeededForRating: gamesNeeded,
        seasonId: activeSeasonId,
        hasCurrentActData: true,
      );
    }

    if (activeSeasonId == null || activeSeasonId.isEmpty) {
      return RankedSnapshot.empty;
    }

    final currentActUpdates = competitiveUpdates
        .where((u) => updateSeasonId(u) == activeSeasonId)
        .toList()
      ..sort((a, b) => _updateTimestamp(b).compareTo(_updateTimestamp(a)));

    for (final update in currentActUpdates) {
      final tier = tierAfterUpdate(update) ?? 0;
      final rating = ratingAfterUpdate(update) ?? 0;
      if (tier > 0 || rating > 0) {
        return RankedSnapshot(
          tier: tier,
          rating: rating,
          isRanked: tier > 0,
          seasonId: activeSeasonId,
          hasCurrentActData: true,
        );
      }
    }

    return RankedSnapshot(seasonId: activeSeasonId);
  }

  /// Highest tier found across all acts, excluding the current snapshot.
  static int? peakTierFromMmr(Map<String, dynamic>? mmr) {
    final queue = competitiveQueue(mmr);
    final seasonal = queue?['SeasonalInfoBySeasonID'];
    if (seasonal is! Map) return null;

    int? peak;
    for (final entry in seasonal.values) {
      if (entry is! Map) continue;
      final data = Map<String, dynamic>.from(entry);
      final tier = tierFromSeasonData(data) ?? 0;
      final badgeInfo = data['SeasonalBadgeInfo'];
      final badge =
          badgeInfo is Map ? (_asInt(badgeInfo['Rank']) ?? 0) : 0;
      if (tier > (peak ?? 0)) peak = tier;
      if (badge > (peak ?? 0)) peak = badge;
    }
    return peak != null && peak > 0 ? peak : null;
  }
}
