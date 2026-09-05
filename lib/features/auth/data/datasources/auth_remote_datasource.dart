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

      // Try classic flat format first (used by SkinPeek and traditional Riot 2FA)
      var response = await authDio.put(
        ApiConstants.riotAuthToken,
        data: {
          'type': 'multifactor',
          'code': code.trim(),
          'rememberDevice': true,
        },
      );

      var updatedCookies = _extractCookies(response.headers, sessionCookies);
      var data = response.data as Map<String, dynamic>? ?? {};
      var type = data['type'] as String?;

      // If classic format wasn't accepted, try modern nested format per Riot docs
      if (type != 'response') {
        try {
          final nestedResponse = await authDio.put(
            ApiConstants.riotAuthToken,
            data: {
              'type': 'multifactor',
              'multifactor': {
                'otp': code.trim(),
                'rememberDevice': true,
              },
            },
          );
          final nestedData = nestedResponse.data as Map<String, dynamic>? ?? {};
          if (nestedData['type'] == 'response') {
            response = nestedResponse;
            data = nestedData;
            type = 'response';
            updatedCookies = _extractCookies(nestedResponse.headers, updatedCookies);
          } else if (nestedData['error'] != null) {
            data = nestedData;
          }
        } catch (_) {}
      }

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
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      // Strategy: Re-initialize auth session with existing cookies.
      // When user approves via Riot Mobile, the session is approved server-side.
      // 1. Check POST to /api/v1/authorization
      final response = await authDio.post(
        ApiConstants.riotAuthToken,
        data: {
          'client_id': ApiConstants.riotClientId,
          'nonce': ApiConstants.riotNonce,
          'redirect_uri': ApiConstants.riotRedirectUri,
          'response_type': ApiConstants.riotResponseType,
          'scope': ApiConstants.riotScope,
        },
      );

      final updatedCookies = _extractCookies(response.headers, sessionCookies);

      // Check if POST returned a redirect with tokens
      String? location = response.headers.value('location');
      if (location != null && location.contains('access_token')) {
        final uri = Uri.parse(location);
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

      // Check if POST returned JSON type == 'response'
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
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
        }
      }

      // 2. Also check GET /authorize (Cookie Reauth endpoint)
      // Once approved on Riot Mobile, GET /authorize redirects immediately with tokens
      try {
        final reauthResponse = await authDio.get(
          ApiConstants.authorizeUrl,
          options: Options(
            headers: {'Cookie': updatedCookies},
          ),
        );

        final reauthCookies = _extractCookies(reauthResponse.headers, updatedCookies);
        final reauthLoc = reauthResponse.headers.value('location');

        if (reauthLoc != null && reauthLoc.contains('access_token')) {
          final uri = Uri.parse(reauthLoc);
          final fragmentParams = Uri.splitQueryString(uri.fragment);
          final accessToken = fragmentParams['access_token'];
          final idToken = fragmentParams['id_token'];

          if (accessToken != null && idToken != null) {
            return {
              'status': 'success',
              'access_token': accessToken,
              'id_token': idToken,
              'cookieJar': reauthCookies,
            };
          }
        }
      } catch (_) {}

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

  static String _mapRegionToShard(String region) {
    final r = region.toLowerCase().trim();
    switch (r) {
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
  Future<Map<String, String>> getPasGeo({
    required String accessToken,
    required String idToken,
  }) async {
    try {
      final geoDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'User-Agent': _userAgent,
          },
        ),
      );

      final response = await geoDio.put(
        ApiConstants.pasGeoUrl,
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
          region = affinities['live'].toString().toLowerCase().trim();
          shard = _mapRegionToShard(region);
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
