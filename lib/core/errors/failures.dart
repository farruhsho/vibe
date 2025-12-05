/// Failure classes for Clean Architecture error handling
///
/// This file defines the failure hierarchy used throughout the application.
/// Failures are value objects that represent what went wrong without
/// throwing exceptions across layer boundaries.

/// Base failure class - all failures extend this
abstract class Failure {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

// ============== AUTHENTICATION FAILURES ==============

/// Failure during Spotify OAuth authentication
class SpotifyAuthFailure extends Failure {
  const SpotifyAuthFailure(String message, {String? code, dynamic originalError})
      : super(message: message, code: code, originalError: originalError);

  factory SpotifyAuthFailure.tokenExchange() => const SpotifyAuthFailure(
        'Failed to exchange authorization code for tokens',
        code: 'TOKEN_EXCHANGE_FAILED',
      );

  factory SpotifyAuthFailure.tokenRefresh() => const SpotifyAuthFailure(
        'Failed to refresh access token',
        code: 'TOKEN_REFRESH_FAILED',
      );

  factory SpotifyAuthFailure.invalidState() => const SpotifyAuthFailure(
        'Invalid OAuth state parameter',
        code: 'INVALID_STATE',
      );

  factory SpotifyAuthFailure.userCancelled() => const SpotifyAuthFailure(
        'User cancelled authentication',
        code: 'USER_CANCELLED',
      );

  factory SpotifyAuthFailure.scopesDenied() => const SpotifyAuthFailure(
        'Required permissions were denied',
        code: 'SCOPES_DENIED',
      );
}

/// Failure during Firebase authentication
class FirebaseAuthFailure extends Failure {
  const FirebaseAuthFailure(String message, {String? code, dynamic originalError})
      : super(message: message, code: code, originalError: originalError);

  factory FirebaseAuthFailure.userNotFound() => const FirebaseAuthFailure(
        'No user found with this email',
        code: 'user-not-found',
      );

  factory FirebaseAuthFailure.wrongPassword() => const FirebaseAuthFailure(
        'Incorrect password',
        code: 'wrong-password',
      );

  factory FirebaseAuthFailure.emailAlreadyInUse() => const FirebaseAuthFailure(
        'This email is already registered',
        code: 'email-already-in-use',
      );

  factory FirebaseAuthFailure.weakPassword() => const FirebaseAuthFailure(
        'Password must be at least 6 characters',
        code: 'weak-password',
      );

  factory FirebaseAuthFailure.invalidEmail() => const FirebaseAuthFailure(
        'Invalid email format',
        code: 'invalid-email',
      );

  factory FirebaseAuthFailure.unknown(String message) => FirebaseAuthFailure(
        message,
        code: 'unknown',
      );
}

// ============== NETWORK FAILURES ==============

/// Failure due to network issues
class NetworkFailure extends Failure {
  const NetworkFailure(String message, {String? code, dynamic originalError})
      : super(message: message, code: code, originalError: originalError);

  factory NetworkFailure.noConnection() => const NetworkFailure(
        'No internet connection',
        code: 'NO_CONNECTION',
      );

  factory NetworkFailure.timeout() => const NetworkFailure(
        'Request timed out',
        code: 'TIMEOUT',
      );

  factory NetworkFailure.serverError(int statusCode) => NetworkFailure(
        'Server error ($statusCode)',
        code: 'SERVER_ERROR_$statusCode',
      );

  factory NetworkFailure.rateLimited() => const NetworkFailure(
        'Too many requests. Please wait a moment.',
        code: 'RATE_LIMITED',
      );
}

// ============== SPOTIFY API FAILURES ==============

/// Failure from Spotify API calls
class SpotifyApiFailure extends Failure {
  final int? statusCode;

  const SpotifyApiFailure(String message, {String? code, dynamic originalError, this.statusCode})
      : super(message: message, code: code, originalError: originalError);

  factory SpotifyApiFailure.unauthorized() => const SpotifyApiFailure(
        'Spotify session expired. Please reconnect.',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );

  factory SpotifyApiFailure.forbidden() => const SpotifyApiFailure(
        'Access denied to Spotify resource',
        code: 'FORBIDDEN',
        statusCode: 403,
      );

  factory SpotifyApiFailure.notFound() => const SpotifyApiFailure(
        'Track or resource not found',
        code: 'NOT_FOUND',
        statusCode: 404,
      );

  factory SpotifyApiFailure.badRequest(String details) => SpotifyApiFailure(
        'Invalid request: $details',
        code: 'BAD_REQUEST',
        statusCode: 400,
      );

  factory SpotifyApiFailure.noPreviewAvailable() => const SpotifyApiFailure(
        'Preview not available for this track',
        code: 'NO_PREVIEW',
      );

  factory SpotifyApiFailure.premiumRequired() => const SpotifyApiFailure(
        'Spotify Premium required for this feature',
        code: 'PREMIUM_REQUIRED',
      );
}

// ============== PLAYBACK FAILURES ==============

/// Failure during audio playback
class PlaybackFailure extends Failure {
  const PlaybackFailure(String message, {String? code, dynamic originalError})
      : super(message: message, code: code, originalError: originalError);

  factory PlaybackFailure.noActiveDevice() => const PlaybackFailure(
        'No active playback device found',
        code: 'NO_ACTIVE_DEVICE',
      );

  factory PlaybackFailure.loadFailed() => const PlaybackFailure(
        'Failed to load audio',
        code: 'LOAD_FAILED',
      );

  factory PlaybackFailure.playFailed() => const PlaybackFailure(
        'Failed to start playback',
        code: 'PLAY_FAILED',
      );

  factory PlaybackFailure.sdkNotInitialized() => const PlaybackFailure(
        'Spotify SDK not initialized',
        code: 'SDK_NOT_INITIALIZED',
      );
}

// ============== CACHE/STORAGE FAILURES ==============

/// Failure with local cache or storage
class CacheFailure extends Failure {
  const CacheFailure(String message, {String? code, dynamic originalError})
      : super(message: message, code: code, originalError: originalError);

  factory CacheFailure.notFound() => const CacheFailure(
        'Data not found in cache',
        code: 'CACHE_NOT_FOUND',
      );

  factory CacheFailure.expired() => const CacheFailure(
        'Cached data has expired',
        code: 'CACHE_EXPIRED',
      );

  factory CacheFailure.saveFailed() => const CacheFailure(
        'Failed to save data to cache',
        code: 'CACHE_SAVE_FAILED',
      );
}

// ============== RECOMMENDATION FAILURES ==============

/// Failure in recommendation algorithm
class RecommendationFailure extends Failure {
  const RecommendationFailure(String message, {String? code, dynamic originalError})
      : super(message: message, code: code, originalError: originalError);

  factory RecommendationFailure.insufficientData() =>
      const RecommendationFailure(
        'Not enough listening history for personalized recommendations',
        code: 'INSUFFICIENT_DATA',
      );

  factory RecommendationFailure.algorithmFailed() =>
      const RecommendationFailure(
        'Failed to generate recommendations',
        code: 'ALGORITHM_FAILED',
      );

  factory RecommendationFailure.noTracksFound() => const RecommendationFailure(
        'No matching tracks found for this mood',
        code: 'NO_TRACKS_FOUND',
      );
}

// ============== UNKNOWN FAILURES ==============

/// Generic failure for unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure(String message, {String? code, dynamic originalError})
      : super(message: message, code: code ?? 'UNKNOWN', originalError: originalError);
}
