/// Result type for functional error handling
///
/// This provides an Either-like type for handling success and failure cases
/// without throwing exceptions across layer boundaries.

/// Sealed class representing either a success or failure result
/// T = Success value type, E = Error/Failure type
sealed class Result<T, E> {
  const Result();

  /// Creates a success result with the given value
  const factory Result.success(T value) = Success<T, E>;

  /// Creates an error result with the given error
  const factory Result.error(E error) = Error<T, E>;

  /// Returns true if this is a success result
  bool get isSuccess => this is Success<T, E>;

  /// Returns true if this is an error result
  bool get isError => this is Error<T, E>;

  /// Gets the success value or null if this is an error
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Error() => null,
      };

  /// Gets the error or null if this is a success
  E? get errorOrNull => switch (this) {
        Success() => null,
        Error(:final error) => error,
      };

  /// Gets the success value or throws if this is an error
  T get valueOrThrow => switch (this) {
        Success(:final value) => value,
        Error(:final error) => throw Exception(error.toString()),
      };

  /// Transforms the success value using the given function
  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
        Success(:final value) => Result.success(transform(value)),
        Error(:final error) => Result.error(error),
      };

  /// Transforms the success value using an async function
  Future<Result<R, E>> mapAsync<R>(Future<R> Function(T value) transform) async =>
      switch (this) {
        Success(:final value) => Result.success(await transform(value)),
        Error(:final error) => Result.error(error),
      };

  /// Chains another result-returning operation
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) transform) => switch (this) {
        Success(:final value) => transform(value),
        Error(:final error) => Result.error(error),
      };

  /// Chains another async result-returning operation
  Future<Result<R, E>> flatMapAsync<R>(
    Future<Result<R, E>> Function(T value) transform,
  ) async =>
      switch (this) {
        Success(:final value) => await transform(value),
        Error(:final error) => Result.error(error),
      };

  /// Executes an action based on success or error
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onError,
  }) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Error(:final error) => onError(error),
      };

  /// Gets the value or a default if error
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
  Result<T, E> onSuccess(void Function(T value) action) {
    if (this case Success(:final value)) {
      action(value);
    }
    return this;
  }

  /// Executes a side effect on error
  Result<T, E> onError(void Function(E error) action) {
    if (this case Error(:final error)) {
      action(error);
    }
    return this;
  }
}

/// Success result containing a value
final class Success<T, E> extends Result<T, E> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, E> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Error result containing an error
final class Error<T, E> extends Result<T, E> {
  final E error;

  const Error(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T, E> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Error($error)';
}

/// Extension to combine multiple results
extension ResultListExtension<T, E> on List<Result<T, E>> {
  /// Combines all results into a single result containing a list
  /// Fails if any result is an error
  Result<List<T>, E> combine() {
    final values = <T>[];
    for (final result in this) {
      switch (result) {
        case Success(:final value):
          values.add(value);
        case Error(:final error):
          return Result.error(error);
      }
    }
    return Result.success(values);
  }
}

/// Extension for async result operations
extension FutureResultExtension<T, E> on Future<Result<T, E>> {
  /// Maps the success value of the future result
  Future<Result<R, E>> mapSuccess<R>(R Function(T value) transform) async {
    final result = await this;
    return result.map(transform);
  }

  /// Chains another async operation
  Future<Result<R, E>> thenFlatMap<R>(
    Future<Result<R, E>> Function(T value) transform,
  ) async {
    final result = await this;
    return result.flatMapAsync(transform);
  }
}
