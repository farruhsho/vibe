/// Deep Link Handler for OAuth Callbacks
///
/// Handles incoming deep links for Spotify OAuth callback
/// and other deep linking needs.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';

/// Parsed OAuth callback data
class OAuthCallbackData {
  final String? code;
  final String? state;
  final String? error;
  final String? errorDescription;

  OAuthCallbackData({
    this.code,
    this.state,
    this.error,
    this.errorDescription,
  });

  bool get isSuccess => code != null && error == null;
  bool get isError => error != null;

  @override
  String toString() =>
      'OAuthCallbackData(code: ${code != null ? "***" : null}, '
      'state: $state, error: $error)';
}

/// Deep link handler for the app
class DeepLinkHandler {
  final AppLinks _appLinks;
  final StreamController<OAuthCallbackData> _oauthCallbackController =
      StreamController<OAuthCallbackData>.broadcast();

  DeepLinkHandler({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  /// Stream of OAuth callback data
  Stream<OAuthCallbackData> get oauthCallbacks => _oauthCallbackController.stream;

  /// Initialize deep link handling
  Future<void> initialize() async {
    // Handle link when app is started from link
    try {
      final initialLink = await _appLinks.getInitialLinkString();
      if (initialLink != null) {
        _handleDeepLink(Uri.parse(initialLink));
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to get initial link: $e');
    }

    // Handle links when app is running
    _appLinks.stringLinkStream.listen(
      (String? link) {
        if (link != null) {
          _handleDeepLink(Uri.parse(link));
        }
      },
      onError: (error) {
        debugPrint('Deep link error: $error');
      },
    );
  }

  /// Handle incoming deep link
  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');

    // Check if this is a Spotify OAuth callback
    if (_isSpotifyCallback(uri)) {
      _handleSpotifyCallback(uri);
    }
    // Add other deep link handlers here as needed
  }

  /// Check if URI is a Spotify OAuth callback
  bool _isSpotifyCallback(Uri uri) {
    return uri.scheme == 'vibe' && uri.host == 'spotify-callback';
  }

  /// Handle Spotify OAuth callback
  void _handleSpotifyCallback(Uri uri) {
    final params = uri.queryParameters;

    final callbackData = OAuthCallbackData(
      code: params['code'],
      state: params['state'],
      error: params['error'],
      errorDescription: params['error_description'],
    );

    debugPrint('OAuth callback received: $callbackData');
    _oauthCallbackController.add(callbackData);
  }

  /// Dispose of resources
  void dispose() {
    _oauthCallbackController.close();
  }
}

/// Singleton instance for global access
class DeepLinkService {
  static DeepLinkHandler? _instance;

  static DeepLinkHandler get instance {
    _instance ??= DeepLinkHandler();
    return _instance!;
  }

  static Future<void> initialize() async {
    await instance.initialize();
  }

  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}
