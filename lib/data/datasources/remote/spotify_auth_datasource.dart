/// Spotify OAuth 2.0 Authentication with PKCE
///
/// Implements the Authorization Code Flow with PKCE (Proof Key for Code Exchange)
/// which is the recommended OAuth flow for mobile applications.
///
/// PKCE Flow:
/// 1. Generate code_verifier (random string)
/// 2. Create code_challenge (SHA256 hash of verifier, base64url encoded)
/// 3. Open Spotify authorization URL with code_challenge
/// 4. Receive authorization code via deep link callback
/// 5. Exchange code for tokens using code_verifier
/// 6. Store tokens securely
///
/// Reference: https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';

/// Spotify tokens response
class SpotifyTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final List<String> scopes;

  SpotifyTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.scopes,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get willExpireSoon =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  factory SpotifyTokens.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'] as int;
    return SpotifyTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      scopes: (json['scope'] as String?)?.split(' ') ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt.toIso8601String(),
        'scopes': scopes.join(' '),
      };
}

/// PKCE helper class for generating code verifier and challenge
class PKCEHelper {
  /// Generate a random code verifier (43-128 characters)
  static String generateCodeVerifier() {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Generate code challenge from verifier using SHA256
  static String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url
        .encode(digest.bytes)
        .replaceAll('=', '') // Remove padding
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  /// Generate random state parameter for CSRF protection
  static String generateState() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }
}

/// Secure storage keys
class SpotifyStorageKeys {
  static const accessToken = 'spotify_access_token';
  static const refreshToken = 'spotify_refresh_token';
  static const expiresAt = 'spotify_expires_at';
  static const scopes = 'spotify_scopes';
  static const codeVerifier = 'spotify_code_verifier';
  static const state = 'spotify_oauth_state';
}

/// Spotify Authentication Data Source
class SpotifyAuthDatasource {
  final FlutterSecureStorage _secureStorage;
  final http.Client _httpClient;

  SpotifyAuthDatasource({
    FlutterSecureStorage? secureStorage,
    http.Client? httpClient,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? http.Client();

  /// Build the Spotify authorization URL for OAuth
  Future<Uri> buildAuthorizationUrl() async {
    // Generate PKCE parameters
    final codeVerifier = PKCEHelper.generateCodeVerifier();
    final codeChallenge = PKCEHelper.generateCodeChallenge(codeVerifier);
    final state = PKCEHelper.generateState();

    // Store verifier and state for later verification
    await _secureStorage.write(
        key: SpotifyStorageKeys.codeVerifier, value: codeVerifier);
    await _secureStorage.write(key: SpotifyStorageKeys.state, value: state);

    // Build authorization URL
    return Uri.https(
      'accounts.spotify.com',
      '/authorize',
      {
        'client_id': AppConstants.spotifyClientId,
        'response_type': 'code',
        'redirect_uri': AppConstants.spotifyRedirectUri,
        'scope': AppConstants.spotifyScopes.join(' '),
        'state': state,
        'code_challenge_method': 'S256',
        'code_challenge': codeChallenge,
        'show_dialog': 'true',
      },
    );
  }

  /// Handle the OAuth callback and exchange code for tokens
  Future<SpotifyTokens> handleCallback({
    required String code,
    required String returnedState,
  }) async {
    // Verify state to prevent CSRF
    final savedState =
        await _secureStorage.read(key: SpotifyStorageKeys.state);
    if (savedState != returnedState) {
      throw AuthException(
        message: 'Invalid state parameter - possible CSRF attack',
        code: 'INVALID_STATE',
      );
    }

    // Get the code verifier
    final codeVerifier =
        await _secureStorage.read(key: SpotifyStorageKeys.codeVerifier);
    if (codeVerifier == null) {
      throw AuthException(
        message: 'Code verifier not found - authorization session expired',
        code: 'NO_CODE_VERIFIER',
      );
    }

    // Exchange code for tokens
    final tokens = await _exchangeCodeForTokens(code, codeVerifier);

    // Store tokens securely
    await _storeTokens(tokens);

    // Clean up PKCE state
    await _secureStorage.delete(key: SpotifyStorageKeys.codeVerifier);
    await _secureStorage.delete(key: SpotifyStorageKeys.state);

    return tokens;
  }

  /// Exchange authorization code for tokens
  Future<SpotifyTokens> _exchangeCodeForTokens(
    String code,
    String codeVerifier,
  ) async {
    final response = await _httpClient.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': AppConstants.spotifyRedirectUri,
        'client_id': AppConstants.spotifyClientId,
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode != 200) {
      debugPrint('Token exchange failed: ${response.body}');
      throw AuthException(
        message: 'Failed to exchange authorization code',
        code: 'TOKEN_EXCHANGE_FAILED',
        originalError: response.body,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return SpotifyTokens.fromJson(json);
  }

  /// Refresh the access token using refresh token
  Future<SpotifyTokens> refreshAccessToken() async {
    final refreshToken =
        await _secureStorage.read(key: SpotifyStorageKeys.refreshToken);

    if (refreshToken == null || refreshToken.isEmpty) {
      throw AuthException.noToken();
    }

    final response = await _httpClient.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': AppConstants.spotifyClientId,
      },
    );

    if (response.statusCode != 200) {
      debugPrint('Token refresh failed: ${response.body}');
      await clearTokens(); // Clear invalid tokens
      throw AuthException.refreshFailed();
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Spotify may or may not return a new refresh token
    if (!json.containsKey('refresh_token')) {
      json['refresh_token'] = refreshToken;
    }

    final tokens = SpotifyTokens.fromJson(json);
    await _storeTokens(tokens);

    return tokens;
  }

  /// Get stored tokens
  Future<SpotifyTokens?> getStoredTokens() async {
    final accessToken =
        await _secureStorage.read(key: SpotifyStorageKeys.accessToken);
    final refreshToken =
        await _secureStorage.read(key: SpotifyStorageKeys.refreshToken);
    final expiresAtStr =
        await _secureStorage.read(key: SpotifyStorageKeys.expiresAt);
    final scopesStr =
        await _secureStorage.read(key: SpotifyStorageKeys.scopes);

    if (accessToken == null || expiresAtStr == null) {
      return null;
    }

    return SpotifyTokens(
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
      expiresAt: DateTime.parse(expiresAtStr),
      scopes: scopesStr?.split(' ') ?? [],
    );
  }

  /// Get valid access token (refreshing if needed)
  Future<String?> getValidAccessToken() async {
    final tokens = await getStoredTokens();

    if (tokens == null) {
      return null;
    }

    // If token is expired or about to expire, refresh it
    if (tokens.willExpireSoon) {
      try {
        final newTokens = await refreshAccessToken();
        return newTokens.accessToken;
      } catch (e) {
        debugPrint('Failed to refresh token: $e');
        return null;
      }
    }

    return tokens.accessToken;
  }

  /// Store tokens securely
  Future<void> _storeTokens(SpotifyTokens tokens) async {
    await _secureStorage.write(
      key: SpotifyStorageKeys.accessToken,
      value: tokens.accessToken,
    );
    await _secureStorage.write(
      key: SpotifyStorageKeys.refreshToken,
      value: tokens.refreshToken,
    );
    await _secureStorage.write(
      key: SpotifyStorageKeys.expiresAt,
      value: tokens.expiresAt.toIso8601String(),
    );
    await _secureStorage.write(
      key: SpotifyStorageKeys.scopes,
      value: tokens.scopes.join(' '),
    );
  }

  /// Clear all stored tokens (logout)
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: SpotifyStorageKeys.accessToken);
    await _secureStorage.delete(key: SpotifyStorageKeys.refreshToken);
    await _secureStorage.delete(key: SpotifyStorageKeys.expiresAt);
    await _secureStorage.delete(key: SpotifyStorageKeys.scopes);
  }

  /// Check if user is authenticated with Spotify
  Future<bool> isAuthenticated() async {
    final token = await getValidAccessToken();
    return token != null;
  }
}

/// Client Credentials flow for non-user-specific API calls
class SpotifyClientCredentialsDatasource {
  final http.Client _httpClient;

  String? _cachedToken;
  DateTime? _tokenExpiry;

  SpotifyClientCredentialsDatasource({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Get client credentials access token
  /// Note: This requires client_secret which should ideally be in a Cloud Function
  Future<String> getAccessToken(String clientSecret) async {
    // Check cache
    if (_cachedToken != null && _tokenExpiry != null) {
      if (DateTime.now().isBefore(_tokenExpiry!)) {
        return _cachedToken!;
      }
    }

    final credentials = base64Encode(
      utf8.encode('${AppConstants.spotifyClientId}:$clientSecret'),
    );

    final response = await _httpClient.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode != 200) {
      throw AuthException(
        message: 'Failed to get client credentials token',
        code: 'CLIENT_CREDENTIALS_FAILED',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _cachedToken = json['access_token'] as String;
    final expiresIn = json['expires_in'] as int;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));

    return _cachedToken!;
  }
}
