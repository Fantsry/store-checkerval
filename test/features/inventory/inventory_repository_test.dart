import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/daily_store/data/datasources/valorant_api_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:valorant_store_tracker/features/inventory/data/repositories/inventory_repository_impl.dart';

class MockInventoryRemoteDataSource extends Mock
    implements InventoryRemoteDataSource {}

class MockValorantApiRemoteDataSource extends Mock
    implements ValorantApiRemoteDataSource {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockLocalStoreService extends Mock implements LocalStoreService {}

void main() {
  late MockInventoryRemoteDataSource mockRemoteDataSource;
  late MockValorantApiRemoteDataSource mockValorantApiDataSource;
  late MockSecureStorageService mockStorage;
  late MockLocalStoreService mockLocalStore;
  late InventoryRepositoryImpl repository;

  const testPuuid = 'puuid-12345';
  const testShard = 'ap';

  final testSkinStore = SkinItem(
    uuid: 'skin-store-uuid',
    displayName: 'Prime Vandal',
    cost: 1775,
    tierName: 'Premium',
    isBattlepass: false,
    levels: const [
      SkinLevel(uuid: 'lvl-store-uuid', displayName: 'Prime Vandal Level 1'),
    ],
  );

  final testSkinBp = SkinItem(
    uuid: 'skin-bp-uuid',
    displayName: 'Heartbreaker Odin',
    cost: 0,
    tierName: 'Deluxe',
    isBattlepass: false, // Intentionally false in catalog to verify bpRewardUuids cross-check!
    levels: const [
      SkinLevel(uuid: 'lvl-bp-uuid', displayName: 'Heartbreaker Odin Level 1'),
    ],
  );

  setUp(() {
    mockRemoteDataSource = MockInventoryRemoteDataSource();
    mockValorantApiDataSource = MockValorantApiRemoteDataSource();
    mockStorage = MockSecureStorageService();
    mockLocalStore = MockLocalStoreService();

    repository = InventoryRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      valorantApiDataSource: mockValorantApiDataSource,
      storage: mockStorage,
      localStore: mockLocalStore,
    );

    when(() => mockStorage.getPuuid()).thenAnswer((_) async => testPuuid);
    when(() => mockStorage.getShard()).thenAnswer((_) async => testShard);
    when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);

    when(() => mockLocalStore.getMap(any())).thenReturn(null);
    when(() => mockLocalStore.setMap(any(), any())).thenAnswer((_) async {});
    when(() => mockLocalStore.deleteMap(any())).thenAnswer((_) async {});
    when(() => mockLocalStore.saveCachedSkins(any())).thenAnswer((_) async {});

    when(() => mockRemoteDataSource.fetchSkinEntitlements(
          shard: any(named: 'shard'),
          puuid: any(named: 'puuid'),
        )).thenAnswer((_) async => ['lvl-store-uuid', 'lvl-bp-uuid']);

    when(() => mockRemoteDataSource.fetchPlayerLoadout(
          shard: any(named: 'shard'),
          puuid: any(named: 'puuid'),
        )).thenAnswer((_) async => null);

    when(() => mockRemoteDataSource.fetchWeaponsMetadata())
        .thenAnswer((_) async => {});

    when(() => mockValorantApiDataSource.getWeaponSkins())
        .thenAnswer((_) async => [testSkinStore, testSkinBp]);

    when(() => mockValorantApiDataSource.getBattlepassRewardUuids())
        .thenAnswer((_) async => {'lvl-bp-uuid', 'skin-bp-uuid'});
  });

  group('InventoryRepositoryImpl Battlepass Detection & Valuation', () {
    test('cross-checks bpRewardUuids and marks Battlepass skin accurately',
        () async {
      final result = await repository.getInventoryOverview(forceRefresh: true);

      expect(result.isSuccess, isTrue);
      final overview = result.valueOrNull!;

      expect(overview.totalSkinsCount, equals(2));
      expect(overview.battlepassSkinsCount, equals(1));
      expect(overview.storeSkinsCount, equals(1));

      final bpSkin =
          overview.ownedSkins.firstWhere((s) => s.uuid == 'skin-bp-uuid');
      expect(bpSkin.isBattlepass, isTrue);
      expect(bpSkin.cost, equals(0));

      final storeSkin =
          overview.ownedSkins.firstWhere((s) => s.uuid == 'skin-store-uuid');
      expect(storeSkin.isBattlepass, isFalse);
      expect(storeSkin.cost, equals(1775));

      // Valuation should ONLY include Store skin (1775 VP)
      expect(overview.totalVpSpent, equals(1775));
      expect(overview.totalEstimatedIdr, equals(1775 * 135));

      // Should save updated catalog skins to localStore
      verify(() => mockLocalStore.saveCachedSkins(any())).called(1);
    });

    test('discards stale cache where battlepassSkinsCount is 0 on multiple skins',
        () async {
      final staleCacheJson = {
        'totalVpSpent': 10000,
        'totalEstimatedIdr': 1350000,
        'totalSkinsCount': 5,
        'tierBreakdown': {},
        'ownedSkins': [
          {'uuid': '1', 'displayName': 'Skin 1', 'isBattlepass': false},
          {'uuid': '2', 'displayName': 'Skin 2', 'isBattlepass': false},
          {'uuid': '3', 'displayName': 'Skin 3', 'isBattlepass': false},
          {'uuid': '4', 'displayName': 'Skin 4', 'isBattlepass': false},
          {'uuid': '5', 'displayName': 'Skin 5', 'isBattlepass': false},
        ],
        'equippedWeapons': [],
      };

      when(() => mockLocalStore.getMap('cached_inventory_overview_v2_$testPuuid'))
          .thenReturn(staleCacheJson);

      final result = await repository.getInventoryOverview(forceRefresh: false);

      expect(result.isSuccess, isTrue);
      // Because cache was stale (5 skins, 0 BP), it re-fetched and returned fresh data
      expect(result.valueOrNull!.battlepassSkinsCount, equals(1));
      verify(() => mockRemoteDataSource.fetchSkinEntitlements(
            shard: testShard,
            puuid: testPuuid,
          )).called(1);
    });
  });
}
