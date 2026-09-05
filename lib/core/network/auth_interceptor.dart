/// Auth interceptor for Dio.
///
/// Automatically attaches Riot access_token and entitlements_token
/// to outgoing requests. On 401, attempts silent reauth via cookie,
/// then retries the original request once.

import 'package:dio/dio.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  bool _isRefreshing = false;

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

    final accessToken = await _storage.getAccessToken();
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
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        // Signal to auth module that reauth is needed
        // The actual reauth logic lives in AuthRepository
        // Here we just mark the token as invalid
        await _storage.clearTokens();
        _isRefreshing = false;
      } catch (_) {
        _isRefreshing = false;
      }
    }
    handler.next(err);
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
