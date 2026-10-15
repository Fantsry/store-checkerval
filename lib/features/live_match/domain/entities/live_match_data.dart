import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_player_info.dart';

enum LiveMatchPhase {
  preGame, // Agent Select
  coreGame, // Live in Match
  transitioning, // Agent Select completed, loading map/spawning into match
  inLobby, // In Menu / Not currently in a match
}

class LiveMatchData extends Equatable {
  final LiveMatchPhase phase;
  final String matchId;
  final String mapName;
  final String? mapSplash;
  final String modeName;
  final List<LivePlayerInfo> blueTeam;
  final List<LivePlayerInfo> redTeam;

  // ─── Live Match HUD fields ────────────────────────────────────
  final String? playerSide; // "Attack" / "Defense" (nullable)
  final int blueScore; // Ally team score
  final int redScore; // Enemy team score

  const LiveMatchData({
    required this.phase,
    this.matchId = '',
    this.mapName = 'Unknown Map',
    this.mapSplash,
    this.modeName = 'Competitive',
    this.blueTeam = const [],
    this.redTeam = const [],
    this.playerSide,
    this.blueScore = 0,
    this.redScore = 0,
  });

  bool get isInMatch => phase != LiveMatchPhase.inLobby;

  Map<String, dynamic> toJson() => {
        'phase': phase.name,
        'matchId': matchId,
        'mapName': mapName,
        'mapSplash': mapSplash,
        'modeName': modeName,
        'blueTeam': blueTeam.map((p) => p.toJson()).toList(),
        'redTeam': redTeam.map((p) => p.toJson()).toList(),
        'playerSide': playerSide,
        'blueScore': blueScore,
        'redScore': redScore,
      };

  factory LiveMatchData.fromJson(Map<String, dynamic> json) {
    final blueRaw =
        json['blueTeam'] is List ? (json['blueTeam'] as List) : const [];
    final redRaw =
        json['redTeam'] is List ? (json['redTeam'] as List) : const [];

    return LiveMatchData(
      phase: LiveMatchPhase.values.firstWhere(
        (p) => p.name == (json['phase'] as String? ?? 'inLobby'),
        orElse: () => LiveMatchPhase.inLobby,
      ),
      matchId: json['matchId'] as String? ?? '',
      mapName: json['mapName'] as String? ?? 'Unknown Map',
      mapSplash: json['mapSplash'] as String?,
      modeName: json['modeName'] as String? ?? 'Competitive',
      blueTeam: blueRaw
          .whereType<Map>()
          .map((p) => LivePlayerInfo.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      redTeam: redRaw
          .whereType<Map>()
          .map((p) => LivePlayerInfo.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      playerSide: json['playerSide'] as String?,
      blueScore: json['blueScore'] as int? ?? 0,
      redScore: json['redScore'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        matchId,
        mapName,
        mapSplash,
        modeName,
        blueTeam,
        redTeam,
        playerSide,
        blueScore,
        redScore,
      ];

  /// High-fidelity demo match matching the user's photo with landscape card banners and sporty stats
  static LiveMatchData createSampleTrackerMatch() {
    return const LiveMatchData(
      phase: LiveMatchPhase.coreGame,
      matchId: 'sample-abyss-match',
      mapName: 'Abyss',
      modeName: 'Competitive',
      playerSide: 'Attack',
      blueScore: 0,
      redScore: 0,
      blueTeam: [
        LivePlayerInfo(
          puuid: 'p-desolate',
          gameName: 'Desolate',
          tagLine: '2009',
          teamId: 'Blue',
          agentName: 'Gekko',
          agentIcon:
              'https://media.valorant-api.com/agents/e370fa57-4757-3604-3648-499e1f642d3f/displayicon.png',
          cardWideArt:
              'https://media.valorant-api.com/playercards/3329ec45-42c2-8eb4-013b-808605559c78/wideart.png',
          currentRankTierName: 'Ascendant 1',
          rankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/21/largeicon.png',
          peakRankTierName: 'Ascendant 2',
          peakRankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/22/largeicon.png',
          peakRankEpisodeAct: 'E26A4',
          isSelf: true,
          accountLevel: 140,
          recentMatchOutcomes: [false, true, false, true, false],
          lastNMatchCount: 15,
          lastNActScore: 72,
          winPercentage: 33,
          kdRatio: 0.86,
          kastPercentage: 68,
          kda: 1.14,
          averageCombatScore: 198,
          headshotPercentage: 34,
          averageDamageRound: 137,
        ),
        LivePlayerInfo(
          puuid: 'p-sova',
          gameName: 'Sova',
          tagLine: '',
          teamId: 'Blue',
          agentName: 'Sova',
          agentIcon:
              'https://media.valorant-api.com/agents/3207dd69-497b-d476-60e7-cf8681a75d1a/displayicon.png',
          currentRankTierName: 'Ascendant 1',
          rankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/21/largeicon.png',
          peakRankTierName: 'Ascendant 2',
          peakRankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/22/largeicon.png',
          recentMatchOutcomes: [false, true, false, true, true],
          lastNMatchCount: 15,
          winPercentage: 69,
          kdRatio: 1.58,
          kastPercentage: 76,
          kda: 1.79,
          averageCombatScore: 290,
          headshotPercentage: 49,
          averageDamageRound: 195,
        ),
        LivePlayerInfo(
          puuid: 'p-faceit',
          gameName: 'Faceit Warrior',
          tagLine: '2812',
          teamId: 'Blue',
          agentName: 'Yoru',
          agentIcon:
              'https://media.valorant-api.com/agents/7f94d92c-4234-0a36-9646-3a87eb8b5c89/displayicon.png',
          cardWideArt:
              'https://media.valorant-api.com/playercards/da9ab2a8-4444-23db-9889-be96fa5eb354/wideart.png',
          currentRankTierName: 'Ascendant 1',
          rankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/21/largeicon.png',
          peakRankTierName: 'Ascendant 2',
          peakRankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/22/largeicon.png',
          peakRankEpisodeAct: 'E26A5',
          recentMatchOutcomes: [false, false, false, true, false],
          lastNMatchCount: 15,
          lastNActScore: 120,
          winPercentage: 40,
          kdRatio: 1.05,
          kastPercentage: 68,
          kda: 1.26,
          averageCombatScore: 218,
          headshotPercentage: 38,
          averageDamageRound: 145,
        ),
        LivePlayerInfo(
          puuid: 'p-robicheaux',
          gameName: 'Robicheaux',
          tagLine: 'GNITE',
          teamId: 'Blue',
          agentName: 'Jett',
          agentIcon:
              'https://media.valorant-api.com/agents/add6443a-41bd-e414-f6ad-e58d267f4e95/displayicon.png',
          cardWideArt:
              'https://media.valorant-api.com/playercards/716a5a04-45e0-b6f7-b895-ab9f9024a1b0/wideart.png',
          currentRankTierName: 'Ascendant 1',
          rankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/21/largeicon.png',
          peakRankTierName: 'Immortal 1',
          peakRankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/24/largeicon.png',
          peakRankEpisodeAct: 'E6A2',
          recentMatchOutcomes: [true, false, true, true, false],
          lastNMatchCount: 15,
          lastNActScore: 30,
          winPercentage: 33,
          kdRatio: 0.97,
          kastPercentage: 66,
          kda: 1.26,
          averageCombatScore: 211,
          headshotPercentage: 35,
          averageDamageRound: 140,
        ),
        LivePlayerInfo(
          puuid: 'p-clove-ally',
          gameName: 'Clove',
          tagLine: '',
          teamId: 'Blue',
          agentName: 'Clove',
          agentIcon:
              'https://media.valorant-api.com/agents/117ed9e3-49f3-6512-3ccf-0cada7e3823b/displayicon.png',
          currentRankTierName: 'Ascendant 1',
          rankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/21/largeicon.png',
          peakRankTierName: 'Ascendant 2',
          peakRankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/22/largeicon.png',
          recentMatchOutcomes: [true, false, false, false, true],
          lastNMatchCount: 11,
          winPercentage: 60,
          kdRatio: 1.00,
          kastPercentage: 69,
          kda: 1.35,
          averageCombatScore: 206,
          headshotPercentage: 25,
          averageDamageRound: 133,
        ),
      ],
      redTeam: [
        LivePlayerInfo(
          puuid: 'p-vyse',
          gameName: 'Vyse',
          tagLine: '',
          teamId: 'Red',
          agentName: 'Vyse',
          agentIcon:
              'https://media.valorant-api.com/agents/e370fa57-4757-3604-3648-499e1f642d3f/displayicon.png',
          currentRankTierName: 'Ascendant 1',
          rankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/21/largeicon.png',
          peakRankTierName: 'Ascendant 2',
          peakRankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/22/largeicon.png',
          peakRankEpisodeAct: 'E26A5',
          recentMatchOutcomes: [false, true, true, false, false],
          lastNMatchCount: 15,
          averageDamageRound: 150,
          headshotPercentage: 30,
          averageCombatScore: 204,
          kda: 1.35,
          kastPercentage: 68,
          kdRatio: 0.93,
          winPercentage: 40,
        ),
        LivePlayerInfo(
          puuid: 'p-clove-enemy',
          gameName: 'Clove',
          tagLine: '',
          teamId: 'Red',
          agentName: 'Clove',
          agentIcon:
              'https://media.valorant-api.com/agents/117ed9e3-49f3-6512-3ccf-0cada7e3823b/displayicon.png',
          currentRankTierName: 'Immortal 2',
          rankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/25/largeicon.png',
          peakRankTierName: 'Immortal 1',
          peakRankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/24/largeicon.png',
          peakRankEpisodeAct: 'E5A3',
          recentMatchOutcomes: [false, true, true, true, true],
          lastNMatchCount: 15,
          averageDamageRound: 160,
          headshotPercentage: 40,
          averageCombatScore: 229,
          kda: 1.92,
          kastPercentage: 83,
          kdRatio: 1.42,
          winPercentage: 80,
        ),
        LivePlayerInfo(
          puuid: 'p-yoru-enemy',
          gameName: 'Yoru',
          tagLine: '',
          teamId: 'Red',
          agentName: 'Yoru',
          agentIcon:
              'https://media.valorant-api.com/agents/7f94d92c-4234-0a36-9646-3a87eb8b5c89/displayicon.png',
          currentRankTierName: 'Ascendant 1',
          rankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/21/largeicon.png',
          peakRankTierName: 'Ascendant 2',
          peakRankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/22/largeicon.png',
          recentMatchOutcomes: [false, true, false, true, false],
          lastNMatchCount: 15,
          averageDamageRound: 127,
          headshotPercentage: 21,
          averageCombatScore: 181,
          kda: 1.08,
          kastPercentage: 65,
          kdRatio: 0.76,
          winPercentage: 40,
        ),
        LivePlayerInfo(
          puuid: 'p-sova-enemy',
          gameName: 'Sova',
          tagLine: '',
          teamId: 'Red',
          agentName: 'Sova',
          agentIcon:
              'https://media.valorant-api.com/agents/3207dd69-497b-d476-60e7-cf8681a75d1a/displayicon.png',
          currentRankTierName: 'Ascendant 1',
          rankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/21/largeicon.png',
          peakRankTierName: 'Ascendant 2',
          peakRankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/22/largeicon.png',
          peakRankEpisodeAct: 'E25A5',
          recentMatchOutcomes: [false, true, false, true, false],
          lastNMatchCount: 15,
          averageDamageRound: 163,
          headshotPercentage: 24,
          averageCombatScore: 252,
          kda: 1.43,
          kastPercentage: 73,
          kdRatio: 1.09,
          winPercentage: 40,
        ),
        LivePlayerInfo(
          puuid: 'p-cat',
          gameName: 'Cat',
          tagLine: 'LuvYu',
          teamId: 'Red',
          agentName: 'Jett',
          agentIcon:
              'https://media.valorant-api.com/agents/add6443a-41bd-e414-f6ad-e58d267f4e95/displayicon.png',
          cardWideArt:
              'https://media.valorant-api.com/playercards/1f1fc842-4217-105c-5cf1-02a83969be84/wideart.png',
          currentRankTierName: 'Ascendant 1',
          rankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/21/largeicon.png',
          peakRankTierName: 'Immortal 1',
          peakRankIcon:
              'https://media.valorant-api.com/competitivetiers/03621f52-342b-cf4e-4f86-9350a49c6d04/24/largeicon.png',
          peakRankEpisodeAct: 'E25A5',
          recentMatchOutcomes: [false, true, false, true, false],
          lastNMatchCount: 15,
          averageDamageRound: 137,
          headshotPercentage: 25,
          averageCombatScore: 206,
          kda: 1.14,
          kastPercentage: 66,
          kdRatio: 0.84,
          winPercentage: 40,
        ),
      ],
    );
  }
}
