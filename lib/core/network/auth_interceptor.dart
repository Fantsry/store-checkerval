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
    // Skip auth headers for valorant-api.com (public API)
    if (options.uri.host.contains('valorant-api.com')) {
      return handler.next(options);
    }

    var accessToken = await _storage.getAccessToken();

    // Check if token is expired or expiring in next 60 seconds
    if (accessToken != null && _isJwtExpired(accessToken)) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        accessToken = await _storage.getAccessToken();
      }
    }

    final entitlementsToken = await _storage.getEntitlementsToken();
    final clientVersion = await _storage.getClientVersion() ??
        'release-13.05-shipping-11-5350494';

    // Riot PDP and auth endpoints require RiotClient user-agent and client platform
    options.headers['User-Agent'] = _userAgent;
    options.headers['X-Riot-ClientPlatform'] = _clientPlatform;
    options.headers['X-Riot-ClientVersion'] = clientVersion;

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (entitlementsToken != null && entitlementsToken.isNotEmpty) {
      options.headers['X-Riot-Entitlements-JWT'] = entitlementsToken;
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized by attempting silent re-authentication once
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['authRetried'] != true &&
        !err.requestOptions.uri.host.contains('valorant-api.com')) {
      err.requestOptions.extra['authRetried'] = true;

      final refreshed = await _refreshToken();
      if (refreshed) {
        try {
          final newAccessToken = await _storage.getAccessToken();
          final newEntitlementsToken = await _storage.getEntitlementsToken();
          final clientVersion = await _storage.getClientVersion() ??
              'release-13.05-shipping-11-5350494';

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
    handler.next(err);
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
      final cookieJar = await _storage.getCookieJar();
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

  static const String _userAgent =
      'RiotClient/43.0.1.4195386.4190634 rso-auth (Windows; 10;;Enterprise; x64)';

  /// Base64-encoded client platform header required by Riot API.
  static const String _clientPlatform =
      'ew0KCSJwbGF0Zm9ybVR5cGUiOiAiUEMiLA0KCSJwbGF0Zm9ybU9TIjog'
      'IldpbmRvd3MiLA0KCSJwbGF0Zm9ybU9TVmVyc2lvbiI6ICIxMC4wLjE5'
      'MDQyLjEuMjU2LjY0Yml0IiwNCgkicGxhdGZvcm1DaGlwc2V0IjogIlVu'
      'a25vd24iDQp9';
}
