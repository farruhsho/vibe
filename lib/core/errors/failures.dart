/// Failure classes for Clean Architecture error handling
///
/// This file defines the failure hierarchy used throughout the application.
/// Failures are value objects that represent what went wrong without
/// throwing exceptions across layer boundaries.

import 'package:equatable/equatable.dart';

/// Base failure class - all failures extend this
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  List<Object?> get props => [message, code];
}

// ============== AUTHENTICATION FAILURES ==============

/// Failure during Spotify OAuth authentication
class SpotifyAuthFailure extends Failure {
  const SpotifyAuthFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory SpotifyAuthFailure.tokenExchange() => const SpotifyAuthFailure(
        message: 'Failed to exchange authorization code for tokens',
        code: 'TOKEN_EXCHANGE_FAILED',
      );

  factory SpotifyAuthFailure.tokenRefresh() => const SpotifyAuthFailure(
        message: 'Failed to refresh access token',
        code: 'TOKEN_REFRESH_FAILED',
      );

  factory SpotifyAuthFailure.invalidState() => const SpotifyAuthFailure(
        message: 'Invalid OAuth state parameter',
        code: 'INVALID_STATE',
      );

  factory SpotifyAuthFailure.userCancelled() => const SpotifyAuthFailure(
        message: 'User cancelled authentication',
        code: 'USER_CANCELLED',
      );

  factory SpotifyAuthFailure.scopesDenied() => const SpotifyAuthFailure(
        message: 'Required permissions were denied',
        code: 'SCOPES_DENIED',
      );
}

/// Failure during Firebase authentication
class FirebaseAuthFailure extends Failure {
  const FirebaseAuthFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory FirebaseAuthFailure.userNotFound() => const FirebaseAuthFailure(
        message: 'No user found with this email',
        code: 'user-not-found',
      );

  factory FirebaseAuthFailure.wrongPassword() => const FirebaseAuthFailure(
        message: 'Incorrect password',
        code: 'wrong-password',
      );

  factory FirebaseAuthFailure.emailAlreadyInUse() => const FirebaseAuthFailure(
        message: 'This email is already registered',
        code: 'email-already-in-use',
      );

  factory FirebaseAuthFailure.weakPassword() => const FirebaseAuthFailure(
        message: 'Password must be at least 6 characters',
        code: 'weak-password',
      );

  factory FirebaseAuthFailure.invalidEmail() => const FirebaseAuthFailure(
        message: 'Invalid email format',
        code: 'invalid-email',
      );

  factory FirebaseAuthFailure.unknown(String message) => FirebaseAuthFailure(
        message: message,
        code: 'unknown',
      );
}

// ============== NETWORK FAILURES ==============

/// Failure due to network issues
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory NetworkFailure.noConnection() => const NetworkFailure(
        message: 'No internet connection',
        code: 'NO_CONNECTION',
      );

  factory NetworkFailure.timeout() => const NetworkFailure(
        message: 'Request timed out',
        code: 'TIMEOUT',
      );

  factory NetworkFailure.serverError(int statusCode) => NetworkFailure(
        message: 'Server error ($statusCode)',
        code: 'SERVER_ERROR_$statusCode',
      );

  factory NetworkFailure.rateLimited() => const NetworkFailure(
        message: 'Too many requests. Please wait a moment.',
        code: 'RATE_LIMITED',
      );
}

// ============== SPOTIFY API FAILURES ==============

/// Failure from Spotify API calls
class SpotifyApiFailure extends Failure {
  final int? statusCode;

  const SpotifyApiFailure({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });

  factory SpotifyApiFailure.unauthorized() => const SpotifyApiFailure(
        message: 'Spotify session expired. Please reconnect.',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );

  factory SpotifyApiFailure.forbidden() => const SpotifyApiFailure(
        message: 'Access denied to Spotify resource',
        code: 'FORBIDDEN',
        statusCode: 403,
      );

  factory SpotifyApiFailure.notFound() => const SpotifyApiFailure(
        message: 'Track or resource not found',
        code: 'NOT_FOUND',
        statusCode: 404,
      );

  factory SpotifyApiFailure.badRequest(String details) => SpotifyApiFailure(
        message: 'Invalid request: $details',
        code: 'BAD_REQUEST',
        statusCode: 400,
      );

  factory SpotifyApiFailure.noPreviewAvailable() => const SpotifyApiFailure(
        message: 'Preview not available for this track',
        code: 'NO_PREVIEW',
      );

  factory SpotifyApiFailure.premiumRequired() => const SpotifyApiFailure(
        message: 'Spotify Premium required for this feature',
        code: 'PREMIUM_REQUIRED',
      );

  @override
  List<Object?> get props => [message, code, statusCode];
}

// ============== PLAYBACK FAILURES ==============

/// Failure during audio playback
class PlaybackFailure extends Failure {
  const PlaybackFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory PlaybackFailure.noActiveDevice() => const PlaybackFailure(
        message: 'No active playback device found',
        code: 'NO_ACTIVE_DEVICE',
      );

  factory PlaybackFailure.loadFailed() => const PlaybackFailure(
        message: 'Failed to load audio',
        code: 'LOAD_FAILED',
      );

  factory PlaybackFailure.playFailed() => const PlaybackFailure(
        message: 'Failed to start playback',
        code: 'PLAY_FAILED',
      );

  factory PlaybackFailure.sdkNotInitialized() => const PlaybackFailure(
        message: 'Spotify SDK not initialized',
        code: 'SDK_NOT_INITIALIZED',
      );
}

// ============== CACHE/STORAGE FAILURES ==============

/// Failure with local cache or storage
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory CacheFailure.notFound() => const CacheFailure(
        message: 'Data not found in cache',
        code: 'CACHE_NOT_FOUND',
      );

  factory CacheFailure.expired() => const CacheFailure(
        message: 'Cached data has expired',
        code: 'CACHE_EXPIRED',
      );

  factory CacheFailure.saveFailed() => const CacheFailure(
        message: 'Failed to save data to cache',
        code: 'CACHE_SAVE_FAILED',
      );
}

// ============== RECOMMENDATION FAILURES ==============

/// Failure in recommendation algorithm
class RecommendationFailure extends Failure {
  const RecommendationFailure({
    required super.message,
    super.code,
    super.originalError,
  });

  factory RecommendationFailure.insufficientData() =>
      const RecommendationFailure(
        message: 'Not enough listening history for personalized recommendations',
        code: 'INSUFFICIENT_DATA',
      );

  factory RecommendationFailure.algorithmFailed() =>
      const RecommendationFailure(
        message: 'Failed to generate recommendations',
        code: 'ALGORITHM_FAILED',
      );

  factory RecommendationFailure.noTracksFound() => const RecommendationFailure(
        message: 'No matching tracks found for this mood',
        code: 'NO_TRACKS_FOUND',
      );
}
