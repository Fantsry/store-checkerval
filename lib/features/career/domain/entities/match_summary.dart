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
  final List<MatchPlayerSummary> teammates;
  final List<MatchPlayerSummary> enemies;
  final List<MatchRoundSummary> rounds;

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
    this.teammates = const [],
    this.enemies = const [],
    this.rounds = const [],
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

  bool get isDeathmatch =>
      queueId.toLowerCase().trim() == 'deathmatch' ||
      gameMode.toLowerCase().contains('deathmatch');

  List<MatchPlayerSummary> get allPlayers {
    final list = [...teammates, ...enemies];
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  String? get matchMvpPuuid {
    final all = allPlayers;
    return all.isNotEmpty ? all.first.puuid : null;
  }

  String? get teamMvpPuuid {
    return teammates.isNotEmpty ? teammates.first.puuid : null;
  }

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
      'teammates': teammates.map((p) => p.toJson()).toList(),
      'enemies': enemies.map((p) => p.toJson()).toList(),
      'rounds': rounds.map((r) => r.toJson()).toList(),
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
      teammates: (json['teammates'] as List?)
              ?.map((e) =>
                  MatchPlayerSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      enemies: (json['enemies'] as List?)
              ?.map((e) =>
                  MatchPlayerSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      rounds: (json['rounds'] as List?)
              ?.map((e) =>
                  MatchRoundSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
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
        teammates,
        enemies,
        rounds,
      ];
}

class MatchPlayerSummary extends Equatable {
  final String puuid;
  final String gameName;
  final String tagLine;
  final String teamId;
  final String agentId;
  final String agentName;
  final String? agentIconUrl;
  final int? competitiveTier;
  final String? rankName;
  final String? rankIconUrl;
  final int kills;
  final int deaths;
  final int assists;
  final int score;
  final int roundsPlayed;
  final int averageCombatScore;
  final bool isSelf;

  const MatchPlayerSummary({
    required this.puuid,
    this.gameName = '',
    this.tagLine = '',
    required this.teamId,
    required this.agentId,
    required this.agentName,
    this.agentIconUrl,
    this.competitiveTier,
    this.rankName,
    this.rankIconUrl,
    this.kills = 0,
    this.deaths = 0,
    this.assists = 0,
    this.score = 0,
    this.roundsPlayed = 0,
    this.averageCombatScore = 0,
    this.isSelf = false,
  });

  double get kdRatio => deaths > 0 ? (kills / deaths) : kills.toDouble();

  String get kdaDisplay => '$kills / $deaths / $assists';

  String get displayName {
    if (gameName.isNotEmpty) {
      return tagLine.isNotEmpty ? '$gameName#$tagLine' : gameName;
    }
    return agentName;
  }

  Map<String, dynamic> toJson() {
    return {
      'puuid': puuid,
      'gameName': gameName,
      'tagLine': tagLine,
      'teamId': teamId,
      'agentId': agentId,
      'agentName': agentName,
      'agentIconUrl': agentIconUrl,
      'competitiveTier': competitiveTier,
      'rankName': rankName,
      'rankIconUrl': rankIconUrl,
      'kills': kills,
      'deaths': deaths,
      'assists': assists,
      'score': score,
      'roundsPlayed': roundsPlayed,
      'averageCombatScore': averageCombatScore,
      'isSelf': isSelf,
    };
  }

  factory MatchPlayerSummary.fromJson(Map<String, dynamic> json) {
    return MatchPlayerSummary(
      puuid: json['puuid'] as String? ?? '',
      gameName: json['gameName'] as String? ?? '',
      tagLine: json['tagLine'] as String? ?? '',
      teamId: json['teamId'] as String? ?? '',
      agentId: json['agentId'] as String? ?? '',
      agentName: json['agentName'] as String? ?? 'Agent',
      agentIconUrl: json['agentIconUrl'] as String?,
      competitiveTier: (json['competitiveTier'] as num?)?.toInt(),
      rankName: json['rankName'] as String?,
      rankIconUrl: json['rankIconUrl'] as String?,
      kills: (json['kills'] as num?)?.toInt() ?? 0,
      deaths: (json['deaths'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      roundsPlayed: (json['roundsPlayed'] as num?)?.toInt() ?? 0,
      averageCombatScore: (json['averageCombatScore'] as num?)?.toInt() ?? 0,
      isSelf: json['isSelf'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        puuid,
        gameName,
        tagLine,
        teamId,
        agentId,
        agentName,
        agentIconUrl,
        competitiveTier,
        rankName,
        rankIconUrl,
        kills,
        deaths,
        assists,
        score,
        roundsPlayed,
        averageCombatScore,
        isSelf,
      ];
}

class MatchRoundKill extends Equatable {
  final int roundTime;
  final String killerPuuid;
  final String killerName;
  final String killerAgentName;
  final String? killerAgentIconUrl;
  final String killerTeamId;
  final String victimPuuid;
  final String victimName;
  final String victimAgentName;
  final String? victimAgentIconUrl;
  final String victimTeamId;
  final List<String> assistantPuuids;
  final List<String> assistantNames;
  final String? weaponId;
  final bool isKillerSelf;
  final bool isVictimSelf;

  const MatchRoundKill({
    this.roundTime = 0,
    required this.killerPuuid,
    this.killerName = '',
    this.killerAgentName = 'Agent',
    this.killerAgentIconUrl,
    this.killerTeamId = '',
    required this.victimPuuid,
    this.victimName = '',
    this.victimAgentName = 'Agent',
    this.victimAgentIconUrl,
    this.victimTeamId = '',
    this.assistantPuuids = const [],
    this.assistantNames = const [],
    this.weaponId,
    this.isKillerSelf = false,
    this.isVictimSelf = false,
  });

  Map<String, dynamic> toJson() => {
        'roundTime': roundTime,
        'killerPuuid': killerPuuid,
        'killerName': killerName,
        'killerAgentName': killerAgentName,
        'killerAgentIconUrl': killerAgentIconUrl,
        'killerTeamId': killerTeamId,
        'victimPuuid': victimPuuid,
        'victimName': victimName,
        'victimAgentName': victimAgentName,
        'victimAgentIconUrl': victimAgentIconUrl,
        'victimTeamId': victimTeamId,
        'assistantPuuids': assistantPuuids,
        'assistantNames': assistantNames,
        'weaponId': weaponId,
        'isKillerSelf': isKillerSelf,
        'isVictimSelf': isVictimSelf,
      };

  factory MatchRoundKill.fromJson(Map<String, dynamic> json) => MatchRoundKill(
        roundTime: (json['roundTime'] as num?)?.toInt() ?? 0,
        killerPuuid: json['killerPuuid'] as String? ?? '',
        killerName: json['killerName'] as String? ?? '',
        killerAgentName: json['killerAgentName'] as String? ?? 'Agent',
        killerAgentIconUrl: json['killerAgentIconUrl'] as String?,
        killerTeamId: json['killerTeamId'] as String? ?? '',
        victimPuuid: json['victimPuuid'] as String? ?? '',
        victimName: json['victimName'] as String? ?? '',
        victimAgentName: json['victimAgentName'] as String? ?? 'Agent',
        victimAgentIconUrl: json['victimAgentIconUrl'] as String?,
        victimTeamId: json['victimTeamId'] as String? ?? '',
        assistantPuuids: (json['assistantPuuids'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        assistantNames: (json['assistantNames'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        weaponId: json['weaponId'] as String?,
        isKillerSelf: json['isKillerSelf'] as bool? ?? false,
        isVictimSelf: json['isVictimSelf'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        roundTime,
        killerPuuid,
        killerName,
        killerAgentName,
        killerAgentIconUrl,
        killerTeamId,
        victimPuuid,
        victimName,
        victimAgentName,
        victimAgentIconUrl,
        victimTeamId,
        assistantPuuids,
        assistantNames,
        weaponId,
        isKillerSelf,
        isVictimSelf,
      ];
}

class MatchRoundSummary extends Equatable {
  final int roundNum;
  final String winningTeam;
  final bool? won;
  final String roundResult;
  final List<MatchRoundKill> kills;

  const MatchRoundSummary({
    required this.roundNum,
    this.winningTeam = '',
    this.won,
    this.roundResult = '',
    this.kills = const [],
  });

  Map<String, dynamic> toJson() => {
        'roundNum': roundNum,
        'winningTeam': winningTeam,
        'won': won,
        'roundResult': roundResult,
        'kills': kills.map((k) => k.toJson()).toList(),
      };

  factory MatchRoundSummary.fromJson(Map<String, dynamic> json) =>
      MatchRoundSummary(
        roundNum: (json['roundNum'] as num?)?.toInt() ?? 0,
        winningTeam: json['winningTeam'] as String? ?? '',
        won: json['won'] as bool?,
        roundResult: json['roundResult'] as String? ?? '',
        kills: (json['kills'] as List?)
                ?.map((k) =>
                    MatchRoundKill.fromJson(k as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [roundNum, winningTeam, won, roundResult, kills];
}
