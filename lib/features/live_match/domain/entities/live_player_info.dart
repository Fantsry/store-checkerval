import 'package:equatable/equatable.dart';

class LivePlayerInfo extends Equatable {
  final String puuid;
  final String gameName;
  final String tagLine;
  final String teamId; // 'Blue', 'Red', 'Ally'
  final String? agentName;
  final String? agentIcon;
  final String currentRankTierName;
  final String? rankIcon;
  final int currentRr;
  final String peakRankTierName;
  final String? peakRankIcon;
  final int accountLevel;
  final bool isSelf;
  final bool isLocked;
  final int recentWins;
  final int recentLosses;
  final List<bool> recentMatchOutcomes; // true = win, false = loss (up to 10)

  // ─── Extended Live Stats ──────────────────────────────────────
  final double? averageCombatScore; // ACS
  final double? kdRatio; // K/D
  final double? kastPercentage; // KAST%
  final double? kda; // KDA
  final double? averageDamageRound; // ADR
  final double? headshotPercentage; // HS%
  final double? winPercentage; // WIN%
  final int? lastNActScore; // LAST 15/20 acting score
  final int? lastNMatchCount; // how many matches "LAST N" (15 or 20)
  final String? currentRankEpisodeAct; // e.g. "E26A4"
  final String? peakRankEpisodeAct; // e.g. "E25A3"

  // ─── Player Card Banner (Landscape Wide Art) ───────────────────
  final String? cardUuid;
  final String? cardWideArt; // Wide / Landscape Player Card Banner
  final String? cardSmallArt;
  final String? cardLargeArt;
  final String? cardName;

  const LivePlayerInfo({
    required this.puuid,
    required this.gameName,
    this.tagLine = '',
    this.teamId = 'Blue',
    this.agentName,
    this.agentIcon,
    this.currentRankTierName = 'Unranked',
    this.rankIcon,
    this.currentRr = 0,
    this.peakRankTierName = 'Unranked',
    this.peakRankIcon,
    this.accountLevel = 1,
    this.isSelf = false,
    this.isLocked = true,
    this.recentWins = 0,
    this.recentLosses = 0,
    this.recentMatchOutcomes = const [],
    // Extended stats
    this.averageCombatScore,
    this.kdRatio,
    this.kastPercentage,
    this.kda,
    this.averageDamageRound,
    this.headshotPercentage,
    this.winPercentage,
    this.lastNActScore,
    this.lastNMatchCount,
    this.currentRankEpisodeAct,
    this.peakRankEpisodeAct,
    // Player Card Banner
    this.cardUuid,
    this.cardWideArt,
    this.cardSmallArt,
    this.cardLargeArt,
    this.cardName,
  });

  String get displayName =>
      tagLine.isNotEmpty ? '$gameName #$tagLine' : gameName;

  int get recentTotalMatches => recentWins + recentLosses;

  double? get recentWinRate =>
      recentTotalMatches > 0 ? (recentWins / recentTotalMatches) * 100 : null;

  LivePlayerInfo copyWith({
    String? puuid,
    String? gameName,
    String? tagLine,
    String? teamId,
    String? agentName,
    String? agentIcon,
    String? currentRankTierName,
    String? rankIcon,
    int? currentRr,
    String? peakRankTierName,
    String? peakRankIcon,
    int? accountLevel,
    bool? isSelf,
    bool? isLocked,
    int? recentWins,
    int? recentLosses,
    List<bool>? recentMatchOutcomes,
    double? averageCombatScore,
    double? kdRatio,
    double? kastPercentage,
    double? kda,
    double? averageDamageRound,
    double? headshotPercentage,
    double? winPercentage,
    int? lastNActScore,
    int? lastNMatchCount,
    String? currentRankEpisodeAct,
    String? peakRankEpisodeAct,
    String? cardUuid,
    String? cardWideArt,
    String? cardSmallArt,
    String? cardLargeArt,
    String? cardName,
  }) {
    return LivePlayerInfo(
      puuid: puuid ?? this.puuid,
      gameName: gameName ?? this.gameName,
      tagLine: tagLine ?? this.tagLine,
      teamId: teamId ?? this.teamId,
      agentName: agentName ?? this.agentName,
      agentIcon: agentIcon ?? this.agentIcon,
      currentRankTierName: currentRankTierName ?? this.currentRankTierName,
      rankIcon: rankIcon ?? this.rankIcon,
      currentRr: currentRr ?? this.currentRr,
      peakRankTierName: peakRankTierName ?? this.peakRankTierName,
      peakRankIcon: peakRankIcon ?? this.peakRankIcon,
      accountLevel: accountLevel ?? this.accountLevel,
      isSelf: isSelf ?? this.isSelf,
      isLocked: isLocked ?? this.isLocked,
      recentWins: recentWins ?? this.recentWins,
      recentLosses: recentLosses ?? this.recentLosses,
      recentMatchOutcomes: recentMatchOutcomes ?? this.recentMatchOutcomes,
      averageCombatScore: averageCombatScore ?? this.averageCombatScore,
      kdRatio: kdRatio ?? this.kdRatio,
      kastPercentage: kastPercentage ?? this.kastPercentage,
      kda: kda ?? this.kda,
      averageDamageRound: averageDamageRound ?? this.averageDamageRound,
      headshotPercentage: headshotPercentage ?? this.headshotPercentage,
      winPercentage: winPercentage ?? this.winPercentage,
      lastNActScore: lastNActScore ?? this.lastNActScore,
      lastNMatchCount: lastNMatchCount ?? this.lastNMatchCount,
      currentRankEpisodeAct: currentRankEpisodeAct ?? this.currentRankEpisodeAct,
      peakRankEpisodeAct: peakRankEpisodeAct ?? this.peakRankEpisodeAct,
      cardUuid: cardUuid ?? this.cardUuid,
      cardWideArt: cardWideArt ?? this.cardWideArt,
      cardSmallArt: cardSmallArt ?? this.cardSmallArt,
      cardLargeArt: cardLargeArt ?? this.cardLargeArt,
      cardName: cardName ?? this.cardName,
    );
  }

  Map<String, dynamic> toJson() => {
        'puuid': puuid,
        'gameName': gameName,
        'tagLine': tagLine,
        'teamId': teamId,
        'agentName': agentName,
        'agentIcon': agentIcon,
        'currentRankTierName': currentRankTierName,
        'rankIcon': rankIcon,
        'currentRr': currentRr,
        'peakRankTierName': peakRankTierName,
        'peakRankIcon': peakRankIcon,
        'accountLevel': accountLevel,
        'isSelf': isSelf,
        'isLocked': isLocked,
        'recentWins': recentWins,
        'recentLosses': recentLosses,
        'recentMatchOutcomes': recentMatchOutcomes,
        'averageCombatScore': averageCombatScore,
        'kdRatio': kdRatio,
        'kastPercentage': kastPercentage,
        'kda': kda,
        'averageDamageRound': averageDamageRound,
        'headshotPercentage': headshotPercentage,
        'winPercentage': winPercentage,
        'lastNActScore': lastNActScore,
        'lastNMatchCount': lastNMatchCount,
        'currentRankEpisodeAct': currentRankEpisodeAct,
        'peakRankEpisodeAct': peakRankEpisodeAct,
        'cardUuid': cardUuid,
        'cardWideArt': cardWideArt,
        'cardSmallArt': cardSmallArt,
        'cardLargeArt': cardLargeArt,
        'cardName': cardName,
      };

  factory LivePlayerInfo.fromJson(Map<String, dynamic> json) => LivePlayerInfo(
        puuid: json['puuid'] as String? ?? '',
        gameName: json['gameName'] as String? ?? 'Player',
        tagLine: json['tagLine'] as String? ?? '',
        teamId: json['teamId'] as String? ?? 'Blue',
        agentName: json['agentName'] as String?,
        agentIcon: json['agentIcon'] as String?,
        currentRankTierName:
            json['currentRankTierName'] as String? ?? 'Unranked',
        rankIcon: json['rankIcon'] as String?,
        currentRr: json['currentRr'] as int? ?? 0,
        peakRankTierName:
            json['peakRankTierName'] as String? ?? 'Unranked',
        peakRankIcon: json['peakRankIcon'] as String?,
        accountLevel: json['accountLevel'] as int? ?? 1,
        isSelf: json['isSelf'] as bool? ?? false,
        isLocked: json['isLocked'] as bool? ?? true,
        recentWins: json['recentWins'] as int? ?? 0,
        recentLosses: json['recentLosses'] as int? ?? 0,
        recentMatchOutcomes: (json['recentMatchOutcomes'] as List<dynamic>?)
                ?.map((e) => e == true)
                .toList() ??
            const [],
        averageCombatScore: (json['averageCombatScore'] as num?)?.toDouble(),
        kdRatio: (json['kdRatio'] as num?)?.toDouble(),
        kastPercentage: (json['kastPercentage'] as num?)?.toDouble(),
        kda: (json['kda'] as num?)?.toDouble(),
        averageDamageRound: (json['averageDamageRound'] as num?)?.toDouble(),
        headshotPercentage: (json['headshotPercentage'] as num?)?.toDouble(),
        winPercentage: (json['winPercentage'] as num?)?.toDouble(),
        lastNActScore: json['lastNActScore'] as int?,
        lastNMatchCount: json['lastNMatchCount'] as int?,
        currentRankEpisodeAct: json['currentRankEpisodeAct'] as String?,
        peakRankEpisodeAct: json['peakRankEpisodeAct'] as String?,
        cardUuid: json['cardUuid'] as String?,
        cardWideArt: json['cardWideArt'] as String?,
        cardSmallArt: json['cardSmallArt'] as String?,
        cardLargeArt: json['cardLargeArt'] as String?,
        cardName: json['cardName'] as String?,
      );

  @override
  List<Object?> get props => [
        puuid,
        gameName,
        tagLine,
        teamId,
        agentName,
        agentIcon,
        currentRankTierName,
        rankIcon,
        currentRr,
        peakRankTierName,
        peakRankIcon,
        accountLevel,
        isSelf,
        isLocked,
        recentWins,
        recentLosses,
        recentMatchOutcomes,
        averageCombatScore,
        kdRatio,
        kastPercentage,
        kda,
        averageDamageRound,
        headshotPercentage,
        winPercentage,
        lastNActScore,
        lastNMatchCount,
        currentRankEpisodeAct,
        peakRankEpisodeAct,
        cardUuid,
        cardWideArt,
        cardSmallArt,
        cardLargeArt,
        cardName,
      ];
}
