import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';

void main() {
  group('Career Entities & Calculations Test', () {
    final sampleMatch = MatchSummary(
      matchId: 'match-12345-abcde',
      mapId: '/Game/Maps/Ascent/Ascent',
      mapName: 'Ascent',
      mapImageUrl: 'https://media.valorant-api.com/maps/splash.png',
      gameMode: '/Game/GameModes/Bomb/BombGameMode.BombGameMode_C',
      queueId: 'competitive',
      gameStartTime: DateTime(2026, 9, 7, 20, 30),
      gameLengthMillis: 2100000, // 35 min
      won: true,
      scoreWon: 13,
      scoreLost: 9,
      agentId: 'dade69b4-4f5a-8528-247b-219e5a1facd6',
      agentName: 'Fade',
      agentIconUrl: 'https://media.valorant-api.com/agents/fade.png',
      kills: 22,
      deaths: 11,
      assists: 8,
      score: 5500,
      roundsPlayed: 22,
      averageCombatScore: 250,
      headshots: 14,
      bodyshots: 26,
      legshots: 2,
      damage: 3200,
      rankRatingEarned: 24,
      competitiveTier: 15,
      rankName: 'Platinum 1',
      rankIconUrl: 'https://media.valorant-api.com/competitivetiers/plat1.png',
    );

    test('MatchSummary calculates KD ratio and accuracy correctly', () {
      expect(sampleMatch.kdRatio, 2.0); // 22 / 11
      // total hits: 14 + 26 + 2 = 42. hs% = (14 / 42 * 100).round() = 33
      expect(sampleMatch.headshotPercentage, 33);
      expect(sampleMatch.queueDisplayName, 'Competitive');
      expect(sampleMatch.resultText, 'VICTORY');
      expect(sampleMatch.scoreDisplay, '13 - 9');
    });

    test('MatchSummary handles 0 deaths gracefully in KD ratio', () {
      final flawlessMatch = MatchSummary(
        matchId: 'match-flawless',
        mapId: '/Game/Maps/Bind/Bind',
        mapName: 'Bind',
        gameMode: 'spikerush',
        queueId: 'spikerush',
        gameStartTime: DateTime(2026, 9, 7),
        won: true,
        kills: 10,
        deaths: 0,
        agentId: 'jett-uuid',
        agentName: 'Jett',
      );

      expect(flawlessMatch.kdRatio, 10.0);
    });

    test('MatchSummary handles draw outcome correctly', () {
      final drawMatch = MatchSummary(
        matchId: 'match-draw',
        mapId: 'split',
        mapName: 'Split',
        gameMode: 'competitive',
        queueId: 'competitive',
        gameStartTime: DateTime(2026, 9, 7),
        isDraw: true,
        scoreWon: 14,
        scoreLost: 14,
        agentId: 'omen-uuid',
        agentName: 'Omen',
      );

      expect(drawMatch.resultText, 'DRAW');
      expect(drawMatch.scoreDisplay, '14 - 14');
    });

    test('MatchSummary serialization toJson and fromJson preserves data including teammates and enemies', () {
      final teammate = MatchPlayerSummary(
        puuid: 'puuid-ally-1',
        gameName: 'AllyOne',
        tagLine: '123',
        teamId: 'Blue',
        agentId: 'agent-sova',
        agentName: 'Sova',
        agentIconUrl: 'https://media.valorant-api.com/agents/sova.png',
        competitiveTier: 16,
        rankName: 'Platinum 2',
        rankIconUrl: 'https://media.valorant-api.com/tiers/16.png',
        kills: 18,
        deaths: 12,
        assists: 9,
        score: 4200,
        roundsPlayed: 22,
        averageCombatScore: 191,
      );

      final enemy = MatchPlayerSummary(
        puuid: 'puuid-enemy-1',
        gameName: 'EnemyOne',
        tagLine: '999',
        teamId: 'Red',
        agentId: 'agent-reyna',
        agentName: 'Reyna',
        competitiveTier: 17,
        rankName: 'Platinum 3',
        kills: 25,
        deaths: 15,
        assists: 3,
        score: 6100,
        roundsPlayed: 22,
        averageCombatScore: 277,
      );

      final matchWithTeams = MatchSummary(
        matchId: sampleMatch.matchId,
        mapId: sampleMatch.mapId,
        mapName: sampleMatch.mapName,
        gameMode: sampleMatch.gameMode,
        queueId: sampleMatch.queueId,
        gameStartTime: sampleMatch.gameStartTime,
        won: true,
        agentId: sampleMatch.agentId,
        agentName: sampleMatch.agentName,
        teammates: [teammate],
        enemies: [enemy],
      );

      expect(teammate.kdRatio, 1.5);
      expect(teammate.kdaDisplay, '18 / 12 / 9');
      expect(teammate.displayName, 'AllyOne#123');

      final json = matchWithTeams.toJson();
      final reconstructed = MatchSummary.fromJson(json);

      expect(reconstructed.matchId, sampleMatch.matchId);
      expect(reconstructed.mapName, 'Ascent');
      expect(reconstructed.won, true);
      expect(reconstructed.teammates.length, 1);
      expect(reconstructed.enemies.length, 1);
      expect(reconstructed.teammates.first.displayName, 'AllyOne#123');
      expect(reconstructed.teammates.first.rankName, 'Platinum 2');
      expect(reconstructed.enemies.first.displayName, 'EnemyOne#999');
      expect(reconstructed.enemies.first.rankName, 'Platinum 3');
    });

    test('CareerOverview calculates stats and serializes to/from json', () {
      final overview = CareerOverview(
        currentTier: 15,
        currentTierName: 'Platinum 1',
        currentRankRating: 68,
        peakTier: 17,
        peakTierName: 'Platinum 3',
        totalMatches: 1,
        totalWins: 1,
        totalLosses: 0,
        winRate: 100.0,
        avgCombatScore: 250,
        avgKdRatio: 2.0,
        avgHeadshotPct: 33.3,
        matches: [sampleMatch],
      );

      final json = overview.toJson();
      final restored = CareerOverview.fromJson(json);

      expect(restored.currentTier, 15);
      expect(restored.currentTierName, 'Platinum 1');
      expect(restored.currentRankRating, 68);
      expect(restored.peakTierName, 'Platinum 3');
      expect(restored.totalMatches, 1);
      expect(restored.winRate, 100.0);
      expect(restored.matches.length, 1);
      expect(restored.matches.first.mapName, 'Ascent');
    });

    test('MatchRoundKill and MatchRoundSummary serialize to and from json correctly', () {
      const kill = MatchRoundKill(
        roundTime: 45000,
        killerPuuid: 'killer-uuid',
        killerName: 'KillerPlayer#ID1',
        killerAgentName: 'Reyna',
        killerAgentIconUrl: 'https://media.valorant-api.com/reyna.png',
        killerTeamId: 'Blue',
        victimPuuid: 'victim-uuid',
        victimName: 'VictimPlayer#ID2',
        victimAgentName: 'Jett',
        victimAgentIconUrl: 'https://media.valorant-api.com/jett.png',
        victimTeamId: 'Red',
        assistantPuuids: ['assist-uuid'],
        assistantNames: ['AssistPlayer#ID3'],
        weaponId: 'vandal-uuid',
        isKillerSelf: true,
        isVictimSelf: false,
      );

      final killJson = kill.toJson();
      final restoredKill = MatchRoundKill.fromJson(killJson);

      expect(restoredKill.killerName, 'KillerPlayer#ID1');
      expect(restoredKill.killerAgentName, 'Reyna');
      expect(restoredKill.victimName, 'VictimPlayer#ID2');
      expect(restoredKill.victimAgentName, 'Jett');
      expect(restoredKill.isKillerSelf, true);
      expect(restoredKill.assistantNames, ['AssistPlayer#ID3']);

      final round = MatchRoundSummary(
        roundNum: 0,
        winningTeam: 'Blue',
        won: true,
        roundResult: 'Eliminated',
        kills: [restoredKill],
      );

      final roundJson = round.toJson();
      final restoredRound = MatchRoundSummary.fromJson(roundJson);

      expect(restoredRound.roundNum, 0);
      expect(restoredRound.winningTeam, 'Blue');
      expect(restoredRound.won, true);
      expect(restoredRound.kills.length, 1);
      expect(restoredRound.kills.first.killerName, 'KillerPlayer#ID1');
    });

    test('MatchSummary handles Deathmatch, allPlayers, and MVP calculations', () {
      const p1 = MatchPlayerSummary(
        puuid: 'p1',
        gameName: 'TopFragger',
        tagLine: '001',
        teamId: 'Blue',
        agentId: 'jett',
        agentName: 'Jett',
        score: 6000,
      );
      const p2 = MatchPlayerSummary(
        puuid: 'p2',
        gameName: 'SecondFragger',
        tagLine: '002',
        teamId: 'Red',
        agentId: 'reyna',
        agentName: 'Reyna',
        score: 4500,
      );

      final dmMatch = MatchSummary(
        matchId: 'dm-1',
        mapId: 'split',
        mapName: 'Split',
        gameMode: 'deathmatch',
        queueId: 'deathmatch',
        gameStartTime: DateTime(2026, 9, 7),
        agentId: 'jett',
        agentName: 'Jett',
        teammates: const [p1],
        enemies: const [p2],
      );

      expect(dmMatch.isDeathmatch, true);
      expect(dmMatch.allPlayers.length, 2);
      expect(dmMatch.allPlayers.first.puuid, 'p1');
      expect(dmMatch.matchMvpPuuid, 'p1');
      expect(dmMatch.teamMvpPuuid, 'p1');
    });
  });
}
