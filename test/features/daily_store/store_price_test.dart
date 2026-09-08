import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/core/utils/skin_price_helper.dart';
import 'package:valorant_store_tracker/features/daily_store/data/datasources/riot_store_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/data/datasources/valorant_api_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/data/repositories/store_repository_impl.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';

class MockRiotStoreRemoteDataSource extends Mock
    implements RiotStoreRemoteDataSource {}

class MockValorantApiRemoteDataSource extends Mock
    implements ValorantApiRemoteDataSource {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockLocalStoreService extends Mock implements LocalStoreService {}

class FakeDailyStore extends Fake implements DailyStore {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDailyStore());
  });
  late StoreRepositoryImpl repository;
  late MockRiotStoreRemoteDataSource mockRiotRemote;
  late MockValorantApiRemoteDataSource mockValorantApi;
  late MockSecureStorageService mockSecureStorage;
  late MockLocalStoreService mockLocalStore;

  const tKuronamiSkin = SkinItem(
    uuid: 'kuronami-skin-uuid',
    displayName: 'Kuronami no Yaiba',
    weaponName: 'Melee',
    tierName: 'Exclusive',
    cost: 5350,
    levels: [
      SkinLevel(
        uuid: 'kuronami-level-1-uuid',
        displayName: 'Kuronami no Yaiba Level 1',
      ),
    ],
  );

  setUp(() {
    mockRiotRemote = MockRiotStoreRemoteDataSource();
    mockValorantApi = MockValorantApiRemoteDataSource();
    mockSecureStorage = MockSecureStorageService();
    mockLocalStore = MockLocalStoreService();

    repository = StoreRepositoryImpl(
      riotRemoteDataSource: mockRiotRemote,
      valorantApiRemoteDataSource: mockValorantApi,
      secureStorage: mockSecureStorage,
      localStore: mockLocalStore,
    );
  });

  test('extracts 5350 VP price accurately for Melee skin from Riot storefront',
      () async {
    when(() => mockSecureStorage.getPuuid())
        .thenAnswer((_) async => 'test-puuid');
    when(() => mockSecureStorage.getShard()).thenAnswer((_) async => 'ap');
    when(() => mockLocalStore.getCachedDailyStore())
        .thenAnswer((_) async => null);
    when(() => mockLocalStore.getCachedSkins())
        .thenAnswer((_) async => [tKuronamiSkin]);
    when(() => mockLocalStore.saveDailyStore(any()))
        .thenAnswer((_) async => {});

    // Riot storefront returns Offer with level UUID and 5350 VP cost
    when(() => mockRiotRemote.getStorefront(
          shard: any(named: 'shard'),
          puuid: any(named: 'puuid'),
        )).thenAnswer(
      (_) async => {
        'SkinsPanelLayout': {
          'SingleItemOffers': ['kuronami-level-1-uuid'],
          'SingleItemOffersRemainingDurationInSeconds': 86400,
          'SingleItemStoreOffers': [
            {
              'OfferID': 'riot-offer-id-1',
              'Cost': {
                RiotStoreRemoteDataSourceImpl.vpCurrencyUuid: 5350,
              },
              'Rewards': [
                {
                  'ItemTypeID': 'e7c63390-eda7-46e0-bb7a-a6abdacd2433',
                  'ItemID': 'kuronami-level-1-uuid',
                  'Quantity': 1,
                }
              ]
            }
          ],
        },
      },
    );

    final result = await repository.getDailyStore(forceRefresh: true);

    expect(result.isSuccess, isTrue);
    final dailyStore = result.valueOrNull!;
    expect(dailyStore.featuredOffers.length, equals(1));
    expect(dailyStore.featuredOffers.first.displayName,
        equals('Kuronami no Yaiba'));
    // Cost must be 5350 VP (from Riot storefront), not 2175 VP
    expect(dailyStore.featuredOffers.first.cost, equals(5350));
  });

  group('SkinPriceHelper Tests', () {
    test('accurately identifies non-traditional melee weapons', () {
      expect(
        SkinPriceHelper.isMelee(displayName: 'Phaseguard Splitter'),
        isTrue,
      );
      expect(
        SkinPriceHelper.isMelee(displayName: 'Power Fist'),
        isTrue,
      );
      expect(
        SkinPriceHelper.isMelee(displayName: 'Nocturnum Scythe'),
        isTrue,
      );
      expect(
        SkinPriceHelper.isMelee(displayName: 'Waveform'),
        isTrue,
      );
      expect(
        SkinPriceHelper.isMelee(displayName: 'VCT LOCK//IN Misericórdia'),
        isTrue,
      );
      expect(
        SkinPriceHelper.isMelee(displayName: 'Emberclad Hammer'),
        isTrue,
      );
    });

    test('does not misclassify guns ending with gun suffixes', () {
      expect(
        SkinPriceHelper.isMelee(displayName: 'Phaseguard Vandal'),
        isFalse,
      );
      expect(
        SkinPriceHelper.isMelee(displayName: 'Infantry Ghost'),
        isFalse,
      );
      expect(
        SkinPriceHelper.isMelee(displayName: 'Xerøfang Ghost'),
        isFalse,
      );
      expect(
        SkinPriceHelper.isMelee(displayName: 'Combat Crafts Frenzy'),
        isFalse,
      );
      expect(
        SkinPriceHelper.isMelee(displayName: 'Arcane Sheriff'),
        isFalse,
      );
    });

    test('accurately prices Phaseguard Splitter at 5350 VP', () {
      final price = SkinPriceHelper.calculateEstimatedPrice(
        displayName: 'Phaseguard Splitter',
        isMelee: true,
        tierName: 'Exclusive',
      );
      expect(price, equals(5350));
    });

    test('accurately prices Power Fist at 5950 VP', () {
      final price = SkinPriceHelper.calculateEstimatedPrice(
        displayName: 'Power Fist',
        isMelee: true,
        tierName: 'Exclusive',
      );
      expect(price, equals(5950));
    });

    test('accurately prices standard Exclusive melee at 4350 VP', () {
      final price = SkinPriceHelper.calculateEstimatedPrice(
        displayName: 'Araxys Bio-Harvester',
        isMelee: true,
        tierName: 'Exclusive',
      );
      expect(price, equals(4350));
    });

    test('accurately prices VCT LOCK//IN Misericórdia at 5440 VP', () {
      final price = SkinPriceHelper.calculateEstimatedPrice(
        displayName: 'VCT LOCK//IN Misericórdia',
        isMelee: true,
        tierName: 'Exclusive',
      );
      expect(price, equals(5440));
    });

    test('accurately prices Ultra Edition melee at 4950 VP', () {
      final price = SkinPriceHelper.calculateEstimatedPrice(
        displayName: "Evori's Spellcaster",
        isMelee: true,
        tierName: 'Ultra',
      );
      expect(price, equals(4950));
    });
  });

  group('getSkinDetail Self-Healing Tests', () {
    test('heals Phaseguard Splitter with 5350 VP and Melee weapon tag', () async {
      const stalePhaseguard = SkinItem(
        uuid: 'phaseguard-uuid',
        displayName: 'Phaseguard Splitter',
        weaponName: 'Weapon',
        cost: 2175,
        tierName: 'Exclusive',
      );

      when(() => mockLocalStore.getCachedSkins())
          .thenAnswer((_) async => [stalePhaseguard]);

      final result = await repository.getSkinDetail('phaseguard-uuid');
      expect(result.isSuccess, isTrue);
      final skin = result.valueOrNull!;
      expect(skin.cost, equals(5350));
      expect(skin.weaponName, equals('Melee'));
    });

    test('heals Power Fist with 5950 VP and Melee weapon tag', () async {
      const stalePowerFist = SkinItem(
        uuid: 'power-fist-uuid',
        displayName: 'Power Fist',
        weaponName: null,
        cost: 2175,
        tierName: 'Exclusive',
      );

      when(() => mockLocalStore.getCachedSkins())
          .thenAnswer((_) async => [stalePowerFist]);

      final result = await repository.getSkinDetail('power-fist-uuid');
      expect(result.isSuccess, isTrue);
      final skin = result.valueOrNull!;
      expect(skin.cost, equals(5950));
      expect(skin.weaponName, equals('Melee'));
    });
  });
}
