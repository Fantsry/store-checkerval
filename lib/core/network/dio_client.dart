/// Dio HTTP client configuration.
///
/// Provides a pre-configured [Dio] instance with:
/// - Timeouts from [ApiConstants]
/// - [AuthInterceptor] for token management
/// - [RetryInterceptor] for exponential backoff
/// - Conditional logging (debug only)

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';
import 'package:valorant_store_tracker/core/network/auth_interceptor.dart';
import 'package:valorant_store_tracker/core/network/retry_interceptor.dart';

class DioClient {
  late final Dio _dio;

  DioClient({
    required AuthInterceptor authInterceptor,
  }) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Order matters: auth → retry → logging
    _dio.interceptors.addAll([
      authInterceptor,
      RetryInterceptor(dio: _dio),
      if (kDebugMode) _debugLogInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  /// Debug-only logging interceptor.
  /// Gated behind kDebugMode to prevent token leaks in release.
  InterceptorsWrapper _debugLogInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('┌── REQUEST ──────────────────────────');
        debugPrint('│ ${options.method} ${options.uri}');
        debugPrint('└────────────────────────────────────');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('┌── RESPONSE ─────────────────────────');
        debugPrint('│ ${response.statusCode} ${response.requestOptions.uri}');
        debugPrint('└────────────────────────────────────');
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('┌── ERROR ────────────────────────────');
        debugPrint('│ ${error.response?.statusCode} ${error.requestOptions.uri}');
        debugPrint('│ ${error.message}');
        debugPrint('└────────────────────────────────────');
        handler.next(error);
      },
    );
  }
}
