import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';
import 'package:valorant_store_tracker/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/pages/inventory_page.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;
  late InventoryCubit cubit;

  const testSkin1 = OwnedSkinItem(
    uuid: 'skin-1',
    displayName: 'Prime Vandal',
    cost: 1775,
    tierName: 'Premium',
    tierColor: '#D1548D',
    weapon: 'Vandal',
    isEquipped: true,
    isBattlepass: false,
  );

  const testSkin2 = OwnedSkinItem(
    uuid: 'skin-2',
    displayName: 'Kuronami No Yaiba',
    cost: 5350,
    tierName: 'Exclusive',
    tierColor: '#E5B94E',
    weapon: 'Melee',
    isEquipped: false,
    isBattlepass: false,
  );

  const testSkin3 = OwnedSkinItem(
    uuid: 'skin-3',
    displayName: 'Heartbreaker Odin',
    cost: 0,
    tierName: 'Deluxe',
    tierColor: '#00B1A7',
    weapon: 'Odin',
    isEquipped: false,
    isBattlepass: true,
  );

  const testOverview = InventoryOverview(
    totalVpSpent: 7125,
    totalEstimatedIdr: 961875,
    totalSkinsCount: 3,
    tierBreakdown: {
      'Exclusive': 1,
      'Premium': 1,
      'Deluxe': 1,
      'Ultra': 0,
      'Select': 0,
    },
    ownedSkins: [testSkin1, testSkin2, testSkin3],
    equippedWeapons: [],
  );

  setUp(() {
    mockRepository = MockInventoryRepository();
    when(() => mockRepository.getInventoryOverview(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Result.success(testOverview));
    cubit = InventoryCubit(repository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  Widget buildWidget() {
    return MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const InventoryPage(),
      ),
    );
  }

  testWidgets('tapping tier in TierBreakdownCard filters skins grid', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await cubit.loadInventory();
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Initially all 3 skins are displayed
    expect(find.text('Prime Vandal'), findsOneWidget);
    expect(find.text('Kuronami No Yaiba'), findsOneWidget);
    expect(find.text('Heartbreaker Odin'), findsOneWidget);

    // Tap 'Exclusive' in TierBreakdownCard
    final exclusiveFinders = find.text('Exclusive');
    expect(exclusiveFinders, findsWidgets);

    await tester.tap(exclusiveFinders.first);
    await tester.pumpAndSettle();

    // Now only Kuronami No Yaiba should be visible
    expect(find.text('Kuronami No Yaiba'), findsOneWidget);
    expect(find.text('Prime Vandal'), findsNothing);
    expect(find.text('Heartbreaker Odin'), findsNothing);
  });

  testWidgets('tapping BATTLEPASS source filter chip filters skins grid', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await cubit.loadInventory();
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Tap BATTLEPASS
    await tester.tap(find.text('BATTLEPASS'));
    await tester.pumpAndSettle();

    expect(find.text('Heartbreaker Odin'), findsOneWidget);
    expect(find.text('Prime Vandal'), findsNothing);
    expect(find.text('Kuronami No Yaiba'), findsNothing);

    // Verify counter bar shows filtered count
    expect(find.text('SHOWING 1 OF 3 SKINS'), findsOneWidget);

    // Tapping BATTLEPASS again should toggle back to ALL
    await tester.tap(find.text('BATTLEPASS').first);
    await tester.pumpAndSettle();

    expect(find.text('SHOWING 3 OF 3 SKINS'), findsOneWidget);
    expect(find.text('Prime Vandal'), findsOneWidget);
  });

  testWidgets('counter bar displays correct count and RESET clears filters', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await cubit.loadInventory();
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('SHOWING 3 OF 3 SKINS'), findsOneWidget);

    // Tap 'Exclusive' tier
    final exclusiveFinders = find.text('Exclusive');
    await tester.tap(exclusiveFinders.first);
    await tester.pumpAndSettle();

    expect(find.text('SHOWING 1 OF 3 SKINS'), findsOneWidget);
    expect(find.text('RESET'), findsOneWidget);

    // Tap RESET button
    await tester.tap(find.text('RESET'));
    await tester.pumpAndSettle();

    expect(find.text('SHOWING 3 OF 3 SKINS'), findsOneWidget);
    expect(find.text('Prime Vandal'), findsOneWidget);
    expect(find.text('Kuronami No Yaiba'), findsOneWidget);
    expect(find.text('Heartbreaker Odin'), findsOneWidget);
  });
}
