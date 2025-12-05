/// Authentication Repository Implementation
///
/// Implements the AuthRepository interface using Firebase Auth
/// and the SpotifyAuthDatasource for OAuth.

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../domain/repositories/auth_repository.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../datasources/remote/spotify_auth_datasource.dart' as datasource;

/// Firebase Auth implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final firebase.FirebaseAuth _firebaseAuth;
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  AuthRepositoryImpl({firebase.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance {
    // Listen to Firebase auth state changes and map to domain User
    _firebaseAuth.authStateChanges().listen((firebaseUser) {
      _authStateController.add(
        firebaseUser != null ? _mapFirebaseUser(firebaseUser) : null,
      );
    });
  }

  User _mapFirebaseUser(firebase.User firebaseUser) {
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime,
      lastLoginAt: firebaseUser.metadata.lastSignInTime,
    );
  }

  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null ? _mapFirebaseUser(firebaseUser) : null;
  }

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  @override
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  @override
  Future<Result<User, Failure>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return const Result.error(
          FirebaseAuthFailure('Authentication failed'),
        );
      }

      return Result.success(_mapFirebaseUser(credential.user!));
    } on firebase.FirebaseAuthException catch (e) {
      return Result.error(
        FirebaseAuthFailure(_mapFirebaseAuthError(e.code)),
      );
    } catch (e) {
      return Result.error(
        FirebaseAuthFailure('An unexpected error occurred'),
      );
    }
  }

  @override
  Future<Result<User, Failure>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return const Result.error(
          FirebaseAuthFailure('Account creation failed'),
        );
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      // Get updated user
      final updatedUser = _firebaseAuth.currentUser;
      return Result.success(_mapFirebaseUser(updatedUser ?? credential.user!));
    } on firebase.FirebaseAuthException catch (e) {
      return Result.error(
        FirebaseAuthFailure(_mapFirebaseAuthError(e.code)),
      );
    } catch (e) {
      return Result.error(
        FirebaseAuthFailure('An unexpected error occurred'),
      );
    }
  }

  @override
  Future<Result<void, Failure>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Result.success(null);
    } catch (e) {
      return const Result.error(
        FirebaseAuthFailure('Failed to sign out'),
      );
    }
  }

  @override
  Future<Result<void, Failure>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return const Result.success(null);
    } on firebase.FirebaseAuthException catch (e) {
      return Result.error(
        FirebaseAuthFailure(_mapFirebaseAuthError(e.code)),
      );
    } catch (e) {
      return const Result.error(
        FirebaseAuthFailure('Failed to send reset email'),
      );
    }
  }

  @override
  Future<Result<void, Failure>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Result.error(
          FirebaseAuthFailure('Not authenticated'),
        );
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      await user.reload();
      return const Result.success(null);
    } catch (e) {
      return const Result.error(
        FirebaseAuthFailure('Failed to update profile'),
      );
    }
  }

  @override
  Future<Result<void, Failure>> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Result.error(
          FirebaseAuthFailure('Not authenticated'),
        );
      }

      await user.delete();
      return const Result.success(null);
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return const Result.error(
          FirebaseAuthFailure('Please sign in again before deleting your account'),
        );
      }
      return Result.error(
        FirebaseAuthFailure(_mapFirebaseAuthError(e.code)),
      );
    } catch (e) {
      return const Result.error(
        FirebaseAuthFailure('Failed to delete account'),
      );
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Email/password sign in is not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'An error occurred. Please try again';
    }
  }

  void dispose() {
    _authStateController.close();
  }
}

/// Spotify Auth implementation
class SpotifyAuthRepositoryImpl implements SpotifyAuthRepository {
  final datasource.SpotifyAuthDatasource _datasource;

  SpotifyAuthRepositoryImpl({datasource.SpotifyAuthDatasource? ds})
      : _datasource = ds ?? datasource.SpotifyAuthDatasource();

  @override
  Future<Uri> getAuthorizationUrl() async {
    return _datasource.buildAuthorizationUrl();
  }

  @override
  Future<Result<SpotifyTokens, Failure>> handleCallback({
    required String code,
    required String state,
  }) async {
    try {
      final tokens = await _datasource.handleCallback(
        code: code,
        returnedState: state,
      );

      return Result.success(SpotifyTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresAt: tokens.expiresAt,
        scopes: tokens.scopes,
      ));
    } on AuthException catch (e) {
      return Result.error(SpotifyAuthFailure(e.message));
    } catch (e) {
      return Result.error(
        SpotifyAuthFailure('Failed to complete Spotify authorization'),
      );
    }
  }

  @override
  Future<Result<SpotifyTokens, Failure>> refreshToken() async {
    try {
      final tokens = await _datasource.refreshAccessToken();

      return Result.success(SpotifyTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresAt: tokens.expiresAt,
        scopes: tokens.scopes,
      ));
    } on AuthException catch (e) {
      return Result.error(SpotifyAuthFailure(e.message));
    } catch (e) {
      return Result.error(
        SpotifyAuthFailure('Failed to refresh token'),
      );
    }
  }

  @override
  Future<SpotifyTokens?> getStoredTokens() async {
    final tokens = await _datasource.getStoredTokens();
    if (tokens == null) return null;

    return SpotifyTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: tokens.expiresAt,
      scopes: tokens.scopes,
    );
  }

  @override
  Future<bool> isConnected() async {
    return _datasource.isAuthenticated();
  }

  @override
  Future<void> disconnect() async {
    await _datasource.clearTokens();
  }

  @override
  Future<String?> getValidAccessToken() async {
    return _datasource.getValidAccessToken();
  }
}
