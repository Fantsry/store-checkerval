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
    when(() => mockLocalStore.saveLivePrice(any(), any()))
        .thenAnswer((_) async => {});

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
    test('accurately identifies melee weapons from API category, weaponName, and assetPath', () {
      // 1. From category in API
      expect(
        SkinPriceHelper.isMelee(category: 'EEquippableCategory::Melee'),
        isTrue,
      );

      // 2. From weaponName in API
      expect(
        SkinPriceHelper.isMelee(weaponName: 'Melee'),
        isTrue,
      );

      // 3. From engine assetPath
      expect(
        SkinPriceHelper.isMelee(
          assetPath: 'ShooterGame/Content/Equippables/Melee/Commando/Melee_Commando_PrimaryAsset',
        ),
        isTrue,
      );
      expect(
        SkinPriceHelper.isMelee(
          assetPath: 'ShooterGame/Content/Equippables/Melee/Arcade/Melee_Arcade_PrimaryAsset',
        ),
        isTrue,
      );

      // 4. Guns are not melee
      expect(
        SkinPriceHelper.isMelee(
          category: 'EEquippableCategory::Rifle',
          weaponName: 'Vandal',
          assetPath: 'ShooterGame/Content/Equippables/Guns/Rifles/AK/AssaultRifle_AK_PrimaryAsset',
        ),
        isFalse,
      );
    });

    test('accurately prices Melee based on Content Tier data', () {
      // Exclusive Melee (e.g. Phaseguard Splitter, Kuronami)
      expect(
        SkinPriceHelper.calculateEstimatedPrice(
          isMelee: true,
          tierName: 'Exclusive',
        ),
        equals(5350),
      );

      // Premium Melee (e.g. Reaver Knife)
      expect(
        SkinPriceHelper.calculateEstimatedPrice(
          isMelee: true,
          tierName: 'Premium',
        ),
        equals(3550),
      );

      // Deluxe Melee (e.g. Prism Knife)
      expect(
        SkinPriceHelper.calculateEstimatedPrice(
          isMelee: true,
          tierName: 'Deluxe',
        ),
        equals(2550),
      );

      // Select Melee (e.g. Luxe Knife)
      expect(
        SkinPriceHelper.calculateEstimatedPrice(
          isMelee: true,
          tierName: 'Select',
        ),
        equals(1750),
      );
    });

    test('uses live storefront price from Riot when available', () {
      expect(
        SkinPriceHelper.calculateEstimatedPrice(
          isMelee: true,
          tierName: 'Exclusive',
          liveStorePrice: 5950,
        ),
        equals(5950),
      );
    });
  });

  group('getSkinDetail Data-Driven Self-Healing Tests', () {
    test('heals Phaseguard Splitter with 5350 VP and Melee weapon tag from tier data', () async {
      const stalePhaseguard = SkinItem(
        uuid: 'phaseguard-uuid',
        displayName: 'Phaseguard Splitter',
        weaponName: 'Melee',
        cost: 2175,
        tierName: 'Exclusive',
      );

      when(() => mockLocalStore.getCachedSkins())
          .thenAnswer((_) async => [stalePhaseguard]);
      when(() => mockLocalStore.getLivePrice('phaseguard-uuid'))
          .thenReturn(null);

      final result = await repository.getSkinDetail('phaseguard-uuid');
      expect(result.isSuccess, isTrue);
      final skin = result.valueOrNull!;
      expect(skin.cost, equals(5350));
      expect(skin.weaponName, equals('Melee'));
    });

    test('heals Power Fist with live storefront price when recorded', () async {
      const stalePowerFist = SkinItem(
        uuid: 'power-fist-uuid',
        displayName: 'Power Fist',
        weaponName: 'Melee',
        cost: 2175,
        tierName: 'Exclusive',
      );

      when(() => mockLocalStore.getCachedSkins())
          .thenAnswer((_) async => [stalePowerFist]);
      when(() => mockLocalStore.getLivePrice('power-fist-uuid'))
          .thenReturn(5950);

      final result = await repository.getSkinDetail('power-fist-uuid');
      expect(result.isSuccess, isTrue);
      final skin = result.valueOrNull!;
      expect(skin.cost, equals(5950));
      expect(skin.weaponName, equals('Melee'));
    });
  });
}
