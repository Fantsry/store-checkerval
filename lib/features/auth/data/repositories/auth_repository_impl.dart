import 'package:valorant_store_tracker/core/error/exceptions.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:valorant_store_tracker/features/auth/domain/entities/auth_login_result.dart';
import 'package:valorant_store_tracker/features/auth/domain/entities/auth_session.dart';
import 'package:valorant_store_tracker/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;
  final LocalStoreService? _localStore;
  final Future<void> Function()? _onLogout;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService storage,
    LocalStoreService? localStore,
    Future<void> Function()? onLogout,
  })  : _remoteDataSource = remoteDataSource,
        _storage = storage,
        _localStore = localStore,
        _onLogout = onLogout;

  static final RegExp _puuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool _isValidPuuid(String? puuid) =>
      puuid != null && _puuidPattern.hasMatch(puuid);

  static String _regionToShard(String region) {
    switch (region.toLowerCase().trim()) {
      case 'latam':
      case 'br':
      case 'na':
      case 'pbe':
        return 'na';
      case 'eu':
        return 'eu';
      case 'kr':
        return 'kr';
      case 'ap':
      default:
        return 'ap';
    }
  }

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

        return switch (sessionResult) {
          Success(:final value) => Result.success(AuthLoginSuccess(value)),
          Error(:final failure) => Result.failure(failure),
        };
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

        return switch (sessionResult) {
          Success(:final value) => Result.success(value),
          Error(:final failure) => Result.failure(failure),
        };
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
    String? manualRegion,
  }) async {
    try {
      if (accessToken.trim().isEmpty || idToken.trim().isEmpty) {
        throw const AuthException(message: 'Missing Riot authentication tokens');
      }

      // 1. Fetch entitlements token
      final entitlementsToken =
          await _remoteDataSource.getEntitlementsToken(accessToken);

      // 2. Fetch UserInfo for PUUID & account name
      final userInfo = await _remoteDataSource.getUserInfo(accessToken);
      final puuid = (userInfo['sub'] as String? ?? '').trim();
      if (!_isValidPuuid(puuid)) {
        throw const AuthException(
          message: 'Riot did not return a valid PUUID for this session',
        );
      }
      final acct = userInfo['acct'] as Map<String, dynamic>?;
      final gameName = acct?['game_name'] as String?;
      final tagLine = acct?['tag_line'] as String?;

      // 3. Determine region / shard via PAS Geo. Never silently guess a
      // region: a wrong shard makes every Riot API request target the wrong
      // data center. If geo lookup fails, require an explicit manual choice.
      Map<String, String>? geo;
      try {
        geo = await _remoteDataSource.getPasGeo(
          accessToken: accessToken,
          idToken: idToken,
        );
      } on AuthException catch (e) {
        if (manualRegion == null || manualRegion.trim().isEmpty) {
          throw AuthException(
            message:
                '${e.message} Select your region manually and try again.',
            statusCode: e.statusCode,
          );
        }
      } on ServerException catch (e) {
        if (manualRegion == null || manualRegion.trim().isEmpty) {
          throw AuthException(message: e.message, statusCode: e.statusCode);
        }
      }

      final detectedRegion = (geo?['region'] ?? '').trim();
      final selectedRegion = detectedRegion.isNotEmpty
          ? detectedRegion
          : (manualRegion ?? '').trim();
      if (selectedRegion.isEmpty) {
        throw const AuthException(
          message:
              'Unable to detect your Riot region. Choose a region manually and try again.',
        );
      }
      final region = selectedRegion.toLowerCase();
      final shard = (geo?['shard'] ?? '').trim().isNotEmpty
          ? geo!['shard']!.trim().toLowerCase()
          : _regionToShard(region);

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
      // Persist dedicated SSID cookie for resilient long-term rolling sessions
      final ssidMatch = RegExp(r'(?:^|;\s*)ssid=([^;]+)').firstMatch(cookieJar);
      if (ssidMatch != null) {
        await _storage.setSsidCookie(ssidMatch.group(1)!);
      }
      if (gameName != null && gameName.isNotEmpty) {
        await _storage.setGameName(gameName);
      }
      if (tagLine != null && tagLine.isNotEmpty) {
        await _storage.setTagLine(tagLine);
      }

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
      var cookieJar = await _storage.getCookieJar();
      final savedSsid = await _storage.getSsidCookie();
      if ((cookieJar == null || cookieJar.isEmpty) &&
          savedSsid != null &&
          savedSsid.isNotEmpty) {
        cookieJar = 'ssid=$savedSsid';
      } else if (cookieJar != null &&
          savedSsid != null &&
          savedSsid.isNotEmpty &&
          !cookieJar.contains('ssid=')) {
        cookieJar = 'ssid=$savedSsid; $cookieJar';
      }

      if (cookieJar == null || cookieJar.isEmpty) {
        return const Result.failure(
          AuthFailure(message: 'No saved session cookie for reauth'),
        );
      }

      final tokens = await _remoteDataSource.reauthorizeSilent(cookieJar);
      final accessToken = tokens['access_token']!;
      final idToken = tokens['id_token']!;
      final updatedCookies = tokens['cookieJar'] ?? cookieJar;

      return await loginWithTokens(
        accessToken: accessToken,
        idToken: idToken,
        cookieJar: updatedCookies,
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
      // Stop background work first so it cannot repopulate the caches we clear.
      try {
        await _onLogout?.call();
      } catch (_) {}
      Object? cacheError;
      try {
        await _localStore?.clearAccountCaches();
      } catch (e) {
        cacheError = e;
      }
      await _storage.clearAll();
      if (cacheError != null) {
        return Result.failure(
          CacheFailure(message: 'Logout cache cleanup failed: $cacheError'),
        );
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: 'Logout failed: $e'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final puuid = await _storage.getPuuid();
    if (!_isValidPuuid(puuid)) return false;
    final accessToken = await _storage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) return true;
    final cookieJar = await _storage.getCookieJar();
    return cookieJar != null && cookieJar.isNotEmpty;
  }

  @override
  Future<AuthSession?> getCachedSession() async {
    final puuid = await _storage.getPuuid();
    if (!_isValidPuuid(puuid)) return null;

    var accessToken = await _storage.getAccessToken();
    var idToken = await _storage.getIdToken();
    var entitlementsToken = await _storage.getEntitlementsToken();
    final shard = await _storage.getShard();
    final region = await _storage.getRegion();
    final cookieJar = await _storage.getCookieJar();
    final gameName = await _storage.getGameName();
    final tagLine = await _storage.getTagLine();

    // If tokens are missing/cleared but we have a valid cookie session, attempt silent reauth
    if ((accessToken == null || idToken == null || entitlementsToken == null) &&
        cookieJar != null &&
        cookieJar.isNotEmpty) {
      final reauthResult = await silentReauth();
      if (reauthResult.isSuccess) {
        return reauthResult.valueOrNull;
      }
    }

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
      gameName: gameName,
      tagLine: tagLine,
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
      return const Result.success('release-13.08-shipping-14-5627607');
    }
  }
}
