import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/widgets/accessory_store_section.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/widgets/bundle_card.dart';

void main() {
  testWidgets('bundle with unknown price does not render as FREE', (
    tester,
  ) async {
    const bundle = FeaturedBundle(
      uuid: 'bundle-1',
      displayName: 'Mystery Bundle',
      price: 0,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: BundleCard(bundle: bundle)),
        ),
      ),
    );

    expect(find.text('FREE'), findsNothing);
    expect(find.text('-- VP'), findsOneWidget);
  });

  testWidgets('accessory with unknown KC cost renders a dash', (tester) async {
    const item = AccessoryStoreItem(
      uuid: 'buddy-1',
      displayName: 'Mystery Buddy',
      itemType: 'Buddy',
      kcCost: 0,
      remainingDurationSeconds: 3600,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AccessoryStoreSection(items: [item])),
      ),
    );

    expect(find.text('0 KC'), findsNothing);
    expect(find.text('-- KC'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
