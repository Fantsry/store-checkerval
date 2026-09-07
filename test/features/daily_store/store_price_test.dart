import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
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
}
