import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:valorant_store_tracker/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';

class MockProfileRemoteDataSource extends Mock implements ProfileRemoteDataSource {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockLocalStoreService extends Mock implements LocalStoreService {}

void main() {
  late MockProfileRemoteDataSource mockRemote;
  late MockSecureStorageService mockSecureStorage;
  late MockLocalStoreService mockLocalStore;
  late ProfileRepositoryImpl repository;

  const tPuuid = '11111111-2222-3333-4444-555555555555';
  const tInGameCardUuid = '8edf22c5-4489-ab41-769a-07adb4c454d6';
  const tTitleUuid = 'd1357591-450f-24d4-d130-1b866c1f5139';

  const tCachedValidProfile = UserProfile(
    puuid: tPuuid,
    gameName: 'Irfan',
    tagLine: 'VAL',
    accountLevel: 100,
    cardUuid: tInGameCardUuid,
    cardName: 'Prime Card',
    cardWideArt: 'https://media.valorant-api.com/playercards/$tInGameCardUuid/wideart.png',
    cardSmallArt: 'https://media.valorant-api.com/playercards/$tInGameCardUuid/smallart.png',
    cardLargeArt: 'https://media.valorant-api.com/playercards/$tInGameCardUuid/largeart.png',
    region: 'ap',
    shard: 'ap',
  );

  const tCachedDefaultBannerProfile = UserProfile(
    puuid: tPuuid,
    gameName: 'Irfan',
    tagLine: 'VAL',
    accountLevel: 100,
    cardUuid: '9fb348bc-41a0-91ad-8a3e-818035c4e561',
    cardName: 'VALORANT Card',
    cardWideArt: 'https://media.valorant-api.com/playercards/9fb348bc-41a0-91ad-8a3e-818035c4e561/wideart.png',
    region: 'ap',
    shard: 'ap',
  );

  setUpAll(() {
    registerFallbackValue(tCachedValidProfile);
  });

  setUp(() {
    mockRemote = MockProfileRemoteDataSource();
    mockSecureStorage = MockSecureStorageService();
    mockLocalStore = MockLocalStoreService();

    repository = ProfileRepositoryImpl(
      remoteDataSource: mockRemote,
      storage: mockSecureStorage,
      localStore: mockLocalStore,
    );
  });

  group('ProfileRepositoryImpl', () {
    test('returns cached profile immediately when valid and not default banner', () async {
      when(() => mockLocalStore.getCachedProfile())
          .thenAnswer((_) async => tCachedValidProfile);

      final result = await repository.getUserProfile(forceRefresh: false);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, equals(tCachedValidProfile));
      // Primary response is cached
      expect(result.valueOrNull?.cardUuid, equals(tInGameCardUuid));
    });

    test('invalidates cache and fetches fresh in-game card if cached profile is default VALORANT Card banner', () async {
      when(() => mockLocalStore.getCachedProfile())
          .thenAnswer((_) async => tCachedDefaultBannerProfile);
      when(() => mockSecureStorage.getPuuid()).thenAnswer((_) async => tPuuid);
      when(() => mockSecureStorage.getShard()).thenAnswer((_) async => 'ap');
      when(() => mockSecureStorage.getRegion()).thenAnswer((_) async => 'ap');
      when(() => mockSecureStorage.getGameName()).thenAnswer((_) async => 'Irfan');
      when(() => mockSecureStorage.getTagLine()).thenAnswer((_) async => 'VAL');
      when(() => mockSecureStorage.setShard(any())).thenAnswer((_) async {});
      when(() => mockSecureStorage.setGameName(any())).thenAnswer((_) async {});
      when(() => mockSecureStorage.setTagLine(any())).thenAnswer((_) async {});

      when(() => mockRemote.fetchPlayerName(shard: 'ap', puuid: tPuuid))
          .thenAnswer((_) async => {'gameName': 'Irfan', 'tagLine': 'VAL', 'resolvedShard': 'ap'});

      when(() => mockRemote.fetchPlayerIdentity(shard: 'ap', puuid: tPuuid))
          .thenAnswer((_) async => {
                'identity': {
                  'PlayerCardID': tInGameCardUuid,
                  'PlayerTitleID': tTitleUuid,
                  'AccountLevel': 105,
                },
                'resolvedShard': 'ap',
              });

      when(() => mockRemote.fetchAccountXp(shard: 'ap', puuid: tPuuid))
          .thenAnswer((_) async => {'Progress': {'Level': 105, 'XP': 500}});

      when(() => mockRemote.fetchPlayerCardDetails(tInGameCardUuid))
          .thenAnswer((_) async => {
                'uuid': tInGameCardUuid,
                'displayName': 'Prime Card',
                'wideArt': 'https://media.valorant-api.com/playercards/$tInGameCardUuid/wideart.png',
                'smallArt': 'https://media.valorant-api.com/playercards/$tInGameCardUuid/smallart.png',
                'largeArt': 'https://media.valorant-api.com/playercards/$tInGameCardUuid/largeart.png',
              });

      when(() => mockRemote.fetchPlayerTitleText(tTitleUuid))
          .thenAnswer((_) async => 'Prime Agent');

      when(() => mockRemote.fetchWallet(shard: 'ap', puuid: tPuuid))
          .thenAnswer((_) async => {'vp': 1500, 'rp': 50, 'kc': 4000});

      when(() => mockLocalStore.saveCachedProfile(any())).thenAnswer((_) async {});

      final result = await repository.getUserProfile(forceRefresh: false);

      expect(result.isSuccess, isTrue);
      final profile = result.valueOrNull!;
      expect(profile.cardUuid, equals(tInGameCardUuid));
      expect(profile.cardName, equals('Prime Card'));
      expect(profile.cardWideArt, contains(tInGameCardUuid));
      expect(profile.titleText, equals('Prime Agent'));
      expect(profile.accountLevel, equals(105));
      verify(() => mockRemote.fetchPlayerIdentity(shard: 'ap', puuid: tPuuid)).called(1);
    });

    test('recovers PUUID from JWT token when storage PUUID is null', () async {
      // Create valid JWT with sub = tPuuid
      final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}')).replaceAll('=', '');
      final payload = base64Url.encode(utf8.encode('{"sub":"$tPuuid","exp":9999999999}')).replaceAll('=', '');
      final jwt = '$header.$payload.signature';

      when(() => mockLocalStore.getCachedProfile()).thenAnswer((_) async => null);
      when(() => mockSecureStorage.getPuuid()).thenAnswer((_) async => null);
      when(() => mockSecureStorage.getAccessToken()).thenAnswer((_) async => jwt);
      when(() => mockSecureStorage.setPuuid(tPuuid)).thenAnswer((_) async {});
      when(() => mockSecureStorage.getShard()).thenAnswer((_) async => 'ap');
      when(() => mockSecureStorage.getRegion()).thenAnswer((_) async => 'ap');
      when(() => mockSecureStorage.getGameName()).thenAnswer((_) async => 'Irfan');
      when(() => mockSecureStorage.getTagLine()).thenAnswer((_) async => 'VAL');
      when(() => mockSecureStorage.setShard(any())).thenAnswer((_) async {});
      when(() => mockSecureStorage.setGameName(any())).thenAnswer((_) async {});
      when(() => mockSecureStorage.setTagLine(any())).thenAnswer((_) async {});

      when(() => mockRemote.fetchPlayerName(shard: 'ap', puuid: tPuuid))
          .thenAnswer((_) async => {'gameName': 'Irfan', 'tagLine': 'VAL', 'resolvedShard': 'ap'});

      when(() => mockRemote.fetchPlayerIdentity(shard: 'ap', puuid: tPuuid))
          .thenAnswer((_) async => {
                'identity': {
                  'PlayerCardID': tInGameCardUuid,
                },
                'resolvedShard': 'ap',
              });

      when(() => mockRemote.fetchAccountXp(shard: 'ap', puuid: tPuuid))
          .thenAnswer((_) async => {});

      when(() => mockRemote.fetchPlayerCardDetails(tInGameCardUuid))
          .thenAnswer((_) async => {
                'uuid': tInGameCardUuid,
                'displayName': 'Sovereign Card',
                'wideArt': 'https://media.valorant-api.com/playercards/$tInGameCardUuid/wideart.png',
                'smallArt': 'https://media.valorant-api.com/playercards/$tInGameCardUuid/smallart.png',
              });

      when(() => mockRemote.fetchWallet(shard: 'ap', puuid: tPuuid))
          .thenAnswer((_) async => {'vp': 500, 'rp': 10, 'kc': 1000});

      when(() => mockLocalStore.saveCachedProfile(any())).thenAnswer((_) async {});

      final result = await repository.getUserProfile(forceRefresh: true);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.puuid, equals(tPuuid));
      expect(result.valueOrNull?.cardName, equals('Sovereign Card'));
      verify(() => mockSecureStorage.setPuuid(tPuuid)).called(1);
    });
  });
}
