import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';
import 'package:valorant_store_tracker/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/cubit/inventory_state.dart';

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
    },
    ownedSkins: [testSkin1, testSkin2, testSkin3],
    equippedWeapons: [
      EquippedWeaponSkin(
        weaponId: 'w-1',
        weaponName: 'Vandal',
        skinId: 'skin-1',
        skinName: 'Prime Vandal',
        isBattlepass: false,
      ),
    ],
  );

  setUp(() {
    mockRepository = MockInventoryRepository();
    cubit = InventoryCubit(repository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('InventoryOverview Entity Tests', () {
    test('formattedEstimatedIdr formats Rupiah correctly with dots', () {
      expect(testOverview.formattedEstimatedIdr, equals('Rp 961.875'));

      const largeOverview = InventoryOverview(
        totalEstimatedIdr: 24500000,
      );
      expect(largeOverview.formattedEstimatedIdr, equals('Rp 24.500.000'));
    });

    test('toJson and fromJson preserves all fields including isBattlepass', () {
      final json = testOverview.toJson();
      final restored = InventoryOverview.fromJson(json);

      expect(restored.totalVpSpent, equals(testOverview.totalVpSpent));
      expect(restored.totalEstimatedIdr, equals(testOverview.totalEstimatedIdr));
      expect(restored.totalSkinsCount, equals(testOverview.totalSkinsCount));
      expect(restored.ownedSkins.length, equals(3));
      expect(restored.ownedSkins.first.displayName, equals('Prime Vandal'));
      expect(restored.ownedSkins[2].displayName, equals('Heartbreaker Odin'));
      expect(restored.ownedSkins[2].isBattlepass, isTrue);
      expect(restored.equippedWeapons.first.weaponName, equals('Vandal'));
      expect(restored.equippedWeapons.first.isBattlepass, isFalse);
    });

    test('battlepassSkinsCount and storeSkinsCount calculate accurately', () {
      expect(testOverview.battlepassSkinsCount, equals(1));
      expect(testOverview.storeSkinsCount, equals(2));
    });
  });

  group('InventoryCubit Tests', () {
    test('initial state is InventoryInitial', () {
      expect(cubit.state, equals(const InventoryInitial()));
    });

    test('emits [InventoryLoading, InventoryLoaded] when loadInventory succeeds',
        () async {
      when(() => mockRepository.getInventoryOverview(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => const Result.success(testOverview));

      final expectedStates = [
        const InventoryLoading(),
        isA<InventoryLoaded>()
            .having((s) => s.overview.totalVpSpent, 'totalVpSpent', 7125)
            .having((s) => s.filteredSkins.length, 'skinsCount', 3)
            .having((s) => s.sourceFilter, 'sourceFilter', InventorySourceFilter.all),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadInventory();
    });

    test('filterBySource filters skins by battlepass and store', () async {
      when(() => mockRepository.getInventoryOverview(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => const Result.success(testOverview));

      await cubit.loadInventory();

      // Filter by battlepass
      cubit.filterBySource(InventorySourceFilter.battlepass);
      expect((cubit.state as InventoryLoaded).filteredSkins.length, equals(1));
      expect(
        (cubit.state as InventoryLoaded).filteredSkins.first.displayName,
        equals('Heartbreaker Odin'),
      );
      expect(
        (cubit.state as InventoryLoaded).filteredSkins.first.isBattlepass,
        isTrue,
      );

      // Filter by store
      cubit.filterBySource(InventorySourceFilter.store);
      expect((cubit.state as InventoryLoaded).filteredSkins.length, equals(2));
      expect(
        (cubit.state as InventoryLoaded).filteredSkins.every((s) => !s.isBattlepass),
        isTrue,
      );

      // Reset to all
      cubit.filterBySource(InventorySourceFilter.all);
      expect((cubit.state as InventoryLoaded).filteredSkins.length, equals(3));
    });

    test('filterByTier filters owned skins by tier name', () async {
      when(() => mockRepository.getInventoryOverview(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => const Result.success(testOverview));

      await cubit.loadInventory();

      cubit.filterByTier('Exclusive');

      expect((cubit.state as InventoryLoaded).filteredSkins.length, equals(1));
      expect(
        (cubit.state as InventoryLoaded).filteredSkins.first.displayName,
        equals('Kuronami No Yaiba'),
      );
    });

    test('combined source and tier filtering works correctly', () async {
      when(() => mockRepository.getInventoryOverview(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => const Result.success(testOverview));

      await cubit.loadInventory();

      cubit.filterBySource(InventorySourceFilter.battlepass);
      cubit.filterByTier('Deluxe');

      expect((cubit.state as InventoryLoaded).filteredSkins.length, equals(1));
      expect(
        (cubit.state as InventoryLoaded).filteredSkins.first.displayName,
        equals('Heartbreaker Odin'),
      );

      cubit.filterByTier('Premium');
      expect((cubit.state as InventoryLoaded).filteredSkins.length, equals(0));
    });

    test('searchSkins filters owned skins by query', () async {
      when(() => mockRepository.getInventoryOverview(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => const Result.success(testOverview));

      await cubit.loadInventory();

      cubit.searchSkins('Vandal');

      expect((cubit.state as InventoryLoaded).filteredSkins.length, equals(1));
      expect(
        (cubit.state as InventoryLoaded).filteredSkins.first.displayName,
        equals('Prime Vandal'),
      );
    });
  });

  group('Inventory API Constants & Endpoints', () {
    test('weaponSkinItemTypeId matches official Riot Games skins UUID', () {
      expect(
        ApiConstants.weaponSkinItemTypeId,
        equals('e7c63390-eda7-46e0-bb7a-a6abdacd2433'),
      );
    });

    test('skinChromaItemTypeId matches official Riot Games chromas UUID', () {
      expect(
        ApiConstants.skinChromaItemTypeId,
        equals('3ad1b2b2-acdb-4524-852f-954a76ddae0a'),
      );
    });

    test('entitlementsUrl constructs valid Riot PVP endpoint', () {
      final url = ApiConstants.entitlementsUrl('ap', 'test-puuid');
      expect(
        url,
        equals(
          'https://pd.ap.a.pvp.net/store/v1/entitlements/test-puuid/e7c63390-eda7-46e0-bb7a-a6abdacd2433',
        ),
      );
    });
  });
}
