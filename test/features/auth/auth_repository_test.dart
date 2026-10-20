import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/exceptions.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:valorant_store_tracker/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockLocalStoreService extends Mock implements LocalStoreService {}

void main() {
  const tPuuid = '12345678-1234-1234-1234-123456789abc';
  const tAccessToken = 'access_123';
  const tIdToken = 'id_123';
  const tEntitlementsToken = 'ent_123';
  const tCookieJar = 'ssid=test';

  late MockAuthRemoteDataSource remote;
  late MockSecureStorageService storage;
  late MockLocalStoreService localStore;
  late AuthRepositoryImpl repository;
  late int logoutCleanupCalls;

  setUp(() {
    remote = MockAuthRemoteDataSource();
    storage = MockSecureStorageService();
    localStore = MockLocalStoreService();
    logoutCleanupCalls = 0;

    repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      storage: storage,
      localStore: localStore,
      onLogout: () async => logoutCleanupCalls++,
    );

    when(() => remote.getEntitlementsToken(any()))
        .thenAnswer((_) async => tEntitlementsToken);
    when(() => remote.getUserInfo(any())).thenAnswer(
      (_) async => {
        'sub': tPuuid,
        'acct': {'game_name': 'Test', 'tag_line': '1234'},
      },
    );
    when(() => remote.getPasGeo(
          accessToken: any(named: 'accessToken'),
          idToken: any(named: 'idToken'),
        )).thenAnswer((_) async => {'region': 'eu', 'shard': 'eu'});
    when(() => storage.getClientVersion()).thenAnswer((_) async => '13.08');
    when(() => storage.getClientVersionTimestamp())
        .thenAnswer((_) async => DateTime.now().toIso8601String());
    when(() => storage.setAccessToken(any())).thenAnswer((_) async {});
    when(() => storage.setIdToken(any())).thenAnswer((_) async {});
    when(() => storage.setEntitlementsToken(any())).thenAnswer((_) async {});
    when(() => storage.setPuuid(any())).thenAnswer((_) async {});
    when(() => storage.setShard(any())).thenAnswer((_) async {});
    when(() => storage.setRegion(any())).thenAnswer((_) async {});
    when(() => storage.setCookieJar(any())).thenAnswer((_) async {});
    when(() => storage.setSsidCookie(any())).thenAnswer((_) async {});
    when(() => storage.setGameName(any())).thenAnswer((_) async {});
    when(() => storage.setTagLine(any())).thenAnswer((_) async {});
    when(() => storage.clearAll()).thenAnswer((_) async {});
    when(() => localStore.clearAccountCaches()).thenAnswer((_) async {});
  });

  group('loginWithTokens', () {
    test('rejects an empty PUUID instead of persisting an invalid session',
        () async {
      when(() => remote.getUserInfo(any())).thenAnswer(
        (_) async => {
          'sub': '',
          'acct': {'game_name': 'Test', 'tag_line': '1234'},
        },
      );

      final result = await repository.loginWithTokens(
        accessToken: tAccessToken,
        idToken: tIdToken,
        cookieJar: tCookieJar,
      );

      expect(result, isA<Error<Object>>());
      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull!.message, contains('PUUID'));
      verifyNever(() => storage.setPuuid(any()));
      verifyNever(() => storage.setAccessToken(any()));
    });

    test('uses a manual region when PAS geo detection fails', () async {
      when(() => remote.getPasGeo(
            accessToken: any(named: 'accessToken'),
            idToken: any(named: 'idToken'),
          )).thenThrow(const AuthException(message: 'PAS unavailable'));

      final result = await repository.loginWithTokens(
        accessToken: tAccessToken,
        idToken: tIdToken,
        cookieJar: tCookieJar,
        manualRegion: 'eu',
      );

      expect(result, isA<Success<Object>>());
      verify(() => storage.setRegion('eu')).called(1);
      verify(() => storage.setShard('eu')).called(1);
      verify(() => storage.setPuuid(tPuuid)).called(1);
    });

    test('fails closed when PAS geo detection fails without a manual region',
        () async {
      when(() => remote.getPasGeo(
            accessToken: any(named: 'accessToken'),
            idToken: any(named: 'idToken'),
          )).thenThrow(const AuthException(message: 'PAS unavailable'));

      final result = await repository.loginWithTokens(
        accessToken: tAccessToken,
        idToken: tIdToken,
        cookieJar: tCookieJar,
      );

      expect(result, isA<Error<Object>>());
      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull!.message, contains('region'));
      verifyNever(() => storage.setPuuid(any()));
      verifyNever(() => storage.setAccessToken(any()));
    });
  });

  group('session validation', () {
    test('isLoggedIn rejects a malformed PUUID', () async {
      when(() => storage.getPuuid()).thenAnswer((_) async => 'not-a-puuid');
      when(() => storage.getAccessToken())
          .thenAnswer((_) async => tAccessToken);

      expect(await repository.isLoggedIn(), isFalse);
    });

    test('isLoggedIn accepts a UUID with a token or cookie jar', () async {
      when(() => storage.getPuuid()).thenAnswer((_) async => tPuuid);
      when(() => storage.getAccessToken())
          .thenAnswer((_) async => tAccessToken);

      expect(await repository.isLoggedIn(), isTrue);
    });

    test('getCachedSession rejects a malformed PUUID', () async {
      when(() => storage.getAccessToken())
          .thenAnswer((_) async => tAccessToken);
      when(() => storage.getIdToken()).thenAnswer((_) async => tIdToken);
      when(() => storage.getEntitlementsToken())
          .thenAnswer((_) async => tEntitlementsToken);
      when(() => storage.getPuuid()).thenAnswer((_) async => 'not-a-puuid');
      when(() => storage.getCookieJar()).thenAnswer((_) async => tCookieJar);

      expect(await repository.getCachedSession(), isNull);
    });
  });

  group('logout', () {
    test('clears secure storage, account caches, and background tasks',
        () async {
      final result = await repository.logout();

      expect(result.isSuccess, isTrue);
      verify(() => storage.clearAll()).called(1);
      verify(() => localStore.clearAccountCaches()).called(1);
      expect(logoutCleanupCalls, 1);
    });
  });
}
