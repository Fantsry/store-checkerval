import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/kills_by_round_widget.dart';

void main() {
  const selfPuuid = 'puuid-self';
  const enemyPuuid = 'puuid-enemy';

  final dummyMatch = MatchSummary(
    matchId: 'match-123',
    mapId: 'haven',
    mapName: 'Haven',
    gameMode: 'bomb',
    queueId: 'competitive',
    agentId: 'agent-jett',
    agentName: 'Jett',
    won: true,
    scoreWon: 13,
    scoreLost: 11,
    gameStartTime: DateTime(2026, 9, 13, 10, 0),
    teammates: const [
      MatchPlayerSummary(
        puuid: selfPuuid,
        gameName: 'Desolate',
        tagLine: '2009',
        agentId: 'agent-jett',
        agentName: 'Jett',
        teamId: 'Blue',
        isSelf: true,
      ),
    ],
    enemies: const [
      MatchPlayerSummary(
        puuid: enemyPuuid,
        gameName: 'Opponent',
        tagLine: '1234',
        agentId: 'agent-chamber',
        agentName: 'Chamber',
        teamId: 'Red',
        isSelf: false,
      ),
    ],
    rounds: const [
      MatchRoundSummary(
        roundNum: 0,
        won: true,
        roundResult: 'Eliminated',
        kills: [
          MatchRoundKill(
            roundTime: 15000,
            killerPuuid: selfPuuid,
            killerName: 'Desolate',
            killerAgentName: 'Jett',
            killerTeamId: 'Blue',
            victimPuuid: enemyPuuid,
            victimName: 'Opponent',
            victimAgentName: 'Chamber',
            victimTeamId: 'Red',
            isKillerSelf: true,
          ),
        ],
      ),
      MatchRoundSummary(
        roundNum: 1,
        won: false,
        roundResult: 'Defused',
        kills: [
          MatchRoundKill(
            roundTime: 25000,
            killerPuuid: enemyPuuid,
            killerName: 'Opponent',
            killerAgentName: 'Chamber',
            killerTeamId: 'Red',
            victimPuuid: selfPuuid,
            victimName: 'Desolate',
            victimAgentName: 'Jett',
            victimTeamId: 'Blue',
            isVictimSelf: true,
          ),
        ],
      ),
    ],
  );

  Widget createWidget(MatchSummary match) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: KillsByRoundWidget(match: match),
        ),
      ),
    );
  }

  testWidgets('renders Kills by Round header and round columns', (tester) async {
    await tester.pumpWidget(createWidget(dummyMatch));
    await tester.pumpAndSettle();

    expect(find.text('Kills by Round'), findsOneWidget);
    expect(find.text('13 - 11 (2 Rnds)'), findsOneWidget);
    // Round numbers 1 and 2
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    // Focused player defaults to the self player Desolate#2009
    expect(find.text('FOCUSED PLAYER'), findsOneWidget);
    expect(find.text('Desolate#2009'), findsWidgets);
  });

  testWidgets('toggles timeline expand/collapse', (tester) async {
    await tester.pumpWidget(createWidget(dummyMatch));
    await tester.pumpAndSettle();

    expect(find.textContaining('Match timeline & events for Round 1'), findsOneWidget);
    expect(find.text('ROUND 1'), findsOneWidget);
    expect(find.text('VICTORY'), findsOneWidget);

    // Tap to collapse timeline
    await tester.tap(find.textContaining('Match timeline & events for Round 1'));
    await tester.pumpAndSettle();

    expect(find.text('ROUND 1'), findsNothing);

    // Tap to expand again
    await tester.tap(find.textContaining('Match timeline & events for Round 1'));
    await tester.pumpAndSettle();

    expect(find.text('ROUND 1'), findsOneWidget);
  });

  testWidgets('tapping round 2 updates selected round timeline', (tester) async {
    await tester.pumpWidget(createWidget(dummyMatch));
    await tester.pumpAndSettle();

    expect(find.text('VICTORY'), findsOneWidget);

    // Tap on round 2 in the matrix
    await tester.tap(find.text('2').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Match timeline & events for Round 2'), findsOneWidget);
    expect(find.text('ROUND 2'), findsOneWidget);
    expect(find.text('DEFEAT'), findsOneWidget);
  });

  testWidgets('displays graceful empty state when rounds are empty', (tester) async {
    final emptyMatch = MatchSummary(
      matchId: 'match-empty',
      mapId: 'haven',
      mapName: 'Haven',
      gameMode: 'bomb',
      queueId: 'competitive',
      agentId: 'agent-jett',
      agentName: 'Jett',
      gameStartTime: DateTime(2026, 9, 13),
      rounds: const [],
    );
    await tester.pumpWidget(createWidget(emptyMatch));
    await tester.pumpAndSettle();

    expect(
      find.text('No round kill events available for this match'),
      findsOneWidget,
    );
  });
}
