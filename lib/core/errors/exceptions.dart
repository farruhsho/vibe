/// Exception classes for the data layer
///
/// Exceptions are thrown in the data layer and caught by repositories,
/// which then convert them to Failures for the domain layer.

/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

// ============== NETWORK EXCEPTIONS ==============

class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });

  factory NetworkException.noConnection() => const NetworkException(
        message: 'No internet connection',
        code: 'NO_CONNECTION',
      );

  factory NetworkException.timeout() => const NetworkException(
        message: 'Request timed out',
        code: 'TIMEOUT',
      );

  factory NetworkException.fromStatusCode(int statusCode, [String? body]) {
    switch (statusCode) {
      case 400:
        return NetworkException(
          message: body ?? 'Bad request',
          code: 'BAD_REQUEST',
          statusCode: statusCode,
        );
      case 401:
        return NetworkException(
          message: 'Unauthorized',
          code: 'UNAUTHORIZED',
          statusCode: statusCode,
        );
      case 403:
        return NetworkException(
          message: 'Forbidden',
          code: 'FORBIDDEN',
          statusCode: statusCode,
        );
      case 404:
        return NetworkException(
          message: 'Not found',
          code: 'NOT_FOUND',
          statusCode: statusCode,
        );
      case 429:
        return NetworkException(
          message: 'Rate limited',
          code: 'RATE_LIMITED',
          statusCode: statusCode,
        );
      default:
        return NetworkException(
          message: 'Server error',
          code: 'SERVER_ERROR',
          statusCode: statusCode,
        );
    }
  }
}

// ============== AUTH EXCEPTIONS ==============

class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
  });

  factory AuthException.tokenExpired() => const AuthException(
        message: 'Token has expired',
        code: 'TOKEN_EXPIRED',
      );

  factory AuthException.invalidToken() => const AuthException(
        message: 'Invalid token',
        code: 'INVALID_TOKEN',
      );

  factory AuthException.noToken() => const AuthException(
        message: 'No authentication token found',
        code: 'NO_TOKEN',
      );

  factory AuthException.refreshFailed() => const AuthException(
        message: 'Failed to refresh token',
        code: 'REFRESH_FAILED',
      );
}

// ============== CACHE EXCEPTIONS ==============

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalError,
  });

  factory CacheException.notFound() => const CacheException(
        message: 'Item not found in cache',
        code: 'NOT_FOUND',
      );

  factory CacheException.expired() => const CacheException(
        message: 'Cache expired',
        code: 'EXPIRED',
      );

  factory CacheException.saveFailed(dynamic error) => CacheException(
        message: 'Failed to save to cache',
        code: 'SAVE_FAILED',
        originalError: error,
      );
}

// ============== SPOTIFY EXCEPTIONS ==============

class SpotifyException extends AppException {
  final int? statusCode;

  const SpotifyException({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });

  factory SpotifyException.apiError(int statusCode, String message) =>
      SpotifyException(
        message: message,
        code: 'API_ERROR',
        statusCode: statusCode,
      );

  factory SpotifyException.noPreview() => const SpotifyException(
        message: 'No preview URL available',
        code: 'NO_PREVIEW',
      );

  factory SpotifyException.sdkError(String message) => SpotifyException(
        message: message,
        code: 'SDK_ERROR',
      );
}

// ============== PLAYBACK EXCEPTIONS ==============

class PlaybackException extends AppException {
  const PlaybackException({
    required super.message,
    super.code,
    super.originalError,
  });

  factory PlaybackException.loadFailed(dynamic error) => PlaybackException(
        message: 'Failed to load audio',
        code: 'LOAD_FAILED',
        originalError: error,
      );

  factory PlaybackException.playFailed(dynamic error) => PlaybackException(
        message: 'Failed to play audio',
        code: 'PLAY_FAILED',
        originalError: error,
      );
}
