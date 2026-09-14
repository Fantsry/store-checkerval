import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/widgets/tier_breakdown_card.dart';

void main() {
  const tTierBreakdown = {
    'Exclusive': 5,
    'Ultra': 2,
    'Premium': 8,
    'Deluxe': 3,
    'Select': 1,
  };

  testWidgets('TierBreakdownCard displays all tier counts and names', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TierBreakdownCard(
            tierBreakdown: tTierBreakdown,
          ),
        ),
      ),
    );

    expect(find.text('SKIN TIERS DISTRIBUTION'), findsOneWidget);
    expect(find.text('Exclusive'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Ultra'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Deluxe'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Select'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('TierBreakdownCard invokes onTierSelected when a tier item is tapped', (tester) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TierBreakdownCard(
            tierBreakdown: tTierBreakdown,
            onTierSelected: (tier) {
              selected = tier;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Exclusive'));
    await tester.pump();

    expect(selected, equals('Exclusive'));
  });

  testWidgets('TierBreakdownCard shows RESET FILTER and toggles to null on tap', (tester) async {
    String? selected = 'Premium';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TierBreakdownCard(
            tierBreakdown: tTierBreakdown,
            selectedTier: 'Premium',
            onTierSelected: (tier) {
              selected = tier;
            },
          ),
        ),
      ),
    );

    expect(find.text('RESET FILTER'), findsOneWidget);

    // Tap RESET FILTER
    await tester.tap(find.text('RESET FILTER'));
    await tester.pump();

    expect(selected, isNull);

    // Tap active Premium tier again to toggle off
    await tester.tap(find.text('Premium'));
    await tester.pump();

    expect(selected, isNull);
  });
}
