import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/match_share_card.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/rank_share_card.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/widgets/inventory_share_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 330, child: child),
        ),
      ),
    );
  }

  testWidgets('RankShareCard renders rank, RR, and player stats', (tester) async {
    final overview = CareerOverview(
      currentTier: 15,
      currentTierName: 'Platinum 1',
      currentRankRating: 68,
      peakTierName: 'Diamond 1',
      totalMatches: 42,
      winRate: 57.5,
      avgCombatScore: 230,
      avgKdRatio: 1.42,
      avgHeadshotPct: 26,
    );

    await tester.pumpWidget(
      wrap(RankShareCard(overview: overview, playerName: 'Player#TAG')),
    );
    await tester.pumpAndSettle();

    expect(find.text('PLAYER#TAG'), findsOneWidget);
    expect(find.text('PLATINUM 1'), findsOneWidget);
    expect(find.text('68 RR'), findsOneWidget);
    expect(find.text('58%'), findsOneWidget);
    expect(find.text('PEAK DIAMOND 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('InventoryShareCard renders collection value and counts',
      (tester) async {
    const overview = InventoryOverview(
      totalVpSpent: 125000,
      totalEstimatedIdr: 12500000,
      totalSkinsCount: 87,
      tierBreakdown: {
        'Premium': 24,
        'Deluxe': 18,
        'Exclusive': 7,
      },
      ownedSkins: [
        OwnedSkinItem(uuid: 'a', displayName: 'Skin A', isBattlepass: true),
        OwnedSkinItem(uuid: 'b', displayName: 'Skin B'),
      ],
    );

    await tester.pumpWidget(
      wrap(const InventoryShareCard(overview: overview)),
    );
    await tester.pumpAndSettle();

    expect(find.text('MY COLLECTION'), findsOneWidget);
    expect(find.text('Rp 12.500.000'), findsOneWidget);
    expect(find.text('125000 VP SPENT'), findsOneWidget);
    expect(find.text('TOP TIERS'), findsOneWidget);
    expect(find.text('PREMIUM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MatchShareCard renders result, map, and match stats',
      (tester) async {
    final match = MatchSummary(
      matchId: 'share-match',
      mapId: 'ascent',
      mapName: 'Ascent',
      gameMode: 'bomb',
      queueId: 'competitive',
      gameStartTime: DateTime(2026, 9, 7),
      won: true,
      scoreWon: 13,
      scoreLost: 9,
      agentId: 'jett',
      agentName: 'Jett',
      kills: 22,
      deaths: 11,
      assists: 8,
      averageCombatScore: 250,
      headshots: 14,
      bodyshots: 26,
      legshots: 2,
      rankName: 'Platinum 1',
    );

    await tester.pumpWidget(wrap(MatchShareCard(match: match)));
    await tester.pumpAndSettle();

    expect(find.text('ASCENT'), findsOneWidget);
    expect(find.text('VICTORY'), findsOneWidget);
    expect(find.text('13 - 9'), findsOneWidget);
    expect(find.text('JETT'), findsOneWidget);
    expect(find.text('22 / 11 / 8'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
