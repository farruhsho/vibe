/// Application-wide constants for Vibe Music Recommendation App
///
/// This file contains all configuration constants used throughout the application.
/// For production, sensitive values should be loaded from environment variables
/// or secure storage.

class AppConstants {
  AppConstants._();

  // ============== APP INFO ==============
  static const String appName = 'Vibe';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-Powered Music Recommendation System';

  // ============== SPOTIFY API ==============
  /// Spotify Client ID - Safe to include in frontend
  /// Get yours at: https://developer.spotify.com/dashboard
  static const String spotifyClientId = '0c4284170a4f4c68a4834dc317e6bd11';

  /// OAuth Redirect URI - Must match Spotify Dashboard settings
  static const String spotifyRedirectUri = 'vibe://spotify-callback';
  static const String spotifyRedirectUriWeb = 'https://vibe.app/callback';

  /// Required Spotify OAuth Scopes
  /// Documentation: https://developer.spotify.com/documentation/web-api/concepts/scopes
  static const List<String> spotifyScopes = [
    'user-read-private',           // Read user's subscription details
    'user-read-email',             // Read user's email address
    'user-library-read',           // Read user's saved tracks/albums
    'user-library-modify',         // Modify user's library
    'user-top-read',               // Read user's top artists/tracks
    'user-read-recently-played',   // Read user's recently played tracks
    'user-read-playback-state',    // Read user's playback state
    'user-modify-playback-state',  // Control playback on user's devices
    'user-read-currently-playing', // Read currently playing track
    'streaming',                   // Stream content via SDK
    'playlist-read-private',       // Read private playlists
    'playlist-modify-public',      // Create/modify public playlists
    'playlist-modify-private',     // Create/modify private playlists
  ];

  /// Spotify API Base URLs
  static const String spotifyAccountsUrl = 'https://accounts.spotify.com';
  static const String spotifyApiUrl = 'https://api.spotify.com/v1';

  // ============== FIREBASE ==============
  /// Cloud Function URL for secure token exchange
  static const String cloudFunctionBaseUrl =
      'https://us-central1-aimusic-8a2d1.cloudfunctions.net';

  // ============== RECOMMENDATION ALGORITHM ==============
  /// Minimum tracks required for reliable pattern analysis
  static const int minTracksForPattern = 10;

  /// Maximum tracks to analyze for pattern detection
  static const int maxTracksToAnalyze = 100;

  /// Default recommendation limit
  static const int defaultRecommendationLimit = 20;

  /// Feature weights for recommendation scoring
  static const Map<String, double> featureWeights = {
    'energy': 0.25,
    'valence': 0.25,
    'danceability': 0.20,
    'tempo': 0.12,
    'acousticness': 0.08,
    'instrumentalness': 0.05,
    'mood_compatibility': 0.05,
  };

  /// Diversity threshold (0.0-1.0) - tracks more similar than this are filtered
  static const double diversityThreshold = 0.65;

  /// Recent track penalty (reduces score for recently played tracks)
  static const double recentTrackPenalty = 0.5;

  // ============== CACHE SETTINGS ==============
  /// Token cache duration (subtract buffer from actual expiry)
  static const Duration tokenCacheBuffer = Duration(minutes: 5);

  /// Recommendation cache duration
  static const Duration recommendationCacheDuration = Duration(minutes: 10);

  /// Search history limit
  static const int searchHistoryLimit = 50;

  /// Listening history limit
  static const int listeningHistoryLimit = 100;

  /// Mood history limit
  static const int moodHistoryLimit = 30;

  // ============== UI SETTINGS ==============
  /// Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  /// Snackbar durations
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration snackbarShortDuration = Duration(seconds: 1);

  /// Rating dialog delay after track starts playing
  static const Duration ratingDialogDelay = Duration(seconds: 15);

  // ============== AUDIO FEATURE RANGES ==============
  /// Spotify audio feature value ranges for normalization
  static const double minTempo = 50.0;
  static const double maxTempo = 200.0;
  static const double minLoudness = -60.0;
  static const double maxLoudness = 0.0;
}
