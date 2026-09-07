import 'package:equatable/equatable.dart';
import 'match_summary.dart';

class CareerOverview extends Equatable {
  final int currentTier;
  final String currentTierName;
  final String? currentTierIcon;
  final int currentRankRating;
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

  const CareerOverview({
    this.currentTier = 0,
    this.currentTierName = 'Unrated',
    this.currentTierIcon,
    this.currentRankRating = 0,
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
  });

  Map<String, dynamic> toJson() {
    return {
      'currentTier': currentTier,
      'currentTierName': currentTierName,
      'currentTierIcon': currentTierIcon,
      'currentRankRating': currentRankRating,
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
    );
  }

  @override
  List<Object?> get props => [
        currentTier,
        currentTierName,
        currentTierIcon,
        currentRankRating,
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
      ];
}
