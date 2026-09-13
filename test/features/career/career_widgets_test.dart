import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/map_kill_overlay_widget.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/performance_stats_card.dart';

void main() {
  group('PerformanceStatsCard Widget Tests', () {
    final matches = [
      MatchSummary(
        matchId: 'm1',
        mapId: 'ascent',
        mapName: 'Ascent',
        gameMode: 'bomb',
        queueId: 'competitive',
        gameStartTime: DateTime(2026, 9, 7),
        won: true,
        agentId: 'jett',
        agentName: 'Jett',
        kills: 20,
        deaths: 10,
        scoreWon: 13,
        scoreLost: 7,
      ),
      MatchSummary(
        matchId: 'm2',
        mapId: 'ascent',
        mapName: 'Ascent',
        gameMode: 'bomb',
        queueId: 'competitive',
        gameStartTime: DateTime(2026, 9, 6),
        won: true,
        agentId: 'jett',
        agentName: 'Jett',
        kills: 18,
        deaths: 12,
        scoreWon: 13,
        scoreLost: 11,
      ),
      MatchSummary(
        matchId: 'm3',
        mapId: 'bind',
        mapName: 'Bind',
        gameMode: 'bomb',
        queueId: 'competitive',
        gameStartTime: DateTime(2026, 9, 5),
        won: false,
        agentId: 'omen',
        agentName: 'Omen',
        kills: 14,
        deaths: 15,
        scoreWon: 8,
        scoreLost: 13,
      ),
    ];

    final overview = CareerOverview(
      currentTier: 15,
      currentTierName: 'Platinum 1',
      currentRankRating: 65,
      totalMatches: 3,
      totalWins: 2,
      totalLosses: 1,
      winRate: 66.7,
      avgKdRatio: 1.41,
      avgCombatScore: 230,
      avgHeadshotPct: 24.0,
      matches: matches,
    );

    testWidgets('renders PerformanceStatsCard with insights, streak, and top agents/maps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PerformanceStatsCard(overview: overview),
            ),
          ),
        ),
      );

      expect(find.text('PERFORMANCE INSIGHTS'), findsOneWidget);
      expect(find.text('RECENT FORM'), findsOneWidget);
      expect(find.text('2 Win Streak'), findsOneWidget);
      expect(find.text('TOP AGENTS'), findsOneWidget);
      expect(find.text('Jett'), findsOneWidget);
      expect(find.text('TOP MAPS'), findsOneWidget);
      expect(find.text('Ascent'), findsOneWidget);
    });
  });

  group('MapKillOverlayWidget Tests', () {
    final matchWithMinimap = MatchSummary(
      matchId: 'm-minimap',
      mapId: 'ascent',
      mapName: 'Ascent',
      mapMinimapUrl: 'https://media.valorant-api.com/maps/ascent-displayicon.png',
      mapXMultiplier: 0.00007,
      mapYMultiplier: -0.00007,
      mapXScalarToAdd: 0.81,
      mapYScalarToAdd: 0.57,
      gameMode: 'bomb',
      queueId: 'competitive',
      gameStartTime: DateTime(2026, 9, 7),
      agentId: 'jett',
      agentName: 'Jett',
      rounds: [
        const MatchRoundSummary(
          roundNum: 0,
          won: true,
          winningTeam: 'Blue',
          roundResult: 'Eliminated',
          kills: [
            MatchRoundKill(
              roundTime: 30000,
              killerPuuid: 'killer-self',
              killerName: 'Me#123',
              killerAgentName: 'Jett',
              victimPuuid: 'victim-opp',
              victimName: 'Enemy#456',
              victimAgentName: 'Reyna',
              isKillerSelf: true,
              isVictimSelf: false,
              killerLocationX: 1000.0,
              killerLocationY: 2000.0,
              victimLocationX: 1500.0,
              victimLocationY: 2500.0,
            ),
            MatchRoundKill(
              roundTime: 45000,
              killerPuuid: 'killer-opp',
              killerName: 'Enemy#456',
              killerAgentName: 'Reyna',
              victimPuuid: 'ally-1',
              victimName: 'Ally#789',
              victimAgentName: 'Fade',
              isKillerSelf: false,
              isVictimSelf: false,
              victimLocationX: 1200.0,
              victimLocationY: 2200.0,
            ),
          ],
        ),
      ],
    );

    testWidgets('renders MapKillOverlayWidget header and mode toggle buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MapKillOverlayWidget(
                match: matchWithMinimap,
                selectedRoundIndex: 0,
              ),
            ),
          ),
        ),
      );

      expect(find.text('KILL MAP — ROUND 1'), findsOneWidget);
      expect(find.text('R1'), findsOneWidget);
      expect(find.text('All Rounds'), findsOneWidget);
      expect(find.text('Your Kill (1)'), findsOneWidget);

      // Tap All Rounds toggle
      await tester.tap(find.text('All Rounds'));
      await tester.pumpAndSettle();

      expect(find.text('MAP OVERVIEW — ALL ROUNDS'), findsOneWidget);
    });

    testWidgets('renders empty shrink when no minimap data is present', (tester) async {
      final matchNoMinimap = MatchSummary(
        matchId: 'no-mini',
        mapId: 'custom',
        mapName: 'Custom',
        gameMode: 'bomb',
        queueId: 'custom',
        gameStartTime: DateTime(2026, 9, 7),
        agentId: 'jett',
        agentName: 'Jett',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapKillOverlayWidget(
              match: matchNoMinimap,
              selectedRoundIndex: 0,
            ),
          ),
        ),
      );

      expect(find.text('KILL MAP — ROUND 1'), findsNothing);
    });
  });
}
