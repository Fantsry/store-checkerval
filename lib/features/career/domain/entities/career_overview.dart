import 'package:equatable/equatable.dart';
import 'match_summary.dart';

class CareerOverview extends Equatable {
  final int currentTier;
  final String currentTierName;
  final String? currentTierIcon;
  final int currentRankRating;
  final bool isRanked;
  final bool isPlacement;
  final int? gamesNeededForRating;
  final String? seasonId;
  final int? peakTier;
  final String? peakTierName;
  final String? peakTierIcon;
  final int totalMatches;
  final int totalWins;
  final int totalLosses;
  final double winRate;
  final int avgCombatScore;
  final double avgKdRatio;
  final double avgHeadshotPct;
  final List<MatchSummary> matches;
  final bool hasMore;

  const CareerOverview({
    this.currentTier = 0,
    this.currentTierName = 'Unrated',
    this.currentTierIcon,
    this.currentRankRating = 0,
    this.isRanked = false,
    this.isPlacement = false,
    this.gamesNeededForRating,
    this.seasonId,
    this.peakTier,
    this.peakTierName,
    this.peakTierIcon,
    this.totalMatches = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.winRate = 0.0,
    this.avgCombatScore = 0,
    this.avgKdRatio = 0.0,
    this.avgHeadshotPct = 0.0,
    this.matches = const [],
    this.hasMore = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentTier': currentTier,
      'currentTierName': currentTierName,
      'currentTierIcon': currentTierIcon,
      'currentRankRating': currentRankRating,
      'isRanked': isRanked,
      'isPlacement': isPlacement,
      'gamesNeededForRating': gamesNeededForRating,
      'seasonId': seasonId,
      'peakTier': peakTier,
      'peakTierName': peakTierName,
      'peakTierIcon': peakTierIcon,
      'totalMatches': totalMatches,
      'totalWins': totalWins,
      'totalLosses': totalLosses,
      'winRate': winRate,
      'avgCombatScore': avgCombatScore,
      'avgKdRatio': avgKdRatio,
      'avgHeadshotPct': avgHeadshotPct,
      'matches': matches.map((m) => m.toJson()).toList(),
      'hasMore': hasMore,
    };
  }

  factory CareerOverview.fromJson(Map<String, dynamic> json) {
    final matchesList = (json['matches'] as List<dynamic>?)
            ?.map((m) => MatchSummary.fromJson(m as Map<String, dynamic>))
            .toList() ??
        const [];

    return CareerOverview(
      currentTier: json['currentTier'] as int? ?? 0,
      currentTierName: json['currentTierName'] as String? ?? 'Unrated',
      currentTierIcon: json['currentTierIcon'] as String?,
      currentRankRating: json['currentRankRating'] as int? ?? 0,
      isRanked: json['isRanked'] as bool? ??
          ((json['currentTier'] as int? ?? 0) > 0),
      isPlacement: json['isPlacement'] as bool? ?? false,
      gamesNeededForRating:
          (json['gamesNeededForRating'] as num?)?.toInt(),
      seasonId: json['seasonId'] as String?,
      peakTier: json['peakTier'] as int?,
      peakTierName: json['peakTierName'] as String?,
      peakTierIcon: json['peakTierIcon'] as String?,
      totalMatches: json['totalMatches'] as int? ?? matchesList.length,
      totalWins: json['totalWins'] as int? ?? 0,
      totalLosses: json['totalLosses'] as int? ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      avgCombatScore: json['avgCombatScore'] as int? ?? 0,
      avgKdRatio: (json['avgKdRatio'] as num?)?.toDouble() ?? 0.0,
      avgHeadshotPct: (json['avgHeadshotPct'] as num?)?.toDouble() ?? 0.0,
      matches: matchesList,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  CareerOverview withMatches(
    List<MatchSummary> updatedMatches, {
    bool? hasMore,
  }) {
    final totalMatches = updatedMatches.length;
    final totalWins = updatedMatches.where((m) => m.won == true).length;
    final totalLosses = updatedMatches.where((m) => m.won == false).length;
    final winRate =
        totalMatches > 0 ? (totalWins / totalMatches) * 100 : 0.0;

    var sumScore = 0;
    var sumKills = 0;
    var sumDeaths = 0;
    var sumHs = 0;
    var sumBs = 0;
    var sumLs = 0;
    for (final m in updatedMatches) {
      sumScore += m.averageCombatScore;
      sumKills += m.kills;
      sumDeaths += m.deaths;
      sumHs += m.headshots;
      sumBs += m.bodyshots;
      sumLs += m.legshots;
    }

    final totalHits = sumHs + sumBs + sumLs;
    return CareerOverview(
      currentTier: currentTier,
      currentTierName: currentTierName,
      currentTierIcon: currentTierIcon,
      currentRankRating: currentRankRating,
      isRanked: isRanked,
      isPlacement: isPlacement,
      gamesNeededForRating: gamesNeededForRating,
      seasonId: seasonId,
      peakTier: peakTier,
      peakTierName: peakTierName,
      peakTierIcon: peakTierIcon,
      totalMatches: totalMatches,
      totalWins: totalWins,
      totalLosses: totalLosses,
      winRate: winRate,
      avgCombatScore:
          totalMatches > 0 ? (sumScore / totalMatches).round() : 0,
      avgKdRatio: sumDeaths > 0
          ? sumKills / sumDeaths
          : (sumKills > 0 ? sumKills.toDouble() : 0.0),
      avgHeadshotPct: totalHits > 0 ? (sumHs / totalHits) * 100 : 0.0,
      matches: updatedMatches,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [
        currentTier,
        currentTierName,
        currentTierIcon,
        currentRankRating,
        isRanked,
        isPlacement,
        gamesNeededForRating,
        seasonId,
        peakTier,
        peakTierName,
        peakTierIcon,
        totalMatches,
        totalWins,
        totalLosses,
        winRate,
        avgCombatScore,
        avgKdRatio,
        avgHeadshotPct,
        matches,
        hasMore,
      ];
}
