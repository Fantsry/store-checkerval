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
  });

  String get displayName =>
      tagLine.isNotEmpty ? '$gameName #$tagLine' : gameName;

  int get recentTotalMatches => recentWins + recentLosses;

  double? get recentWinRate =>
      recentTotalMatches > 0 ? (recentWins / recentTotalMatches) * 100 : null;

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
      ];
}
