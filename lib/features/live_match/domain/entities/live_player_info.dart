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
  final int accountLevel;
  final bool isSelf;
  final bool isLocked;

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
    this.accountLevel = 1,
    this.isSelf = false,
    this.isLocked = true,
  });

  String get displayName =>
      tagLine.isNotEmpty ? '$gameName #$tagLine' : gameName;

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
        'accountLevel': accountLevel,
        'isSelf': isSelf,
        'isLocked': isLocked,
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
        accountLevel: json['accountLevel'] as int? ?? 1,
        isSelf: json['isSelf'] as bool? ?? false,
        isLocked: json['isLocked'] as bool? ?? true,
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
        accountLevel,
        isSelf,
        isLocked,
      ];
}
