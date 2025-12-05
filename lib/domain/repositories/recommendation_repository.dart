/// Recommendation Repository Interface
///
/// Defines the contract for the ML-based recommendation system.
/// Handles user patterns, mood analysis, and personalized recommendations.

import '../entities/track.dart';
import '../entities/audio_features.dart';
import '../entities/user_pattern.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';

/// Mood category for recommendations
enum MoodCategory {
  energetic('Energetic', 'High energy, upbeat tracks'),
  chill('Chill', 'Relaxed, calm vibes'),
  happy('Happy', 'Positive, joyful music'),
  sad('Sad', 'Melancholic, emotional tracks'),
  focus('Focus', 'Concentration-enhancing music'),
  workout('Workout', 'High-tempo exercise music'),
  party('Party', 'Dance and celebration tracks'),
  romantic('Romantic', 'Love songs and ballads'),
  sleep('Sleep', 'Calm, soothing sounds'),
  meditation('Meditation', 'Peaceful, mindful music');

  final String displayName;
  final String description;

  const MoodCategory(this.displayName, this.description);
}

/// Target audio features for a mood
class MoodTarget {
  final MoodCategory mood;
  final double energy;
  final double valence;
  final double danceability;
  final double tempo;
  final double instrumentalness;
  final double acousticness;

  const MoodTarget({
    required this.mood,
    required this.energy,
    required this.valence,
    required this.danceability,
    required this.tempo,
    this.instrumentalness = 0.5,
    this.acousticness = 0.5,
  });

  /// Convert to AudioFeatures for comparison
  AudioFeatures toAudioFeatures() {
    return AudioFeatures(
      id: mood.name,
      energy: energy,
      valence: valence,
      danceability: danceability,
      tempo: tempo,
      instrumentalness: instrumentalness,
      acousticness: acousticness,
      speechiness: 0.1,
      liveness: 0.2,
      loudness: -8.0,
      key: 0,
      mode: 1,
      timeSignature: 4,
      durationMs: 200000,
    );
  }
}

/// Predefined mood targets based on audio feature research
class MoodTargets {
  static const Map<MoodCategory, MoodTarget> targets = {
    MoodCategory.energetic: MoodTarget(
      mood: MoodCategory.energetic,
      energy: 0.85,
      valence: 0.75,
      danceability: 0.80,
      tempo: 130.0,
    ),
    MoodCategory.chill: MoodTarget(
      mood: MoodCategory.chill,
      energy: 0.35,
      valence: 0.55,
      danceability: 0.45,
      tempo: 95.0,
      acousticness: 0.6,
    ),
    MoodCategory.happy: MoodTarget(
      mood: MoodCategory.happy,
      energy: 0.70,
      valence: 0.85,
      danceability: 0.70,
      tempo: 120.0,
    ),
    MoodCategory.sad: MoodTarget(
      mood: MoodCategory.sad,
      energy: 0.30,
      valence: 0.20,
      danceability: 0.35,
      tempo: 85.0,
      acousticness: 0.5,
    ),
    MoodCategory.focus: MoodTarget(
      mood: MoodCategory.focus,
      energy: 0.45,
      valence: 0.50,
      danceability: 0.40,
      tempo: 100.0,
      instrumentalness: 0.7,
    ),
    MoodCategory.workout: MoodTarget(
      mood: MoodCategory.workout,
      energy: 0.90,
      valence: 0.70,
      danceability: 0.75,
      tempo: 140.0,
    ),
    MoodCategory.party: MoodTarget(
      mood: MoodCategory.party,
      energy: 0.85,
      valence: 0.80,
      danceability: 0.90,
      tempo: 125.0,
    ),
    MoodCategory.romantic: MoodTarget(
      mood: MoodCategory.romantic,
      energy: 0.40,
      valence: 0.60,
      danceability: 0.50,
      tempo: 90.0,
      acousticness: 0.4,
    ),
    MoodCategory.sleep: MoodTarget(
      mood: MoodCategory.sleep,
      energy: 0.15,
      valence: 0.40,
      danceability: 0.25,
      tempo: 70.0,
      instrumentalness: 0.6,
      acousticness: 0.7,
    ),
    MoodCategory.meditation: MoodTarget(
      mood: MoodCategory.meditation,
      energy: 0.20,
      valence: 0.50,
      danceability: 0.20,
      tempo: 65.0,
      instrumentalness: 0.8,
      acousticness: 0.6,
    ),
  };

  static MoodTarget get(MoodCategory mood) => targets[mood]!;
}

/// Track rating for feedback
class TrackRating {
  final String trackId;
  final String userId;
  final int rating; // 1-5 stars
  final MoodCategory? mood;
  final DateTime timestamp;
  final String? context; // e.g., 'morning', 'workout', 'work'

  const TrackRating({
    required this.trackId,
    required this.userId,
    required this.rating,
    this.mood,
    required this.timestamp,
    this.context,
  });

  bool get isPositive => rating >= 4;
  bool get isNegative => rating <= 2;
}

/// Scored track with recommendation score
class ScoredTrack {
  final Track track;
  final double score;
  final Map<String, double> scoreBreakdown;
  final String? explanation;

  const ScoredTrack({
    required this.track,
    required this.score,
    this.scoreBreakdown = const {},
    this.explanation,
  });
}

/// Recommendation repository interface
abstract class RecommendationRepository {
  // ============== USER PATTERNS ==============

  /// Get user's listening patterns
  Future<Result<UserPattern, Failure>> getUserPattern(String userId);

  /// Update user pattern based on listening history
  Future<Result<void, Failure>> updateUserPattern({
    required String userId,
    required List<Track> recentTracks,
    required List<AudioFeatures> audioFeatures,
  });

  /// Clear user pattern (reset)
  Future<Result<void, Failure>> clearUserPattern(String userId);

  // ============== RECOMMENDATIONS ==============

  /// Get personalized recommendations
  Future<Result<List<ScoredTrack>, Failure>> getRecommendations({
    required String userId,
    MoodCategory? mood,
    int limit = 20,
    bool includeExplanations = false,
  });

  /// Get recommendations for a specific mood
  Future<Result<List<ScoredTrack>, Failure>> getMoodRecommendations({
    required String userId,
    required MoodCategory mood,
    int limit = 20,
  });

  /// Get discovery recommendations (explore new genres/artists)
  Future<Result<List<ScoredTrack>, Failure>> getDiscoveryRecommendations({
    required String userId,
    int limit = 20,
  });

  /// Get similar tracks
  Future<Result<List<ScoredTrack>, Failure>> getSimilarTracks({
    required Track seedTrack,
    int limit = 20,
  });

  // ============== FEEDBACK ==============

  /// Record track rating for ML improvement
  Future<Result<void, Failure>> rateTrack({
    required String userId,
    required String trackId,
    required int rating,
    MoodCategory? mood,
    String? context,
  });

  /// Get user's rating history
  Future<Result<List<TrackRating>, Failure>> getUserRatings({
    required String userId,
    int limit = 100,
    int offset = 0,
  });

  /// Record skip event (negative signal)
  Future<Result<void, Failure>> recordSkip({
    required String userId,
    required String trackId,
    Duration listenedDuration,
  });

  /// Record full listen (positive signal)
  Future<Result<void, Failure>> recordFullListen({
    required String userId,
    required String trackId,
  });

  // ============== MOOD ANALYSIS ==============

  /// Analyze track mood based on audio features
  MoodCategory? analyzeTrackMood(AudioFeatures features);

  /// Get user's mood history/trends
  Future<Result<Map<MoodCategory, int>, Failure>> getMoodHistory({
    required String userId,
    int days = 30,
  });

  /// Detect current mood based on recent listening
  Future<Result<MoodCategory?, Failure>> detectCurrentMood(String userId);

  // ============== COLD START ==============

  /// Get onboarding recommendations for new users
  Future<Result<List<Track>, Failure>> getOnboardingTracks({int limit = 20});

  /// Process initial preferences from onboarding
  Future<Result<void, Failure>> processOnboardingPreferences({
    required String userId,
    required List<String> selectedTrackIds,
    required List<MoodCategory> preferredMoods,
  });
}
