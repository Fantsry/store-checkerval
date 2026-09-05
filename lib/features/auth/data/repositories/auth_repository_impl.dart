import 'package:valorant_store_tracker/core/error/exceptions.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:valorant_store_tracker/features/auth/domain/entities/auth_login_result.dart';
import 'package:valorant_store_tracker/features/auth/domain/entities/auth_session.dart';
import 'package:valorant_store_tracker/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService storage,
  })  : _remoteDataSource = remoteDataSource,
        _storage = storage;

  @override
  Future<Result<AuthLoginResult>> loginWithCredentials({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _remoteDataSource.loginWithCredentials(
        username: username,
        password: password,
      );

      final status = res['status'] as String?;

      if (status == '2fa_required') {
        return Result.success(
          AuthLogin2FaRequired(
            email: res['email'] as String? ?? 'your registered email',
            method: res['method'] as String? ?? 'email',
            sessionCookies: res['sessionCookies'] as String? ?? '',
          ),
        );
      } else if (status == 'success') {
        final sessionResult = await loginWithTokens(
          accessToken: res['access_token'] as String,
          idToken: res['id_token'] as String,
          cookieJar: res['cookieJar'] as String,
        );

        return sessionResult.when(
          success: (session) => Result.success(AuthLoginSuccess(session)),
          failure: (failure) => Result.failure(failure),
        );
      }

      return const Result.failure(
        AuthFailure(message: 'Unexpected authentication response from Riot.'),
      );
    } on AuthException catch (e) {
      return Result.failure(
        AuthFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Sign in failed: $e'),
      );
    }
  }

  @override
  Future<Result<AuthSession>> submit2FaCode({
    required String code,
    required String sessionCookies,
  }) async {
    try {
      final res = await _remoteDataSource.submit2FaCode(
        code: code,
        sessionCookies: sessionCookies,
      );

      final accessToken = res['access_token']!;
      final idToken = res['id_token']!;
      final cookieJar = res['cookieJar']!;

      return await loginWithTokens(
        accessToken: accessToken,
        idToken: idToken,
        cookieJar: cookieJar,
      );
    } on AuthException catch (e) {
      return Result.failure(
        AuthFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: '2FA verification error: $e'),
      );
    }
  }

  @override
  Future<Result<AuthSession?>> checkMfaStatus({
    required String sessionCookies,
  }) async {
    try {
      final res = await _remoteDataSource.checkMfaStatus(
        sessionCookies: sessionCookies,
      );

      final status = res['status'] as String?;
      if (status == 'success') {
        final accessToken = res['access_token'] as String;
        final idToken = res['id_token'] as String;
        final cookieJar = res['cookieJar'] as String;

        final sessionResult = await loginWithTokens(
          accessToken: accessToken,
          idToken: idToken,
          cookieJar: cookieJar,
        );

        return sessionResult.when(
          success: (session) => Result.success(session),
          failure: (failure) => Result.failure(failure),
        );
      }

      // Still pending — save updated cookies for next poll cycle
      final updatedCookies = res['sessionCookies'] as String?;
      if (updatedCookies != null && updatedCookies.isNotEmpty) {
        await _storage.setCookieJar(updatedCookies);
      }

      return const Result.success(null);
    } catch (e) {
      return const Result.success(null);
    }
  }

  @override
  Future<Result<AuthSession>> loginWithTokens({
    required String accessToken,
    required String idToken,
    required String cookieJar,
  }) async {
    try {
      // 1. Fetch entitlements token
      final entitlementsToken =
          await _remoteDataSource.getEntitlementsToken(accessToken);

      // 2. Fetch UserInfo for PUUID & account name
      final userInfo = await _remoteDataSource.getUserInfo(accessToken);
      final puuid = userInfo['sub'] as String? ?? '';
      final acct = userInfo['acct'] as Map<String, dynamic>?;
      final gameName = acct?['game_name'] as String?;
      final tagLine = acct?['tag_line'] as String?;

      // 3. Determine region / shard via PAS Geo
      final geo = await _remoteDataSource.getPasGeo(
        accessToken: accessToken,
        idToken: idToken,
      );
      final shard = geo['shard'] ?? 'ap';
      final region = geo['region'] ?? 'ap';

      // 4. Cache client version
      await getClientVersion();

      // 5. Store session in SecureStorage
      await _storage.setAccessToken(accessToken);
      await _storage.setIdToken(idToken);
      await _storage.setEntitlementsToken(entitlementsToken);
      await _storage.setPuuid(puuid);
      await _storage.setShard(shard);
      await _storage.setRegion(region);
      await _storage.setCookieJar(cookieJar);

      final session = AuthSession(
        accessToken: accessToken,
        idToken: idToken,
        entitlementsToken: entitlementsToken,
        puuid: puuid,
        shard: shard,
        region: region,
        cookieJar: cookieJar,
        gameName: gameName,
        tagLine: tagLine,
      );

      return Result.success(session);
    } on AuthException catch (e) {
      return Result.failure(
        AuthFailure(message: e.message, statusCode: e.statusCode),
      );
    } on ServerException catch (e) {
      return Result.failure(
        ServerFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Authentication failed: $e'),
      );
    }
  }

  @override
  Future<Result<AuthSession>> silentReauth() async {
    try {
      final cookieJar = await _storage.getCookieJar();
      if (cookieJar == null || cookieJar.isEmpty) {
        return const Result.failure(
          AuthFailure(message: 'No saved session cookie for reauth'),
        );
      }

      final tokens = await _remoteDataSource.reauthorizeSilent(cookieJar);
      final accessToken = tokens['access_token']!;
      final idToken = tokens['id_token']!;

      return await loginWithTokens(
        accessToken: accessToken,
        idToken: idToken,
        cookieJar: cookieJar,
      );
    } on AuthException catch (e) {
      return Result.failure(
        AuthFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Silent reauth error: $e'),
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _storage.clearAll();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: 'Logout failed: $e'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final accessToken = await _storage.getAccessToken();
    final puuid = await _storage.getPuuid();
    return accessToken != null &&
        accessToken.isNotEmpty &&
        puuid != null &&
        puuid.isNotEmpty;
  }

  @override
  Future<AuthSession?> getCachedSession() async {
    final accessToken = await _storage.getAccessToken();
    final idToken = await _storage.getIdToken();
    final entitlementsToken = await _storage.getEntitlementsToken();
    final puuid = await _storage.getPuuid();
    final shard = await _storage.getShard();
    final region = await _storage.getRegion();
    final cookieJar = await _storage.getCookieJar();

    if (accessToken == null ||
        idToken == null ||
        entitlementsToken == null ||
        puuid == null) {
      return null;
    }

    return AuthSession(
      accessToken: accessToken,
      idToken: idToken,
      entitlementsToken: entitlementsToken,
      puuid: puuid,
      shard: shard ?? 'ap',
      region: region ?? 'ap',
      cookieJar: cookieJar ?? '',
    );
  }

  @override
  Future<Result<String>> getClientVersion() async {
    try {
      final cached = await _storage.getClientVersion();
      final tsStr = await _storage.getClientVersionTimestamp();
      if (cached != null && tsStr != null) {
        final ts = DateTime.tryParse(tsStr);
        // Cache valid for 24 hours
        if (ts != null &&
            DateTime.now().difference(ts) < const Duration(hours: 24)) {
          return Result.success(cached);
        }
      }

      final version = await _remoteDataSource.getClientVersion();
      await _storage.setClientVersion(version);
      await _storage.setClientVersionTimestamp(
        DateTime.now().toIso8601String(),
      );
      return Result.success(version);
    } catch (e) {
      final fallback = await _storage.getClientVersion();
      if (fallback != null) {
        return Result.success(fallback);
      }
      return const Result.success('release-09.08-shipping-9-2917531');
    }
  }
}
