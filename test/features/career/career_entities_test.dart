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

    test('MatchSummary serialization toJson and fromJson preserves data', () {
      final json = sampleMatch.toJson();
      final reconstructed = MatchSummary.fromJson(json);

      expect(reconstructed.matchId, sampleMatch.matchId);
      expect(reconstructed.mapName, 'Ascent');
      expect(reconstructed.won, true);
      expect(reconstructed.kills, 22);
      expect(reconstructed.rankRatingEarned, 24);
      expect(reconstructed.rankName, 'Platinum 1');
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
  });
}
