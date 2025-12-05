/// Scientific Mood-Based Recommendation Algorithm
///
/// This module implements a pattern-based music recommendation algorithm
/// designed for a diploma thesis. It uses Spotify's audio features to
/// match tracks to user preferences and mood selections.
///
/// THEORETICAL BACKGROUND:
/// The algorithm combines three approaches:
/// 1. Content-Based Filtering - using audio features as track descriptors
/// 2. User Pattern Matching - comparing tracks to user's listening history
/// 3. Mood Context Mapping - adjusting recommendations based on mood selection
///
/// ALGORITHM OVERVIEW:
/// For each candidate track T, we calculate a composite score S(T) as:
///
///   S(T) = α·S_pattern(T) + β·S_mood(T) + γ·S_diversity(T) + δ·S_context(T)
///
/// Where:
///   - S_pattern: Pattern matching score based on user's historical preferences
///   - S_mood: Mood compatibility score based on selected mood category
///   - S_diversity: Diversity factor to prevent filter bubbles
///   - S_context: Contextual factors (time of day, recent plays)
///   - α, β, γ, δ: Weighting coefficients (α + β + γ + δ = 1.0)

import 'dart:math' as math;
import '../entities/audio_features.dart';
import '../entities/user_pattern.dart';
import '../entities/track.dart';

/// Configuration for the recommendation algorithm
class RecommendationConfig {
  /// Weight for pattern matching score (α)
  final double patternWeight;

  /// Weight for mood matching score (β)
  final double moodWeight;

  /// Weight for diversity factor (γ)
  final double diversityWeight;

  /// Weight for contextual factors (δ)
  final double contextWeight;

  /// Standard deviation for Gaussian scoring function
  final double gaussianSigma;

  /// Minimum similarity threshold for diversity filtering
  final double diversityThreshold;

  /// Penalty factor for recently played tracks
  final double recentTrackPenalty;

  /// Number of recent tracks to penalize
  final int recentTrackWindow;

  const RecommendationConfig({
    this.patternWeight = 0.40,
    this.moodWeight = 0.35,
    this.diversityWeight = 0.10,
    this.contextWeight = 0.15,
    this.gaussianSigma = 0.25,
    this.diversityThreshold = 0.65,
    this.recentTrackPenalty = 0.5,
    this.recentTrackWindow = 10,
  });

  /// Validates that weights sum to 1.0
  bool get isValid =>
      (patternWeight + moodWeight + diversityWeight + contextWeight - 1.0).abs() < 0.001;
}

/// Mood category with target audio features
class MoodProfile {
  final String name;
  final String displayName;
  final double targetEnergy;
  final double targetValence;
  final double targetDanceability;
  final double targetTempo;
  final double? targetAcousticness;
  final double? targetInstrumentalness;
  final List<String> seedGenres;

  const MoodProfile({
    required this.name,
    required this.displayName,
    required this.targetEnergy,
    required this.targetValence,
    required this.targetDanceability,
    required this.targetTempo,
    this.targetAcousticness,
    this.targetInstrumentalness,
    this.seedGenres = const [],
  });

  /// Convert to pseudo AudioFeatures for comparison
  AudioFeatures toAudioFeatures() => AudioFeatures(
        trackId: 'mood_$name',
        energy: targetEnergy,
        valence: targetValence,
        danceability: targetDanceability,
        tempo: targetTempo,
        acousticness: targetAcousticness ?? 0.0,
        instrumentalness: targetInstrumentalness ?? 0.0,
      );
}

/// Predefined mood profiles with scientifically mapped audio features
class MoodProfiles {
  static const MoodProfile energetic = MoodProfile(
    name: 'energetic',
    displayName: 'Energetic',
    targetEnergy: 0.85,
    targetValence: 0.70,
    targetDanceability: 0.75,
    targetTempo: 130,
    seedGenres: ['pop', 'dance', 'electronic'],
  );

  static const MoodProfile chill = MoodProfile(
    name: 'chill',
    displayName: 'Chill',
    targetEnergy: 0.35,
    targetValence: 0.55,
    targetDanceability: 0.45,
    targetTempo: 95,
    targetAcousticness: 0.6,
    seedGenres: ['chill', 'ambient', 'lo-fi'],
  );

  static const MoodProfile happy = MoodProfile(
    name: 'happy',
    displayName: 'Happy',
    targetEnergy: 0.70,
    targetValence: 0.85,
    targetDanceability: 0.70,
    targetTempo: 120,
    seedGenres: ['pop', 'indie-pop', 'happy'],
  );

  static const MoodProfile sad = MoodProfile(
    name: 'sad',
    displayName: 'Sad',
    targetEnergy: 0.30,
    targetValence: 0.20,
    targetDanceability: 0.35,
    targetTempo: 85,
    targetAcousticness: 0.5,
    seedGenres: ['sad', 'acoustic', 'singer-songwriter'],
  );

  static const MoodProfile focus = MoodProfile(
    name: 'focus',
    displayName: 'Focus',
    targetEnergy: 0.45,
    targetValence: 0.50,
    targetDanceability: 0.30,
    targetTempo: 100,
    targetInstrumentalness: 0.7,
    seedGenres: ['classical', 'ambient', 'study'],
  );

  static const MoodProfile workout = MoodProfile(
    name: 'workout',
    displayName: 'Workout',
    targetEnergy: 0.90,
    targetValence: 0.65,
    targetDanceability: 0.80,
    targetTempo: 145,
    seedGenres: ['workout', 'edm', 'hip-hop'],
  );

  static const MoodProfile party = MoodProfile(
    name: 'party',
    displayName: 'Party',
    targetEnergy: 0.88,
    targetValence: 0.80,
    targetDanceability: 0.85,
    targetTempo: 128,
    seedGenres: ['dance', 'party', 'pop'],
  );

  static const MoodProfile romantic = MoodProfile(
    name: 'romantic',
    displayName: 'Romantic',
    targetEnergy: 0.40,
    targetValence: 0.60,
    targetDanceability: 0.50,
    targetTempo: 90,
    targetAcousticness: 0.4,
    seedGenres: ['romance', 'r-n-b', 'soul'],
  );

  static const MoodProfile sleep = MoodProfile(
    name: 'sleep',
    displayName: 'Sleep',
    targetEnergy: 0.15,
    targetValence: 0.40,
    targetDanceability: 0.20,
    targetTempo: 70,
    targetAcousticness: 0.7,
    targetInstrumentalness: 0.8,
    seedGenres: ['sleep', 'ambient', 'piano'],
  );

  static const MoodProfile meditation = MoodProfile(
    name: 'meditation',
    displayName: 'Meditation',
    targetEnergy: 0.10,
    targetValence: 0.45,
    targetDanceability: 0.15,
    targetTempo: 60,
    targetAcousticness: 0.8,
    targetInstrumentalness: 0.9,
    seedGenres: ['ambient', 'new-age', 'meditation'],
  );

  static MoodProfile? getByName(String name) {
    return all.where((m) => m.name.toLowerCase() == name.toLowerCase()).firstOrNull;
  }

  static List<MoodProfile> get all => [
        energetic, chill, happy, sad, focus,
        workout, party, romantic, sleep, meditation,
      ];
}

/// Result of recommendation scoring
class ScoredTrack {
  final Track track;
  final double totalScore;
  final double patternScore;
  final double moodScore;
  final double diversityScore;
  final double contextScore;

  const ScoredTrack({
    required this.track,
    required this.totalScore,
    required this.patternScore,
    required this.moodScore,
    required this.diversityScore,
    required this.contextScore,
  });

  @override
  String toString() =>
      'ScoredTrack(${track.name}, score: ${(totalScore * 100).toStringAsFixed(1)}%)';
}

/// Main Recommendation Algorithm
///
/// Implements the pattern-based recommendation system with
/// scientifically grounded scoring functions.
class RecommendationAlgorithm {
  final RecommendationConfig config;

  const RecommendationAlgorithm({
    this.config = const RecommendationConfig(),
  });

  /// Generate recommendations for a user based on mood selection
  ///
  /// Parameters:
  /// - [candidateTracks]: List of tracks to score and rank
  /// - [userPattern]: User's listening preference pattern (can be null for new users)
  /// - [mood]: Selected mood category
  /// - [recentTracks]: Recently played track IDs for diversity filtering
  ///
  /// Returns: Sorted list of scored tracks, highest score first
  List<ScoredTrack> generateRecommendations({
    required List<Track> candidateTracks,
    UserPattern? userPattern,
    required MoodProfile mood,
    List<String> recentTracks = const [],
  }) {
    if (candidateTracks.isEmpty) return [];

    // Score all candidate tracks
    final scoredTracks = <ScoredTrack>[];
    final selectedTracks = <Track>[];

    for (final track in candidateTracks) {
      if (track.audioFeatures == null) continue;

      final scores = _calculateScores(
        track: track,
        userPattern: userPattern,
        mood: mood,
        recentTracks: recentTracks,
        selectedTracks: selectedTracks,
      );

      // Calculate weighted total score
      final totalScore = config.patternWeight * scores['pattern']! +
          config.moodWeight * scores['mood']! +
          config.diversityWeight * scores['diversity']! +
          config.contextWeight * scores['context']!;

      scoredTracks.add(ScoredTrack(
        track: track.copyWith(recommendationScore: totalScore),
        totalScore: totalScore,
        patternScore: scores['pattern']!,
        moodScore: scores['mood']!,
        diversityScore: scores['diversity']!,
        contextScore: scores['context']!,
      ));

      selectedTracks.add(track);
    }

    // Sort by total score (descending)
    scoredTracks.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    // Apply diversity filtering to final list
    return _applyDiversityFilter(scoredTracks);
  }

  /// Calculate all component scores for a track
  Map<String, double> _calculateScores({
    required Track track,
    UserPattern? userPattern,
    required MoodProfile mood,
    required List<String> recentTracks,
    required List<Track> selectedTracks,
  }) {
    final features = track.audioFeatures!;

    return {
      'pattern': _calculatePatternScore(features, userPattern),
      'mood': _calculateMoodScore(features, mood),
      'diversity': _calculateDiversityScore(track, selectedTracks),
      'context': _calculateContextScore(track, recentTracks),
    };
  }

  /// Calculate Pattern Matching Score (S_pattern)
  ///
  /// Uses a Gaussian (normal distribution) scoring function:
  ///
  ///   S_pattern(f) = exp(-(f - μ)² / (2σ²))
  ///
  /// Where:
  ///   - f: Track's feature value
  ///   - μ: User's average preference for that feature
  ///   - σ: Standard deviation (configurable, controls tolerance)
  ///
  /// This gives highest scores (≈1.0) to tracks matching user preferences
  /// and decreasing scores as features deviate from preferences.
  double _calculatePatternScore(AudioFeatures features, UserPattern? pattern) {
    if (pattern == null || !pattern.isReliable) {
      return 0.5; // Neutral score for new users
    }

    final sigma = config.gaussianSigma;

    // Calculate Gaussian score for each feature
    final energyScore = _gaussianScore(
      features.energy,
      pattern.avgEnergy,
      sigma,
    );
    final valenceScore = _gaussianScore(
      features.valence,
      pattern.avgValence,
      sigma,
    );
    final danceabilityScore = _gaussianScore(
      features.danceability,
      pattern.avgDanceability,
      sigma,
    );
    final tempoScore = _gaussianScore(
      features.normalizedTempo,
      (pattern.avgTempo - 50) / 150, // Normalize pattern tempo
      sigma,
    );
    final acousticnessScore = _gaussianScore(
      features.acousticness,
      pattern.avgAcousticness,
      sigma,
    );

    // Weighted combination of feature scores
    // Weights based on psychological research on music preference factors
    const weights = {
      'energy': 0.25,
      'valence': 0.25,
      'danceability': 0.20,
      'tempo': 0.15,
      'acousticness': 0.15,
    };

    return weights['energy']! * energyScore +
        weights['valence']! * valenceScore +
        weights['danceability']! * danceabilityScore +
        weights['tempo']! * tempoScore +
        weights['acousticness']! * acousticnessScore;
  }

  /// Gaussian scoring function
  ///
  /// G(x, μ, σ) = exp(-(x - μ)² / (2σ²))
  double _gaussianScore(double value, double mean, double sigma) {
    final diff = value - mean;
    return math.exp(-(diff * diff) / (2 * sigma * sigma));
  }

  /// Calculate Mood Matching Score (S_mood)
  ///
  /// Measures how well a track's audio features match the target mood.
  /// Uses cosine similarity between feature vectors:
  ///
  ///   S_mood = (T · M) / (||T|| · ||M||)
  ///
  /// Where T is the track feature vector and M is the mood target vector.
  double _calculateMoodScore(AudioFeatures features, MoodProfile mood) {
    final moodFeatures = mood.toAudioFeatures();

    // Use the built-in cosine similarity function
    final cosineSim = features.cosineSimilarityTo(moodFeatures);

    // Also check tempo match (important for mood)
    final tempoDiff = (features.tempo - mood.targetTempo).abs();
    final tempoScore = math.max(0.0, 1.0 - (tempoDiff / 50.0));

    // Combine cosine similarity with tempo match
    return 0.7 * cosineSim + 0.3 * tempoScore;
  }

  /// Calculate Diversity Score (S_diversity)
  ///
  /// Penalizes tracks too similar to already selected tracks.
  /// This prevents "filter bubble" effect and ensures variety.
  ///
  ///   S_diversity = 1 - max(similarity(T, T_i) for all selected T_i)
  double _calculateDiversityScore(Track track, List<Track> selectedTracks) {
    if (selectedTracks.isEmpty) return 1.0;

    final features = track.audioFeatures;
    if (features == null) return 1.0;

    // Find maximum similarity to any selected track
    double maxSimilarity = 0.0;
    for (final selected in selectedTracks) {
      if (selected.audioFeatures != null) {
        final similarity = features.similarityTo(selected.audioFeatures!);
        maxSimilarity = math.max(maxSimilarity, similarity);
      }
    }

    // Invert: high diversity = low similarity
    return 1.0 - maxSimilarity;
  }

  /// Calculate Context Score (S_context)
  ///
  /// Incorporates contextual factors:
  /// 1. Time of day preference boost
  /// 2. Recent track penalty (avoid repetition)
  /// 3. Track popularity factor (mild boost for popular tracks)
  double _calculateContextScore(Track track, List<String> recentTracks) {
    double score = 1.0;

    // Apply recent track penalty
    if (recentTracks.contains(track.id)) {
      final position = recentTracks.indexOf(track.id);
      // Linear decay: more recent = higher penalty
      final penaltyFactor = 1.0 - (position / config.recentTrackWindow);
      score *= 1.0 - (config.recentTrackPenalty * penaltyFactor);
    }

    // Time of day boost (simplified - full implementation would use user pattern)
    score *= _getTimeOfDayBoost(track.audioFeatures);

    // Popularity factor (mild boost for proven tracks)
    if (track.popularity != null) {
      // Map 0-100 popularity to 0.95-1.05 boost
      final popularityBoost = 0.95 + (track.popularity! / 100) * 0.1;
      score *= popularityBoost;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Time of day preference adjustment
  ///
  /// Based on research on circadian rhythms and music preference:
  /// - Morning (6-10): Higher energy, moderate valence
  /// - Midday (10-14): Peak energy and valence
  /// - Afternoon (14-18): Slightly lower energy
  /// - Evening (18-22): Decreasing energy, varied valence
  /// - Night (22-6): Low energy, low danceability
  double _getTimeOfDayBoost(AudioFeatures? features) {
    if (features == null) return 1.0;

    final hour = DateTime.now().hour;
    double targetEnergy;
    double targetValence;

    if (hour >= 6 && hour < 10) {
      targetEnergy = 0.60;
      targetValence = 0.55;
    } else if (hour >= 10 && hour < 14) {
      targetEnergy = 0.70;
      targetValence = 0.65;
    } else if (hour >= 14 && hour < 18) {
      targetEnergy = 0.55;
      targetValence = 0.55;
    } else if (hour >= 18 && hour < 22) {
      targetEnergy = 0.50;
      targetValence = 0.60;
    } else {
      targetEnergy = 0.30;
      targetValence = 0.45;
    }

    // Calculate fit with time of day preferences
    final energyFit = 1.0 - (features.energy - targetEnergy).abs();
    final valenceFit = 1.0 - (features.valence - targetValence).abs();

    // Convert to boost factor (0.9-1.1 range)
    return 0.9 + ((energyFit + valenceFit) / 2) * 0.2;
  }

  /// Apply diversity filter to final recommendations
  ///
  /// Removes tracks that are too similar to higher-ranked tracks
  List<ScoredTrack> _applyDiversityFilter(List<ScoredTrack> scoredTracks) {
    if (scoredTracks.length <= 1) return scoredTracks;

    final filtered = <ScoredTrack>[scoredTracks.first];

    for (int i = 1; i < scoredTracks.length; i++) {
      final candidate = scoredTracks[i];
      final candidateFeatures = candidate.track.audioFeatures;

      if (candidateFeatures == null) {
        filtered.add(candidate);
        continue;
      }

      // Check similarity to all already selected tracks
      bool tooSimilar = false;
      for (final selected in filtered) {
        final selectedFeatures = selected.track.audioFeatures;
        if (selectedFeatures != null) {
          final similarity = candidateFeatures.similarityTo(selectedFeatures);
          if (similarity > config.diversityThreshold) {
            tooSimilar = true;
            break;
          }
        }
      }

      if (!tooSimilar) {
        filtered.add(candidate);
      }
    }

    return filtered;
  }
}

/// Cold-Start Strategy for new users
///
/// When a user has no listening history, we use these strategies:
/// 1. Mood-only scoring (S_mood gets 100% weight)
/// 2. Popularity-based ranking (prefer proven tracks)
/// 3. Diversity sampling (ensure variety in initial recommendations)
class ColdStartStrategy {
  /// Generate recommendations for new users without history
  static List<ScoredTrack> generateColdStartRecommendations({
    required List<Track> candidateTracks,
    required MoodProfile mood,
    int limit = 20,
  }) {
    final algorithm = RecommendationAlgorithm(
      config: const RecommendationConfig(
        patternWeight: 0.0, // No pattern data
        moodWeight: 0.70, // Rely heavily on mood
        diversityWeight: 0.15, // Ensure variety
        contextWeight: 0.15, // Context still matters
      ),
    );

    final recommendations = algorithm.generateRecommendations(
      candidateTracks: candidateTracks,
      userPattern: null,
      mood: mood,
    );

    return recommendations.take(limit).toList();
  }
}
