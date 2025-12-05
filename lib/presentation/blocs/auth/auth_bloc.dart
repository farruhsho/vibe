/// Authentication BLoC
///
/// Manages authentication state for both Firebase and Spotify.
/// Handles login, logout, and OAuth callback processing.

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/datasources/remote/spotify_auth_datasource.dart';
import '../../../core/utils/deep_link_handler.dart';

// ============== EVENTS ==============

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check initial authentication state
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

/// Sign in with email and password
class SignInWithEmail extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmail({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Create account with email and password
class SignUpWithEmail extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const SignUpWithEmail({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Sign out from both Firebase and Spotify
class SignOut extends AuthEvent {
  const SignOut();
}

/// Start Spotify OAuth flow
class ConnectSpotify extends AuthEvent {
  const ConnectSpotify();
}

/// Handle OAuth callback
class HandleSpotifyCallback extends AuthEvent {
  final String code;
  final String state;

  const HandleSpotifyCallback({required this.code, required this.state});

  @override
  List<Object?> get props => [code, state];
}

/// Disconnect Spotify account
class DisconnectSpotify extends AuthEvent {
  const DisconnectSpotify();
}

/// Clear error state
class ClearAuthError extends AuthEvent {
  const ClearAuthError();
}

// ============== STATE ==============

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? firebaseUser;
  final bool isSpotifyConnected;
  final SpotifyTokens? spotifyTokens;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.firebaseUser,
    this.isSpotifyConnected = false,
    this.spotifyTokens,
    this.errorMessage,
    this.isLoading = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get hasError => errorMessage != null;
  String get displayName => firebaseUser?.displayName ?? firebaseUser?.email ?? 'User';
  String? get email => firebaseUser?.email;
  String? get userId => firebaseUser?.uid;

  AuthState copyWith({
    AuthStatus? status,
    User? firebaseUser,
    bool? isSpotifyConnected,
    SpotifyTokens? spotifyTokens,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      isSpotifyConnected: isSpotifyConnected ?? this.isSpotifyConnected,
      spotifyTokens: spotifyTokens ?? this.spotifyTokens,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        status,
        firebaseUser?.uid,
        isSpotifyConnected,
        spotifyTokens?.accessToken,
        errorMessage,
        isLoading,
      ];
}

// ============== BLOC ==============

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth;
  final SpotifyAuthDatasource _spotifyAuth;
  final DeepLinkHandler _deepLinkHandler;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<OAuthCallbackData>? _oauthCallbackSubscription;

  AuthBloc({
    FirebaseAuth? firebaseAuth,
    SpotifyAuthDatasource? spotifyAuth,
    DeepLinkHandler? deepLinkHandler,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _spotifyAuth = spotifyAuth ?? SpotifyAuthDatasource(),
        _deepLinkHandler = deepLinkHandler ?? DeepLinkService.instance,
        super(const AuthState()) {
    // Register event handlers
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInWithEmail>(_onSignInWithEmail);
    on<SignUpWithEmail>(_onSignUpWithEmail);
    on<SignOut>(_onSignOut);
    on<ConnectSpotify>(_onConnectSpotify);
    on<HandleSpotifyCallback>(_onHandleSpotifyCallback);
    on<DisconnectSpotify>(_onDisconnectSpotify);
    on<ClearAuthError>(_onClearError);

    // Listen to Firebase auth state changes
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
      add(const CheckAuthStatus());
    });

    // Listen for OAuth callbacks
    _oauthCallbackSubscription = _deepLinkHandler.oauthCallbacks.listen(
      (callbackData) {
        if (callbackData.isSuccess) {
          add(HandleSpotifyCallback(
            code: callbackData.code!,
            state: callbackData.state!,
          ));
        } else if (callbackData.isError) {
          debugPrint('OAuth error: ${callbackData.error}');
        }
      },
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final user = _firebaseAuth.currentUser;

    if (user != null) {
      // Check Spotify connection
      final isSpotifyConnected = await _spotifyAuth.isAuthenticated();
      final spotifyTokens = await _spotifyAuth.getStoredTokens();

      emit(AuthState(
        status: AuthStatus.authenticated,
        firebaseUser: user,
        isSpotifyConnected: isSpotifyConnected,
        spotifyTokens: spotifyTokens,
      ));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onSignInWithEmail(
    SignInWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      emit(AuthState(
        status: AuthStatus.authenticated,
        firebaseUser: credential.user,
      ));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e.code),
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'An error occurred. Please try again.',
      ));
    }
  }

  Future<void> _onSignUpWithEmail(
    SignUpWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      // Update display name if provided
      if (event.displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(event.displayName);
      }

      emit(AuthState(
        status: AuthStatus.authenticated,
        firebaseUser: credential.user,
      ));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseError(e.code),
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'An error occurred. Please try again.',
      ));
    }
  }

  Future<void> _onSignOut(SignOut event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      await _spotifyAuth.clearTokens();
      await _firebaseAuth.signOut();

      emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to sign out',
      ));
    }
  }

  Future<void> _onConnectSpotify(
    ConnectSpotify event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final authUrl = await _spotifyAuth.buildAuthorizationUrl();
      debugPrint('Opening Spotify auth URL: $authUrl');

      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Could not open Spotify authorization',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to start Spotify authorization',
      ));
    }
  }

  Future<void> _onHandleSpotifyCallback(
    HandleSpotifyCallback event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final tokens = await _spotifyAuth.handleCallback(
        code: event.code,
        returnedState: event.state,
      );

      emit(state.copyWith(
        isLoading: false,
        isSpotifyConnected: true,
        spotifyTokens: tokens,
      ));
    } catch (e) {
      debugPrint('Spotify callback error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to connect Spotify account',
      ));
    }
  }

  Future<void> _onDisconnectSpotify(
    DisconnectSpotify event,
    Emitter<AuthState> emit,
  ) async {
    await _spotifyAuth.clearTokens();
    emit(state.copyWith(
      isSpotifyConnected: false,
      spotifyTokens: null,
    ));
  }

  void _onClearError(ClearAuthError event, Emitter<AuthState> emit) {
    emit(state.copyWith(errorMessage: null));
  }

  String _mapFirebaseError(String code) {
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
      default:
        return 'An error occurred. Please try again';
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    await _oauthCallbackSubscription?.cancel();
    return super.close();
  }
}
