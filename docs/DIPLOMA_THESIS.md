# Vibe: AI-Powered Music Recommendation System

## Diploma Thesis Technical Documentation

**Author:** Diploma Thesis Project 2025
**Technology Stack:** Flutter, Firebase, Spotify API
**Architecture:** Clean Architecture with BLoC Pattern

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [System Architecture](#2-system-architecture)
3. [Authentication System](#3-authentication-system)
4. [Machine Learning Recommendation Algorithm](#4-machine-learning-recommendation-algorithm)
5. [Data Layer Implementation](#5-data-layer-implementation)
6. [User Interface Design](#6-user-interface-design)
7. [Security Considerations](#7-security-considerations)
8. [Performance Optimization](#8-performance-optimization)
9. [Testing Strategy](#9-testing-strategy)
10. [Conclusion](#10-conclusion)

---

## 1. Introduction

### 1.1 Problem Statement

Modern music streaming services offer millions of tracks, creating a paradox of choice that can overwhelm users. Traditional recommendation systems often fail to capture the nuanced relationship between a user's emotional state and their music preferences. This thesis presents **Vibe**, an AI-powered music recommendation system that combines Spotify's audio analysis capabilities with custom machine learning algorithms to deliver personalized, mood-based music suggestions.

### 1.2 Objectives

1. Develop a cross-platform mobile application using Flutter
2. Implement secure OAuth 2.0 authentication with PKCE for Spotify integration
3. Create a scientifically-grounded recommendation algorithm based on audio features
4. Design an intuitive user interface for mood-based music discovery
5. Ensure scalability and maintainability through Clean Architecture

### 1.3 Technology Justification

| Technology | Justification |
|------------|---------------|
| **Flutter** | Cross-platform development reduces time-to-market by 40%, single codebase for iOS and Android |
| **Firebase** | Real-time database, authentication services, and analytics with minimal server management |
| **Spotify API** | Access to 100M+ tracks, comprehensive audio feature analysis, industry-standard OAuth 2.0 |
| **BLoC Pattern** | Predictable state management, separation of concerns, testability |

---

## 2. System Architecture

### 2.1 Clean Architecture Overview

The application follows **Clean Architecture** principles, dividing the codebase into three distinct layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Screens   │  │   Widgets   │  │   BLoCs (State)     │  │
│  │  - Home     │  │  - TrackCard│  │  - AuthBloc         │  │
│  │  - Player   │  │  - MiniPlay │  │  - PlayerBloc       │  │
│  │  - Search   │  │  - MoodCard │  │  - RecommendBloc    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Entities   │  │ Repositories│  │     Use Cases       │  │
│  │  - Track    │  │ (Interfaces)│  │  - GetRecommend     │  │
│  │  - AudioFeat│  │  - AuthRepo │  │  - AnalyzePatterns  │  │
│  │  - UserPatt │  │  - MusicRepo│  │  - PlayTrack        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Models    │  │ Data Sources│  │  Repo Implements    │  │
│  │  - TrackMod │  │  - SpotifyAPI│  │  - AuthRepoImpl    │  │
│  │  - AudioMod │  │  - Firebase │  │  - MusicRepoImpl   │  │
│  │  - UserMod  │  │  - Local    │  │  - RecommendImpl   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Dependency Injection

Dependencies are managed using **GetIt** service locator:

```dart
/// Global service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initDependencies() async {
  // External Services
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Data Sources
  sl.registerLazySingleton<SpotifyAuthDatasource>(() => SpotifyAuthDatasource());
  sl.registerLazySingleton<SpotifyApiDatasource>(() => SpotifyApiDatasource(...));

  // BLoCs
  sl.registerLazySingleton<AuthBloc>(() => AuthBloc(...));
  sl.registerLazySingleton<PlayerBloc>(() => PlayerBloc(...));
}
```

### 2.3 Data Flow Diagram

```
┌──────────┐    Events    ┌──────────┐    Call    ┌──────────┐
│   UI     │─────────────>│   BLoC   │──────────>│ UseCase  │
│ (Widget) │              │  (State) │           │          │
└──────────┘              └──────────┘           └──────────┘
     ^                         │                      │
     │                         │                      v
     │    States              │              ┌──────────┐
     └────────────────────────┘              │Repository│
                                             │(Interface)│
                                             └──────────┘
                                                   │
                                                   v
                                             ┌──────────┐
                                             │Data Source│
                                             │(API/DB)   │
                                             └──────────┘
```

---

## 3. Authentication System

### 3.1 Dual Authentication Architecture

Vibe implements a two-tier authentication system:

1. **Firebase Authentication**: User account management (email/password)
2. **Spotify OAuth 2.0 with PKCE**: Music service integration

### 3.2 OAuth 2.0 with PKCE Implementation

**PKCE (Proof Key for Code Exchange)** is crucial for mobile applications as they cannot securely store client secrets.

#### 3.2.1 PKCE Flow Diagram

```
┌────────┐                              ┌─────────────┐
│  App   │                              │   Spotify   │
└────┬───┘                              └──────┬──────┘
     │                                         │
     │  1. Generate code_verifier (random)     │
     │  2. Generate code_challenge (SHA256)    │
     │                                         │
     │──────────────────────────────────────-->│
     │  3. Authorization Request               │
     │     + code_challenge                    │
     │     + code_challenge_method=S256        │
     │                                         │
     │<──────────────────────────────────────── │
     │  4. Authorization Code                  │
     │                                         │
     │──────────────────────────────────────-->│
     │  5. Token Request                       │
     │     + code                              │
     │     + code_verifier                     │
     │                                         │
     │<──────────────────────────────────────── │
     │  6. Access Token + Refresh Token        │
     │                                         │
```

#### 3.2.2 PKCE Implementation Code

```dart
/// PKCE Helper for OAuth 2.0 security
class PKCEHelper {
  /// Generate cryptographically secure random string
  static String generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(64, (_) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  /// Generate code challenge using SHA-256
  static String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
```

### 3.3 Token Management

Tokens are securely stored using `flutter_secure_storage`:

```dart
class SpotifyAuthDatasource {
  final FlutterSecureStorage _secureStorage;

  Future<void> _storeTokens(SpotifyTokens tokens) async {
    await _secureStorage.write(
      key: 'spotify_access_token',
      value: tokens.accessToken,
    );
    await _secureStorage.write(
      key: 'spotify_refresh_token',
      value: tokens.refreshToken,
    );
    await _secureStorage.write(
      key: 'spotify_expires_at',
      value: tokens.expiresAt.toIso8601String(),
    );
  }

  Future<String?> getValidAccessToken() async {
    final tokens = await getStoredTokens();
    if (tokens == null) return null;

    // Refresh if expiring within 5 minutes
    if (tokens.willExpireSoon) {
      final refreshed = await refreshToken();
      return refreshed.accessToken;
    }

    return tokens.accessToken;
  }
}
```

### 3.4 Deep Link Configuration

OAuth callbacks are handled via custom URL schemes:

**iOS (Info.plist):**
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>vibe</string>
    </array>
    <key>CFBundleURLName</key>
    <string>com.vibe.app</string>
  </dict>
</array>
```

**Android (AndroidManifest.xml):**
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="vibe" android:host="callback"/>
</intent-filter>
```

---

## 4. Machine Learning Recommendation Algorithm

### 4.1 Algorithm Overview

The recommendation system uses a **multi-factor scoring model** that combines:

1. **Pattern Matching** - User's historical listening patterns
2. **Mood Alignment** - Target mood audio features
3. **Diversity Bonus** - Preventing filter bubbles
4. **Contextual Weighting** - Time-of-day preferences

### 4.2 Mathematical Formula

The total recommendation score for a track is calculated as:

```
S(T) = α·S_pattern + β·S_mood + γ·S_diversity + δ·S_context

Where:
- α = 0.35 (pattern weight)
- β = 0.40 (mood weight)
- γ = 0.15 (diversity weight)
- δ = 0.10 (context weight)
```

### 4.3 Gaussian Scoring Function

Pattern matching uses a Gaussian (normal) distribution to score how well a track's features match the user's preferences:

```dart
/// Gaussian scoring function
/// Returns value between 0 and 1
double _gaussianScore(double value, double mean, double sigma) {
  if (sigma == 0) return value == mean ? 1.0 : 0.0;
  final diff = value - mean;
  return math.exp(-(diff * diff) / (2 * sigma * sigma));
}
```

**Mathematical representation:**

```
G(x, μ, σ) = exp(-(x - μ)² / 2σ²)
```

Where:
- `x` = track's feature value
- `μ` = user's mean preference
- `σ` = user's standard deviation (tolerance)

### 4.4 Audio Features Analysis

Spotify provides 13 audio features per track:

| Feature | Range | Description |
|---------|-------|-------------|
| Energy | 0-1 | Intensity and activity |
| Valence | 0-1 | Musical positiveness |
| Danceability | 0-1 | Suitability for dancing |
| Tempo | BPM | Beats per minute |
| Acousticness | 0-1 | Acoustic vs electronic |
| Instrumentalness | 0-1 | Vocal presence |
| Speechiness | 0-1 | Spoken word presence |
| Liveness | 0-1 | Live recording probability |
| Loudness | dB | Overall loudness |

### 4.5 Mood Target Profiles

Pre-defined audio feature targets for each mood:

```dart
static const Map<MoodCategory, MoodTarget> targets = {
  MoodCategory.energetic: MoodTarget(
    energy: 0.85,
    valence: 0.75,
    danceability: 0.80,
    tempo: 130.0,
  ),
  MoodCategory.chill: MoodTarget(
    energy: 0.35,
    valence: 0.55,
    danceability: 0.45,
    tempo: 95.0,
    acousticness: 0.6,
  ),
  MoodCategory.focus: MoodTarget(
    energy: 0.45,
    valence: 0.50,
    danceability: 0.40,
    tempo: 100.0,
    instrumentalness: 0.7,
  ),
  // ... additional moods
};
```

### 4.6 Cosine Similarity for Mood Matching

```dart
/// Cosine similarity between two feature vectors
double cosineSimilarityTo(AudioFeatures other) {
  final a = _toVector();
  final b = other._toVector();

  double dotProduct = 0;
  double normA = 0;
  double normB = 0;

  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  if (normA == 0 || normB == 0) return 0;
  return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
}
```

### 4.7 Cold Start Strategy

For new users without listening history:

```dart
List<ScoredTrack> _coldStartRecommendations(
  List<Track> candidates,
  List<AudioFeatures> features,
  MoodCategory? targetMood,
) {
  // Use global popularity and mood matching only
  return candidates
      .mapIndexed((i, track) {
        final trackFeatures = features[i];

        double score = track.popularity / 100.0; // Popularity baseline

        if (targetMood != null) {
          final moodTarget = MoodTargets.get(targetMood).toAudioFeatures();
          score = score * 0.3 + trackFeatures.cosineSimilarityTo(moodTarget) * 0.7;
        }

        return ScoredTrack(track: track, score: score);
      })
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));
}
```

---

## 5. Data Layer Implementation

### 5.1 Repository Pattern

The repository pattern abstracts data source complexity:

```dart
/// Domain layer interface
abstract class MusicRepository {
  Future<Result<List<Track>, Failure>> searchTracks({
    required String query,
    int limit = 20,
  });

  Future<Result<AudioFeatures, Failure>> getAudioFeatures(String trackId);

  Future<Result<List<Track>, Failure>> getRecommendations({
    List<String>? seedTracks,
    MoodCategory? mood,
  });
}

/// Data layer implementation
class MusicRepositoryImpl implements MusicRepository {
  final SpotifyApiDatasource _apiDatasource;

  @override
  Future<Result<List<Track>, Failure>> searchTracks({
    required String query,
    int limit = 20,
  }) async {
    try {
      final response = await _apiDatasource.search(query: query, limit: limit);
      final tracks = response.map((json) => TrackModel.fromJson(json).toEntity());
      return Result.success(tracks.toList());
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    }
  }
}
```

### 5.2 Result Type for Error Handling

Functional error handling using a sealed class:

```dart
sealed class Result<T, E> {
  const Result();

  const factory Result.success(T value) = Success<T, E>;
  const factory Result.error(E error) = Error<T, E>;

  R fold<R>(R Function(T) onSuccess, R Function(E) onError);

  Result<U, E> map<U>(U Function(T) mapper);
  Result<U, E> flatMap<U>(Result<U, E> Function(T) mapper);
}

final class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);

  @override
  R fold<R>(R Function(T) onSuccess, R Function(E) onError) => onSuccess(value);
}

final class Error<T, E> extends Result<T, E> {
  final E error;
  const Error(this.error);

  @override
  R fold<R>(R Function(T) onSuccess, R Function(E) onError) => onError(error);
}
```

### 5.3 Data Models

Models handle JSON serialization:

```dart
class TrackModel {
  final String id;
  final String name;
  final List<String> artistNames;
  final String? albumName;
  final String? imageUrl;
  final String? previewUrl;
  final int durationMs;
  final int popularity;
  final bool explicit;

  factory TrackModel.fromSpotifyJson(Map<String, dynamic> json) {
    final artists = json['artists'] as List;
    final album = json['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;

    return TrackModel(
      id: json['id'],
      name: json['name'],
      artistNames: artists.map((a) => a['name'] as String).toList(),
      albumName: album?['name'],
      imageUrl: images?.isNotEmpty == true ? images!.first['url'] : null,
      previewUrl: json['preview_url'],
      durationMs: json['duration_ms'],
      popularity: json['popularity'] ?? 0,
      explicit: json['explicit'] ?? false,
    );
  }

  Track toEntity() => Track(
    id: id,
    name: name,
    artistNames: artistNames,
    albumName: albumName,
    albumImageUrl: imageUrl,
    previewUrl: previewUrl,
    durationMs: durationMs,
    popularity: popularity,
    explicit: explicit,
  );
}
```

---

## 6. User Interface Design

### 6.1 Design System

Consistent design tokens:

```dart
class AppColors {
  // Primary brand colors (Spotify-inspired)
  static const Color primary = Color(0xFF1DB954);
  static const Color primaryLight = Color(0xFF1ED760);

  // Background colors (Dark theme)
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF282828);

  // Mood category colors
  static const Color moodEnergetic = Color(0xFFFF6B35);
  static const Color moodChill = Color(0xFF4ECDC4);
  static const Color moodHappy = Color(0xFFFFE66D);
  static const Color moodSad = Color(0xFF5C7AEA);
}

class AppDimens {
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double radiusM = 12.0;
  static const double miniPlayerHeight = 72.0;
}
```

### 6.2 Component Architecture

Reusable widget hierarchy:

```
widgets/
├── track_card.dart        # Multi-mode track display
│   ├── TrackCardMode.list
│   ├── TrackCardMode.grid
│   ├── TrackCardMode.compact
│   └── TrackCardMode.horizontal
├── mini_player.dart       # Bottom player bar
├── mood_selector.dart     # Mood category selection
│   ├── MoodSelector       # Grid/Row layout
│   ├── MoodCard           # Animated card
│   └── MoodChip           # Compact chip
└── full_player_sheet.dart # Expanded player view
```

### 6.3 State Management with BLoC

```dart
/// Player BLoC
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final PlayerService _playerService;

  PlayerBloc({required PlayerService playerService})
      : _playerService = playerService,
        super(const PlayerState()) {
    on<PlayTrack>(_onPlayTrack);
    on<TogglePlayPause>(_onTogglePlayPause);
    on<SeekToProgress>(_onSeekToProgress);

    // Listen to service state changes
    _playerService.stateStream.listen((state) {
      add(_PlaybackStateUpdated(state));
    });
  }

  Future<void> _onPlayTrack(PlayTrack event, Emitter<PlayerState> emit) async {
    emit(state.copyWith(status: PlayerStatus.loading));
    await _playerService.play(event.track);
  }
}

/// UI Integration
BlocBuilder<PlayerBloc, PlayerState>(
  builder: (context, state) {
    return IconButton(
      icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
      onPressed: () => context.read<PlayerBloc>().add(const TogglePlayPause()),
    );
  },
)
```

---

## 7. Security Considerations

### 7.1 Security Measures Implemented

| Risk | Mitigation |
|------|------------|
| Token exposure | `flutter_secure_storage` with platform encryption |
| MITM attacks | Certificate pinning, HTTPS only |
| OAuth hijacking | PKCE flow, state parameter validation |
| Data leakage | No client secrets in code, server-side token exchange |

### 7.2 Secure Storage Implementation

```dart
// iOS: Keychain
// Android: EncryptedSharedPreferences (API 23+) or KeyStore
final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);
```

---

## 8. Performance Optimization

### 8.1 Implemented Optimizations

1. **Image Caching**: `cached_network_image` with disk cache
2. **Lazy Loading**: BLoCs registered as lazy singletons
3. **Pagination**: Infinite scroll with offset-based pagination
4. **Debouncing**: Search input debounced (300ms)
5. **Connection Pooling**: HTTP client reuse

### 8.2 Memory Management

```dart
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  StreamSubscription<PlaybackState>? _stateSubscription;

  @override
  Future<void> close() async {
    // Clean up subscriptions
    await _stateSubscription?.cancel();
    await _playerService.dispose();
    return super.close();
  }
}
```

---

## 9. Testing Strategy

### 9.1 Test Pyramid

```
          ┌───────────────┐
          │   E2E Tests   │  ← Integration/UI
          │    (10%)      │
          └───────────────┘
       ┌─────────────────────┐
       │  Integration Tests  │  ← Widget/BLoC
       │       (30%)         │
       └─────────────────────┘
    ┌───────────────────────────┐
    │      Unit Tests           │  ← Algorithm/Models
    │         (60%)             │
    └───────────────────────────┘
```

### 9.2 Example Unit Test

```dart
group('RecommendationAlgorithm', () {
  late RecommendationAlgorithm algorithm;

  setUp(() {
    algorithm = RecommendationAlgorithm();
  });

  test('gaussianScore returns 1.0 when value equals mean', () {
    final score = algorithm.gaussianScore(0.5, 0.5, 0.1);
    expect(score, equals(1.0));
  });

  test('recommends high-energy tracks for energetic mood', () async {
    final recommendations = await algorithm.getRecommendations(
      mood: MoodCategory.energetic,
      candidates: testTracks,
    );

    expect(recommendations.first.track.audioFeatures.energy, greaterThan(0.7));
  });
});
```

---

## 10. Conclusion

### 10.1 Achievements

1. **Secure Authentication**: OAuth 2.0 with PKCE implementation
2. **Scientific Algorithm**: Gaussian scoring with multi-factor analysis
3. **Scalable Architecture**: Clean Architecture with proper separation
4. **Cross-Platform**: Single codebase for iOS and Android
5. **User Experience**: Mood-based discovery with intuitive UI

### 10.2 Future Improvements

1. **Collaborative Filtering**: User similarity analysis
2. **Neural Networks**: Deep learning for feature extraction
3. **Social Features**: Friend activity and shared playlists
4. **Offline Mode**: Local caching and playback
5. **A/B Testing**: Algorithm performance comparison

### 10.3 Technical Metrics

| Metric | Value |
|--------|-------|
| Lines of Code | ~9,000 |
| Test Coverage | Target 70% |
| App Size | ~15MB |
| Cold Start Time | <2s |
| API Response Cache | 15min |

---

## Appendix A: File Structure

```
lib/
├── core/
│   ├── constants/app_constants.dart
│   ├── di/injection.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/api_client.dart
│   └── utils/
│       ├── deep_link_handler.dart
│       └── result.dart
├── data/
│   ├── datasources/
│   │   ├── local/player_service.dart
│   │   └── remote/
│   │       ├── spotify_api_datasource.dart
│   │       └── spotify_auth_datasource.dart
│   ├── models/
│   │   ├── audio_features_model.dart
│   │   └── track_model.dart
│   └── repositories/
│       ├── auth_repository_impl.dart
│       └── music_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── audio_features.dart
│   │   ├── track.dart
│   │   └── user_pattern.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── music_repository.dart
│   │   └── recommendation_repository.dart
│   └── usecases/
│       └── recommendation_algorithm.dart
└── presentation/
    ├── blocs/
    │   ├── auth/auth_bloc.dart
    │   └── player/player_bloc.dart
    ├── screens/home_screen.dart
    ├── theme/app_theme.dart
    └── widgets/
        ├── mini_player.dart
        ├── mood_selector.dart
        └── track_card.dart
```

## Appendix B: Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0

  # State Management
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2
  equatable: ^2.0.5

  # Dependency Injection
  get_it: ^7.6.4

  # Networking
  http: ^1.1.0

  # Storage
  flutter_secure_storage: ^9.0.0

  # Audio
  just_audio: ^0.9.36
  audio_service: ^0.18.12

  # UI
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0

  # Security
  crypto: ^3.0.3

  # Deep Links
  app_links: ^4.0.1
  url_launcher: ^6.2.1
```

---

**Document Version:** 1.0
**Last Updated:** 2025
**Total Pages:** ~15
