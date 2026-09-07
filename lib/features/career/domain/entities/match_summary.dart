import 'package:equatable/equatable.dart';

class MatchSummary extends Equatable {
  final String matchId;
  final String mapId;
  final String mapName;
  final String? mapImageUrl;
  final String gameMode;
  final String queueId;
  final DateTime gameStartTime;
  final int gameLengthMillis;
  final bool? won;
  final bool isDraw;
  final int scoreWon;
  final int scoreLost;
  final String agentId;
  final String agentName;
  final String? agentIconUrl;
  final int kills;
  final int deaths;
  final int assists;
  final int score;
  final int roundsPlayed;
  final int averageCombatScore;
  final int headshots;
  final int bodyshots;
  final int legshots;
  final int damage;
  final int? rankRatingEarned;
  final int? competitiveTier;
  final String? rankName;
  final String? rankIconUrl;

  const MatchSummary({
    required this.matchId,
    required this.mapId,
    required this.mapName,
    this.mapImageUrl,
    required this.gameMode,
    required this.queueId,
    required this.gameStartTime,
    this.gameLengthMillis = 0,
    this.won,
    this.isDraw = false,
    this.scoreWon = 0,
    this.scoreLost = 0,
    required this.agentId,
    required this.agentName,
    this.agentIconUrl,
    this.kills = 0,
    this.deaths = 0,
    this.assists = 0,
    this.score = 0,
    this.roundsPlayed = 0,
    this.averageCombatScore = 0,
    this.headshots = 0,
    this.bodyshots = 0,
    this.legshots = 0,
    this.damage = 0,
    this.rankRatingEarned,
    this.competitiveTier,
    this.rankName,
    this.rankIconUrl,
  });

  double get kdRatio => deaths > 0 ? (kills / deaths) : kills.toDouble();

  int get totalShots => headshots + bodyshots + legshots;

  int get headshotPercentage =>
      totalShots > 0 ? ((headshots / totalShots) * 100).round() : 0;

  String get queueDisplayName {
    final q = queueId.toLowerCase().trim();
    switch (q) {
      case 'competitive':
        return 'Competitive';
      case 'unrated':
        return 'Unrated';
      case 'swiftplay':
        return 'Swiftplay';
      case 'spikerush':
        return 'Spike Rush';
      case 'deathmatch':
        return 'Deathmatch';
      case 'hurm':
        return 'Team Deathmatch';
      case 'ggteam':
        return 'Escalation';
      case 'onefa':
        return 'Replication';
      case 'snowball':
        return 'Snowball Fight';
      case 'custom':
        return 'Custom Game';
      default:
        return q.isNotEmpty ? (q[0].toUpperCase() + q.substring(1)) : 'Match';
    }
  }

  String get resultText {
    if (isDraw) return 'DRAW';
    if (won == true) return 'VICTORY';
    if (won == false) return 'DEFEAT';
    return 'COMPLETED';
  }

  String get scoreDisplay => '$scoreWon - $scoreLost';

  String get kdaDisplay => '$kills / $deaths / $assists';

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'mapId': mapId,
      'mapName': mapName,
      'mapImageUrl': mapImageUrl,
      'gameMode': gameMode,
      'queueId': queueId,
      'gameStartTime': gameStartTime.toIso8601String(),
      'gameLengthMillis': gameLengthMillis,
      'won': won,
      'isDraw': isDraw,
      'scoreWon': scoreWon,
      'scoreLost': scoreLost,
      'agentId': agentId,
      'agentName': agentName,
      'agentIconUrl': agentIconUrl,
      'kills': kills,
      'deaths': deaths,
      'assists': assists,
      'score': score,
      'roundsPlayed': roundsPlayed,
      'averageCombatScore': averageCombatScore,
      'headshots': headshots,
      'bodyshots': bodyshots,
      'legshots': legshots,
      'damage': damage,
      'rankRatingEarned': rankRatingEarned,
      'competitiveTier': competitiveTier,
      'rankName': rankName,
      'rankIconUrl': rankIconUrl,
    };
  }

  factory MatchSummary.fromJson(Map<String, dynamic> json) {
    return MatchSummary(
      matchId: json['matchId'] as String? ?? '',
      mapId: json['mapId'] as String? ?? '',
      mapName: json['mapName'] as String? ?? 'Unknown Map',
      mapImageUrl: json['mapImageUrl'] as String?,
      gameMode: json['gameMode'] as String? ?? '',
      queueId: json['queueId'] as String? ?? 'unrated',
      gameStartTime: DateTime.tryParse(json['gameStartTime'] as String? ?? '') ??
          DateTime.now(),
      gameLengthMillis: (json['gameLengthMillis'] as num?)?.toInt() ?? 0,
      won: json['won'] as bool?,
      isDraw: json['isDraw'] as bool? ?? false,
      scoreWon: (json['scoreWon'] as num?)?.toInt() ?? 0,
      scoreLost: (json['scoreLost'] as num?)?.toInt() ?? 0,
      agentId: json['agentId'] as String? ?? '',
      agentName: json['agentName'] as String? ?? 'Unknown Agent',
      agentIconUrl: json['agentIconUrl'] as String?,
      kills: (json['kills'] as num?)?.toInt() ?? 0,
      deaths: (json['deaths'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      roundsPlayed: (json['roundsPlayed'] as num?)?.toInt() ?? 0,
      averageCombatScore: (json['averageCombatScore'] as num?)?.toInt() ?? 0,
      headshots: (json['headshots'] as num?)?.toInt() ?? 0,
      bodyshots: (json['bodyshots'] as num?)?.toInt() ?? 0,
      legshots: (json['legshots'] as num?)?.toInt() ?? 0,
      damage: (json['damage'] as num?)?.toInt() ?? 0,
      rankRatingEarned: (json['rankRatingEarned'] as num?)?.toInt(),
      competitiveTier: (json['competitiveTier'] as num?)?.toInt(),
      rankName: json['rankName'] as String?,
      rankIconUrl: json['rankIconUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        matchId,
        mapId,
        mapName,
        mapImageUrl,
        gameMode,
        queueId,
        gameStartTime,
        gameLengthMillis,
        won,
        isDraw,
        scoreWon,
        scoreLost,
        agentId,
        agentName,
        agentIconUrl,
        kills,
        deaths,
        assists,
        score,
        roundsPlayed,
        averageCombatScore,
        headshots,
        bodyshots,
        legshots,
        damage,
        rankRatingEarned,
        competitiveTier,
        rankName,
        rankIconUrl,
      ];
}
