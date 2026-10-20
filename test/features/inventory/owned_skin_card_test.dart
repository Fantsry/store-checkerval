import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/widgets/owned_skin_card.dart';

void main() {
  testWidgets('owned skin with unknown price shows a dash instead of FREE',
      (tester) async {
    const skin = OwnedSkinItem(
      uuid: 'skin-1',
      displayName: 'Mystery Skin',
      cost: 0,
      tierName: 'Premium',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 260,
            child: OwnedSkinCard(skin: skin),
          ),
        ),
      ),
    );

    expect(find.text('FREE'), findsNothing);
    expect(find.text('-- VP'), findsOneWidget);
  });

  testWidgets('owned skin with a price shows the VP amount', (tester) async {
    const skin = OwnedSkinItem(
      uuid: 'skin-2',
      displayName: 'Prime Vandal',
      cost: 1775,
      tierName: 'Premium',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 260,
            child: OwnedSkinCard(skin: skin),
          ),
        ),
      ),
    );

    expect(find.text('1775 VP'), findsOneWidget);
  });
}
