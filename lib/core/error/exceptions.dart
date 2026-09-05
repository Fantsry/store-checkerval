/// Core exception classes — thrown at the data layer,
/// caught and converted to [Failure] in repository implementations.

/// Thrown when server returns non-2xx response
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when authentication fails (401, invalid cookie, etc.)
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException({
    this.message = 'Authentication failed',
    this.statusCode,
  });

  @override
  String toString() => 'AuthException($statusCode): $message';
}

/// Thrown when session/cookie is expired and needs re-login
class SessionExpiredException implements Exception {
  final String message;

  const SessionExpiredException({
    this.message = 'Session expired — please login again',
  });

  @override
  String toString() => 'SessionExpiredException: $message';
}

/// Thrown on cache read/write errors
class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache operation failed'});

  @override
  String toString() => 'CacheException: $message';
}

/// Thrown when rate limited by Riot API
class RateLimitException implements Exception {
  final Duration? retryAfter;

  const RateLimitException({this.retryAfter});

  @override
  String toString() => 'RateLimitException: retry after $retryAfter';
}
