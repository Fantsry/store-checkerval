import 'package:dio/dio.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';
import 'package:valorant_store_tracker/core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<String> getEntitlementsToken(String accessToken);
  Future<Map<String, dynamic>> getUserInfo(String accessToken);
  Future<Map<String, String>> getPasGeo({
    required String accessToken,
    required String idToken,
  });
  Future<Map<String, String>> reauthorizeSilent(String cookieJar);
  Future<String> getClientVersion();

  /// Direct credentials login supporting 2FA (Multi-Factor Authentication).
  Future<Map<String, dynamic>> loginWithCredentials({
    required String username,
    required String password,
  });

  /// Submits the 2FA verification code.
  Future<Map<String, String>> submit2FaCode({
    required String code,
    required String sessionCookies,
  });

  /// Checks if user approved sign-in via Riot Mobile.
  Future<Map<String, dynamic>> checkMfaStatus({
    required String sessionCookies,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  static const String _userAgent =
      'RiotClient/43.0.1.4195386.4190634 rso-auth (Windows; 10;;Enterprise; x64)';

  String _extractCookies(Headers headers, [String? existingCookies]) {
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

  @override
  Future<Map<String, dynamic>> loginWithCredentials({
    required String username,
    required String password,
  }) async {
    try {
      final authDio = Dio(
        BaseOptions(
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': _userAgent,
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      // Step 1: Initialize auth session
      final initResponse = await authDio.post(
        ApiConstants.riotAuthToken,
        data: {
          'client_id': ApiConstants.riotClientId,
          'nonce': ApiConstants.riotNonce,
          'redirect_uri': ApiConstants.riotRedirectUri,
          'response_type': ApiConstants.riotResponseType,
          'scope': ApiConstants.riotScope,
        },
      );

      String cookies = _extractCookies(initResponse.headers);

      // Step 2: Submit username & password
      final authResponse = await authDio.put(
        ApiConstants.riotAuthToken,
        options: Options(
          headers: {
            'Cookie': cookies,
          },
        ),
        data: {
          'type': 'auth',
          'username': username,
          'password': password,
          'remember': true,
        },
      );

      cookies = _extractCookies(authResponse.headers, cookies);
      final data = authResponse.data as Map<String, dynamic>? ?? {};

      final type = data['type'] as String?;

      if (type == 'response') {
        final responseObj = data['response'] as Map<String, dynamic>?;
        final params = responseObj?['parameters'] as Map<String, dynamic>?;
        final uriStr = params?['uri'] as String?;

        if (uriStr != null) {
          final uri = Uri.parse(uriStr);
          final fragmentParams = Uri.splitQueryString(uri.fragment);
          final accessToken = fragmentParams['access_token'];
          final idToken = fragmentParams['id_token'];

          if (accessToken != null && idToken != null) {
            return {
              'status': 'success',
              'access_token': accessToken,
              'id_token': idToken,
              'cookieJar': cookies,
            };
          }
        }
      } else if (type == 'multifactor') {
        final mfa = data['multifactor'] as Map<String, dynamic>? ?? {};
        final email = mfa['email'] as String? ?? 'your registered email';
        final method = mfa['method'] as String? ?? 'email';

        return {
          'status': '2fa_required',
          'email': email,
          'method': method,
          'sessionCookies': cookies,
        };
      } else if (data['error'] != null) {
        final err = data['error'].toString();
        if (err == 'auth_failure') {
          throw const AuthException(
            message: 'Invalid Riot username or password.',
          );
        } else if (err == 'rate_limited') {
          throw const AuthException(
            message: 'Too many attempts. Please wait a moment or sign in via WebView.',
          );
        }
      }

      throw const AuthException(
        message: 'Unable to sign in. Please verify your credentials or use Web Sign-In.',
      );
    } on DioException catch (e) {
      throw AuthException(
        message: e.message ?? 'Network error during login',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, String>> submit2FaCode({
    required String code,
    required String sessionCookies,
  }) async {
    try {
      final authDio = Dio(
        BaseOptions(
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': _userAgent,
            'Cookie': sessionCookies,
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      final response = await authDio.put(
        ApiConstants.riotAuthToken,
        data: {
          'type': 'multifactor',
          'code': code.trim(),
          'rememberDevice': true,
        },
      );

      final updatedCookies = _extractCookies(response.headers, sessionCookies);
      final data = response.data as Map<String, dynamic>? ?? {};
      final type = data['type'] as String?;

      if (type == 'response') {
        final responseObj = data['response'] as Map<String, dynamic>?;
        final params = responseObj?['parameters'] as Map<String, dynamic>?;
        final uriStr = params?['uri'] as String?;

        if (uriStr != null) {
          final uri = Uri.parse(uriStr);
          final fragmentParams = Uri.splitQueryString(uri.fragment);
          final accessToken = fragmentParams['access_token'];
          final idToken = fragmentParams['id_token'];

          if (accessToken != null && idToken != null) {
            return {
              'access_token': accessToken,
              'id_token': idToken,
              'cookieJar': updatedCookies,
            };
          }
        }
      } else if (data['error'] != null) {
        throw const AuthException(
          message: 'Incorrect 2FA verification code. Please try again.',
        );
      }

      throw const AuthException(
        message: '2FA verification failed. Please try again or use Web Sign-In.',
      );
    } on DioException catch (e) {
      throw AuthException(
        message: e.message ?? 'Network error during 2FA verification',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> checkMfaStatus({
    required String sessionCookies,
  }) async {
    try {
      final authDio = Dio(
        BaseOptions(
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': _userAgent,
            'Cookie': sessionCookies,
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      // PUT to authorization endpoint to check if push approval was completed.
      // Riot Mobile approval changes the session state server-side,
      // so re-sending the auth PUT will return 'response' type if approved.
      final response = await authDio.put(
        ApiConstants.riotAuthToken,
        data: {
          'type': 'multifactor',
          'code': '',
          'rememberDevice': true,
        },
      );

      final updatedCookies = _extractCookies(response.headers, sessionCookies);
      final data = response.data as Map<String, dynamic>? ?? {};
      final type = data['type'] as String?;

      if (type == 'response') {
        final responseObj = data['response'] as Map<String, dynamic>?;
        final params = responseObj?['parameters'] as Map<String, dynamic>?;
        final uriStr = params?['uri'] as String?;

        if (uriStr != null) {
          final uri = Uri.parse(uriStr);
          final fragmentParams = Uri.splitQueryString(uri.fragment);
          final accessToken = fragmentParams['access_token'];
          final idToken = fragmentParams['id_token'];

          if (accessToken != null && idToken != null) {
            return {
              'status': 'success',
              'access_token': accessToken,
              'id_token': idToken,
              'cookieJar': updatedCookies,
            };
          }
        }
      } else if (type == 'multifactor') {
        // Still waiting for approval — return updated cookies for next poll
        return {
          'status': 'pending',
          'sessionCookies': updatedCookies,
        };
      } else if (data['error'] != null) {
        // If error (e.g., multifactor_attempt_failed with empty code),
        // try a simple GET as fallback to check session state
        final fallbackResponse = await authDio.get(ApiConstants.riotAuthToken);
        final fbCookies =
            _extractCookies(fallbackResponse.headers, sessionCookies);
        final fbData = fallbackResponse.data as Map<String, dynamic>? ?? {};
        final fbType = fbData['type'] as String?;

        if (fbType == 'response') {
          final fbResp = fbData['response'] as Map<String, dynamic>?;
          final fbParams = fbResp?['parameters'] as Map<String, dynamic>?;
          final fbUri = fbParams?['uri'] as String?;

          if (fbUri != null) {
            final uri = Uri.parse(fbUri);
            final fragmentParams = Uri.splitQueryString(uri.fragment);
            final accessToken = fragmentParams['access_token'];
            final idToken = fragmentParams['id_token'];

            if (accessToken != null && idToken != null) {
              return {
                'status': 'success',
                'access_token': accessToken,
                'id_token': idToken,
                'cookieJar': fbCookies,
              };
            }
          }
        }

        return {'status': 'pending', 'sessionCookies': fbCookies};
      }

      return {'status': 'pending', 'sessionCookies': updatedCookies};
    } catch (_) {
      return {'status': 'pending', 'sessionCookies': sessionCookies};
    }
  }

  @override
  Future<String> getEntitlementsToken(String accessToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.riotEntitlementsUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
        data: {},
      );

      final token = response.data['entitlements_token'] as String?;
      if (token == null || token.isEmpty) {
        throw const ServerException(message: 'Entitlements token is empty');
      }
      return token;
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to fetch entitlements token',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getUserInfo(String accessToken) async {
    try {
      final response = await _dio.get(
        ApiConstants.riotUserInfoUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to fetch user info',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, String>> getPasGeo({
    required String accessToken,
    required String idToken,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.pasGeoUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'id_token': idToken,
        },
      );

      final data = response.data;
      String shard = 'ap';
      String region = 'ap';

      if (data is Map<String, dynamic>) {
        final affinities = data['affinities'];
        if (affinities is Map<String, dynamic> && affinities['live'] != null) {
          shard = affinities['live'].toString();
          region = affinities['live'].toString();
        }
      }

      return {'shard': shard, 'region': region};
    } catch (_) {
      return {'shard': 'ap', 'region': 'ap'};
    }
  }

  @override
  Future<Map<String, String>> reauthorizeSilent(String cookieJar) async {
    try {
      final dioNoRedirect = Dio(
        BaseOptions(
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
          headers: {
            'Cookie': cookieJar,
            'User-Agent': _userAgent,
          },
        ),
      );

      final response = await dioNoRedirect.get(ApiConstants.authorizeUrl);

      String? location = response.headers.value('location');
      if (location == null && response.data is Map) {
        final data = response.data as Map;
        if (data['response'] != null &&
            data['response']['parameters'] != null &&
            data['response']['parameters']['uri'] != null) {
          location = data['response']['parameters']['uri'] as String;
        }
      }

      if (location != null) {
        final uri = Uri.parse(location);
        final fragment = uri.fragment;
        final params = Uri.splitQueryString(fragment);
        final accessToken = params['access_token'];
        final idToken = params['id_token'];

        if (accessToken != null && idToken != null) {
          return {
            'access_token': accessToken,
            'id_token': idToken,
          };
        }
      }

      throw const AuthException(message: 'Silent re-authentication failed');
    } on DioException catch (e) {
      throw AuthException(
        message: e.message ?? 'Silent re-auth network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<String> getClientVersion() async {
    try {
      final response = await _dio.get(ApiConstants.valorantApiVersion);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        final version = data['data']['riotClientVersion'] as String?;
        if (version != null && version.isNotEmpty) {
          return version;
        }
      }
      return 'release-09.08-shipping-9-2917531';
    } catch (_) {
      return 'release-09.08-shipping-9-2917531';
    }
  }
}
