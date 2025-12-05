/// Authentication Repository Interface
///
/// Defines the contract for authentication operations.
/// The implementation is in the data layer.

import '../entities/user.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';

/// User entity for domain layer
class User {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isSpotifyConnected;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isSpotifyConnected = false,
    this.createdAt,
    this.lastLoginAt,
  });

  String get displayNameOrEmail => displayName ?? email ?? 'User';

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isSpotifyConnected,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isSpotifyConnected: isSpotifyConnected ?? this.isSpotifyConnected,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// Authentication repository interface
abstract class AuthRepository {
  /// Get the currently authenticated user
  Future<User?> getCurrentUser();

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Sign in with email and password
  Future<Result<User, Failure>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Create a new account with email and password
  Future<Result<User, Failure>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign out from both Firebase and Spotify
  Future<Result<void, Failure>> signOut();

  /// Send password reset email
  Future<Result<void, Failure>> sendPasswordResetEmail(String email);

  /// Update user profile
  Future<Result<void, Failure>> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Delete user account
  Future<Result<void, Failure>> deleteAccount();

  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Get current user ID (null if not authenticated)
  String? get currentUserId;
}

/// Spotify authentication repository interface
abstract class SpotifyAuthRepository {
  /// Get Spotify authorization URL for OAuth flow
  Future<Uri> getAuthorizationUrl();

  /// Handle OAuth callback and exchange code for tokens
  Future<Result<SpotifyTokens, Failure>> handleCallback({
    required String code,
    required String state,
  });

  /// Refresh access token using refresh token
  Future<Result<SpotifyTokens, Failure>> refreshToken();

  /// Get current tokens (if authenticated)
  Future<SpotifyTokens?> getStoredTokens();

  /// Check if user is connected to Spotify
  Future<bool> isConnected();

  /// Disconnect from Spotify (clear tokens)
  Future<void> disconnect();

  /// Get current access token (refreshes if expired)
  Future<String?> getValidAccessToken();
}

/// Spotify tokens entity
class SpotifyTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final List<String> scopes;

  const SpotifyTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.scopes,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get willExpireSoon =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
}
