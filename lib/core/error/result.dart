/// Lightweight Result type for domain layer.
///
/// Wraps either a [Failure] (left) or a success value [T] (right).
/// Avoids pulling in heavy packages like dartz/fpdart.

import 'package:valorant_store_tracker/core/error/failures.dart';

/// A type that represents either a [Failure] or a [T] success value.
sealed class Result<T> {
  const Result();

  /// Creates a success result.
  const factory Result.success(T value) = Success<T>;

  /// Creates a failure result.
  const factory Result.failure(Failure failure) = Error<T>;

  /// Pattern match on the result.
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  });

  /// Whether this is a success.
  bool get isSuccess => this is Success<T>;

  /// Whether this is a failure.
  bool get isFailure => this is Error<T>;

  /// Get the value or null.
  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Error() => null,
  };

  /// Get the failure or null.
  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Error(:final failure) => failure,
  };
}

/// Success variant of [Result].
class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) => success(value);
}

/// Error variant of [Result].
class Error<T> extends Result<T> {
  final Failure failure;

  const Error(this.failure);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) => failure(this.failure);
}
