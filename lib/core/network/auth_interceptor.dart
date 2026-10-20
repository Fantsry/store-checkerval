/// Auth interceptor for Dio.
///
/// Automatically attaches Riot access_token and entitlements_token
/// to outgoing requests. Proactively checks token expiry, and on 401,
/// attempts silent reauth via stored cookieJar, then retries the original request once.

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  Completer<bool>? _refreshCompleter;

  AuthInterceptor({required SecureStorageService storage}) : _storage = storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only Riot-owned endpoints receive Riot credentials. Public metadata APIs
    // and arbitrary third-party hosts must never see the user's tokens.
    if (!_isRiotHost(options.uri)) {
      return handler.next(options);
    }

    final hasExplicitAuthorization = _hasHeader(options.headers, 'Authorization');
    final hasExplicitEntitlements =
        _hasHeader(options.headers, 'X-Riot-Entitlements-JWT');

    var accessToken = await _storage.getAccessToken();
    var entitlementsToken = await _storage.getEntitlementsToken();

    // Check if either access_token or entitlements_token is expired (or expiring in next 60 seconds)
    final isAccessExpired = accessToken != null && _isJwtExpired(accessToken);
    final isEntitlementsExpired =
        entitlementsToken != null && _isJwtExpired(entitlementsToken);

    if (isAccessExpired || isEntitlementsExpired) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        accessToken = await _storage.getAccessToken();
        entitlementsToken = await _storage.getEntitlementsToken();
      }
    }

    final clientVersion = await _resolveClientVersion();

    // Riot PDP and auth endpoints require RiotClient user-agent and client platform
    options.headers['User-Agent'] = _userAgent;
    options.headers['X-Riot-ClientPlatform'] = _clientPlatform;
    options.headers['X-Riot-ClientVersion'] = clientVersion;

    if (!hasExplicitAuthorization &&
        accessToken != null &&
        accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (!hasExplicitEntitlements &&
        entitlementsToken != null &&
        entitlementsToken.isNotEmpty) {
      options.headers['X-Riot-Entitlements-JWT'] = entitlementsToken;
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final isRiotRequest = _isRiotHost(err.requestOptions.uri);
    final hasExplicitAuthorization =
        _hasHeader(err.requestOptions.headers, 'Authorization');
    final isUnauthorized = statusCode == 401;
    final isBadClaims =
        statusCode == 400 && _isRiotAuthClaimError(err.response?.data);

    // Handle 401 Unauthorized or 400 BAD_CLAIMS (GLZ token expiry) by attempting silent re-authentication once.
    // Explicit Authorization calls own their credential lifecycle; never replace them with stored tokens.
    if ((isUnauthorized || isBadClaims) &&
        isRiotRequest &&
        !hasExplicitAuthorization &&
        err.requestOptions.extra['authRetried'] != true) {
      err.requestOptions.extra['authRetried'] = true;

      final refreshed = await _refreshToken();
      if (refreshed) {
        try {
          final newAccessToken = await _storage.getAccessToken();
          final newEntitlementsToken = await _storage.getEntitlementsToken();
          final clientVersion = await _resolveClientVersion();

          final options = err.requestOptions;
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $newAccessToken';
          }
          if (newEntitlementsToken != null && newEntitlementsToken.isNotEmpty) {
            options.headers['X-Riot-Entitlements-JWT'] = newEntitlementsToken;
          }
          options.headers['X-Riot-ClientVersion'] = clientVersion;

          // Retry request using an isolated Dio instance to avoid interceptor loop
          final retryDio = Dio();
          final response = await retryDio.fetch(options);
          return handler.resolve(response);
        } catch (retryErr) {
          if (retryErr is DioException) {
            return handler.next(retryErr);
          }
        }
      }
    }

    // Handle client-version mismatch only. A generic 400 (bad puuid, invalid
    // payload, etc.) must never trigger a version refresh/retry loop.
    final isVersionMismatch =
        statusCode == 400 && _isClientVersionError(err.response?.data);
    if (isVersionMismatch &&
        isRiotRequest &&
        err.requestOptions.extra['versionRetried'] != true) {
      err.requestOptions.extra['versionRetried'] = true;
      try {
        final newVersion = await _resolveClientVersion(forceRefresh: true);
        final options = err.requestOptions;
        options.headers['X-Riot-ClientVersion'] = newVersion;
        final retryDio = Dio();
        final response = await retryDio.fetch(options);
        return handler.resolve(response);
      } catch (retryErr) {
        if (retryErr is DioException) {
          return handler.next(retryErr);
        }
      }
    }

    handler.next(err);
  }

  static bool _isRiotHost(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'riotgames.com' ||
        host.endsWith('.riotgames.com') ||
        host == 'pvp.net' ||
        host.endsWith('.pvp.net');
  }

  static bool _hasHeader(Map<String, dynamic> headers, String name) {
    final target = name.toLowerCase();
    return headers.keys.any((key) => key.toLowerCase() == target);
  }

  bool _isClientVersionError(dynamic data) {
    final code = data is Map
        ? (data['errorCode'] ?? data['error_code'] ?? '').toString().toUpperCase()
        : '';
    final message = data is Map
        ? (data['message'] ?? data['errorMessage'] ?? '').toString().toUpperCase()
        : data?.toString().toUpperCase() ?? '';

    const versionCodes = {
      'INVALID_CLIENT_VERSION',
      'CLIENT_VERSION_MISMATCH',
      'BAD_CLIENT_VERSION',
      'VERSION_MISMATCH',
    };
    if (versionCodes.contains(code)) return true;

    return message.contains('CLIENT VERSION') ||
        message.contains('VERSION MISMATCH') ||
        message.contains('INVALID VERSION') ||
        message.contains('VERSION IS INVALID') ||
        message.contains('UNSUPPORTED VERSION');
  }

  bool _isRiotAuthClaimError(dynamic data) {
    if (data == null) return false;
    if (data is Map) {
      final errorCode = data['errorCode']?.toString().toUpperCase() ?? '';
      final message = data['message']?.toString().toUpperCase() ?? '';
      if (errorCode == 'BAD_CLAIMS' ||
          message.contains('BAD_CLAIMS') ||
          message.contains('RSO ACCESS TOKEN') ||
          (message.contains('TOKEN') && message.contains('VALIDAT'))) {
        return true;
      }
    } else if (data is String) {
      final upper = data.toUpperCase();
      if (upper.contains('BAD_CLAIMS') || upper.contains('RSO ACCESS TOKEN')) {
        return true;
      }
    }
    return false;
  }

  /// Silently reauthenticates with Riot using stored cookieJar.
  /// Deduplicates concurrent refresh attempts with a Completer.
  Future<bool> _refreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

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
        completer.complete(false);
        return false;
      }

      final isolatedDio = Dio(
        BaseOptions(
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': _userAgent,
            'Cookie': cookieJar,
          },
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      // Step 1: Try GET /authorize
      var response = await isolatedDio.get(ApiConstants.authorizeUrl);
      var updatedCookies = _extractCookies(response.headers, cookieJar);
      String? location = response.headers.value('location');

      if (location == null && response.data is Map) {
        final data = response.data as Map;
        if (data['response'] != null &&
            data['response']['parameters'] != null &&
            data['response']['parameters']['uri'] != null) {
          location = data['response']['parameters']['uri'] as String;
        }
      }

      // Step 2: Fallback to POST /api/v1/authorization if GET didn't return tokens
      if (location == null || !location.contains('access_token')) {
        final postResponse = await isolatedDio.post(
          ApiConstants.riotAuthToken,
          options: Options(headers: {'Cookie': updatedCookies}),
          data: {
            'client_id': ApiConstants.riotClientId,
            'nonce': ApiConstants.riotNonce,
            'redirect_uri': ApiConstants.riotRedirectUri,
            'response_type': ApiConstants.riotResponseType,
            'scope': ApiConstants.riotScope,
          },
        );
        updatedCookies = _extractCookies(postResponse.headers, updatedCookies);
        location = postResponse.headers.value('location');

        if (location == null && postResponse.data is Map) {
          final data = postResponse.data as Map;
          if (data['response'] != null &&
              data['response']['parameters'] != null &&
              data['response']['parameters']['uri'] != null) {
            location = data['response']['parameters']['uri'] as String;
          }
        }
      }

      if (location != null && location.contains('access_token')) {
        final uri = Uri.parse(location);
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        final newAccessToken = fragmentParams['access_token'];
        final newIdToken = fragmentParams['id_token'];

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Fetch new entitlements token
          final entResponse = await isolatedDio.post(
            ApiConstants.riotEntitlementsUrl,
            options: Options(
              headers: {
                'Authorization': 'Bearer $newAccessToken',
                'Content-Type': 'application/json',
              },
            ),
            data: {},
          );
          final newEntitlements =
              entResponse.data['entitlements_token'] as String?;

          await _storage.setAccessToken(newAccessToken);
          if (newIdToken != null) await _storage.setIdToken(newIdToken);
          if (newEntitlements != null) {
            await _storage.setEntitlementsToken(newEntitlements);
          }
          if (updatedCookies.isNotEmpty) {
            await _storage.setCookieJar(updatedCookies);
            final ssidMatch =
                RegExp(r'(?:^|;\s*)ssid=([^;]+)').firstMatch(updatedCookies);
            if (ssidMatch != null) {
              await _storage.setSsidCookie(ssidMatch.group(1)!);
            }
          }

          completer.complete(true);
          return true;
        }
      }

      completer.complete(false);
      return false;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Decodes JWT payload without external libraries and checks expiry.
  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      var normalized = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      final exp = payload['exp'] as int?;
      if (exp == null) return false;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      // Mark expired if expiry is within 60 seconds from now
      return DateTime.now().isAfter(expiryDate.subtract(const Duration(seconds: 60)));
    } catch (_) {
      return false;
    }
  }

  static String _extractCookies(Headers headers, [String? existingCookies]) {
    final setCookies = headers['set-cookie'] ?? [];
    final cookieMap = <String, String>{};

    if (existingCookies != null && existingCookies.isNotEmpty) {
      for (final pair in existingCookies.split(';')) {
        final parts = pair.trim().split('=');
        if (parts.length >= 2) {
          cookieMap[parts[0].trim()] = parts.sublist(1).join('=').trim();
        }
      }
    }

    for (final sc in setCookies) {
      final firstPart = sc.split(';').first.trim();
      final parts = firstPart.split('=');
      if (parts.length >= 2) {
        cookieMap[parts[0].trim()] = parts.sublist(1).join('=').trim();
      }
    }

    return cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  static const String defaultClientVersion =
      'release-13.08-shipping-14-5627607';

  static String? _cachedClientVersion;
  static DateTime? _cachedClientVersionTime;

  /// Resolves the current Riot Client Version dynamically from cache, storage, or valorant-api.com
  Future<String> _resolveClientVersion({bool forceRefresh = false}) async {
    final now = DateTime.now();

    // 1. Fast path: In-memory cache valid for 6 hours
    if (!forceRefresh &&
        _cachedClientVersion != null &&
        _cachedClientVersionTime != null &&
        now.difference(_cachedClientVersionTime!) < const Duration(hours: 6)) {
      return _cachedClientVersion!;
    }

    // 2. Storage cache check
    if (!forceRefresh) {
      try {
        final stored = await _storage.getClientVersion();
        if (stored != null && stored.isNotEmpty) {
          String? tsStr;
          try {
            tsStr = await _storage.getClientVersionTimestamp();
          } catch (_) {}
          if (tsStr != null) {
            final ts = DateTime.tryParse(tsStr);
            if (ts != null && now.difference(ts) < const Duration(hours: 12)) {
              _cachedClientVersion = stored;
              _cachedClientVersionTime = ts;
              return stored;
            }
          } else {
            // When stored without timestamp (e.g. in tests or initial setup), accept stored value
            _cachedClientVersion = stored;
            _cachedClientVersionTime = now;
            return stored;
          }
        }
      } catch (_) {}
    }

    // 3. Fetch fresh client version from valorant-api.com
    try {
      final isolatedDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final response = await isolatedDio.get(ApiConstants.valorantApiVersion);
      final data = response.data;
      if (data is Map && data['data'] != null) {
        final ver = data['data']['riotClientVersion'] as String?;
        if (ver != null && ver.isNotEmpty) {
          _cachedClientVersion = ver;
          _cachedClientVersionTime = now;
          await _storage.setClientVersion(ver);
          await _storage.setClientVersionTimestamp(now.toIso8601String());
          return ver;
        }
      }
    } catch (_) {}

    // 4. Fallback to existing storage or default
    try {
      final fallback = await _storage.getClientVersion();
      if (fallback != null && fallback.isNotEmpty) {
        _cachedClientVersion = fallback;
        _cachedClientVersionTime = now;
        return fallback;
      }
    } catch (_) {}

    _cachedClientVersion = defaultClientVersion;
    _cachedClientVersionTime = now;
    return defaultClientVersion;
  }

  static const String _userAgent =
      'RiotClient/111.0.0.3261.5663 rso-auth (Windows; 10;;Enterprise; x64)';

  /// Base64-encoded client platform header required by Riot API.
  static const String _clientPlatform =
      'ew0KCSJwbGF0Zm9ybVR5cGUiOiAiUEMiLA0KCSJwbGF0Zm9ybU9TIjog'
      'IldpbmRvd3MiLA0KCSJwbGF0Zm9ybU9TVmVyc2lvbiI6ICIxMC4wLjE5'
      'MDQyLjEuMjU2LjY0Yml0IiwNCgkicGxhdGZvcm1DaGlwc2V0IjogIlVu'
      'a25vd24iDQp9';
}
