/// Retry interceptor with exponential backoff.
///
/// Retries failed requests up to [maxRetries] times with
/// increasing delays. Handles network errors, timeouts,
/// and 5xx server errors.

import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = ApiConstants.maxRetries,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    if (_shouldRetry(err) && retryCount < maxRetries) {
      final delay = _calculateDelay(retryCount);
      if (kDebugMode) {
        debugPrint(
          '🔄 Retry ${retryCount + 1}/$maxRetries after ${delay.inMilliseconds}ms '
          '— ${err.requestOptions.uri}',
        );
      }

      await Future<void>.delayed(delay);

      try {
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }

    handler.next(err);
  }

  /// Determine if request should be retried.
  bool _shouldRetry(DioException err) {
    // Don't retry on 401 (auth) or 403 (forbidden)
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 || statusCode == 403 || statusCode == 404) {
      return false;
    }

    // Retry on network errors
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    // Retry on 5xx server errors
    if (statusCode != null && statusCode >= 500) {
      return true;
    }

    // Retry on 429 (rate limit)
    if (statusCode == 429) {
      return true;
    }

    return false;
  }

  /// Exponential backoff: 1s, 2s, 4s (with jitter).
  Duration _calculateDelay(int retryCount) {
    final baseDelay = Duration(seconds: pow(2, retryCount).toInt());
    final jitter = Duration(milliseconds: Random().nextInt(500));
    return baseDelay + jitter;
  }
}
