/// Core error handling — Failure classes for Clean Architecture
///
/// Uses sealed classes for exhaustive pattern matching.
/// Domain layer only knows about [Failure], not platform exceptions.

import 'package:equatable/equatable.dart';

/// Base failure class — all domain-level errors extend this.
sealed class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Server/API error (Riot API, valorant-api.com, etc.)
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

/// Authentication error — token expired, cookie invalid, etc.
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode});
}

/// Network error — no connectivity
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

/// Local storage error — Isar, SecureStorage, etc.
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache operation failed'});
}

/// Unknown/unexpected error
class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'An unexpected error occurred'});
}

/// Timeout error
class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'Request timed out'});
}

/// Rate limit error from Riot API
class RateLimitFailure extends Failure {
  final Duration? retryAfter;

  const RateLimitFailure({
    super.message = 'Rate limited — please try again later',
    this.retryAfter,
  });

  @override
  List<Object?> get props => [...super.props, retryAfter];
}
