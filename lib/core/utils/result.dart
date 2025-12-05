/// Result type for functional error handling
///
/// This provides an Either-like type for handling success and failure cases
/// without throwing exceptions across layer boundaries.

import '../errors/failures.dart';

/// Sealed class representing either a success or failure result
sealed class Result<T> {
  const Result();

  /// Creates a success result with the given value
  factory Result.success(T value) => Success(value);

  /// Creates a failure result with the given failure
  factory Result.failure(Failure failure) => Error(failure);

  /// Returns true if this is a success result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failure result
  bool get isFailure => this is Error<T>;

  /// Gets the success value or null if this is a failure
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Error() => null,
      };

  /// Gets the failure or null if this is a success
  Failure? get failureOrNull => switch (this) {
        Success() => null,
        Error(:final failure) => failure,
      };

  /// Gets the success value or throws if this is a failure
  T get valueOrThrow => switch (this) {
        Success(:final value) => value,
        Error(:final failure) => throw Exception(failure.message),
      };

  /// Transforms the success value using the given function
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success(:final value) => Result.success(transform(value)),
        Error(:final failure) => Result.failure(failure),
      };

  /// Transforms the success value using an async function
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) transform) async =>
      switch (this) {
        Success(:final value) => Result.success(await transform(value)),
        Error(:final failure) => Result.failure(failure),
      };

  /// Chains another result-returning operation
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
        Success(:final value) => transform(value),
        Error(:final failure) => Result.failure(failure),
      };

  /// Chains another async result-returning operation
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T value) transform,
  ) async =>
      switch (this) {
        Success(:final value) => await transform(value),
        Error(:final failure) => Result.failure(failure),
      };

  /// Executes an action based on success or failure
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Error(:final failure) => onFailure(failure),
      };

  /// Gets the value or a default if failure
  T getOrElse(T Function() defaultValue) => switch (this) {
        Success(:final value) => value,
        Error() => defaultValue(),
      };

  /// Gets the value or the provided default
  T getOrDefault(T defaultValue) => switch (this) {
        Success(:final value) => value,
        Error() => defaultValue,
      };

  /// Executes a side effect on success
  Result<T> onSuccess(void Function(T value) action) {
    if (this case Success(:final value)) {
      action(value);
    }
    return this;
  }

  /// Executes a side effect on failure
  Result<T> onFailure(void Function(Failure failure) action) {
    if (this case Error(:final failure)) {
      action(failure);
    }
    return this;
  }
}

/// Success result containing a value
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Error result containing a failure
final class Error<T> extends Result<T> {
  final Failure failure;

  const Error(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Error(${failure.message})';
}

/// Extension to combine multiple results
extension ResultListExtension<T> on List<Result<T>> {
  /// Combines all results into a single result containing a list
  /// Fails if any result is a failure
  Result<List<T>> combine() {
    final values = <T>[];
    for (final result in this) {
      switch (result) {
        case Success(:final value):
          values.add(value);
        case Error(:final failure):
          return Result.failure(failure);
      }
    }
    return Result.success(values);
  }
}

/// Extension for async result operations
extension FutureResultExtension<T> on Future<Result<T>> {
  /// Maps the success value of the future result
  Future<Result<R>> mapSuccess<R>(R Function(T value) transform) async {
    final result = await this;
    return result.map(transform);
  }

  /// Chains another async operation
  Future<Result<R>> thenFlatMap<R>(
    Future<Result<R>> Function(T value) transform,
  ) async {
    final result = await this;
    return result.flatMapAsync(transform);
  }
}
