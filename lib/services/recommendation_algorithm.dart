import 'package:flutter/foundation.dart';
import '../models/audio_features.dart';
import '../models/user_pattern.dart';
import '../models/track.dart';
import 'dart:math' as math;

/// Advanced pattern-based music recommendation algorithm
/// Implements personalized track selection using audio feature analysis
/// with contextual awareness and intelligent diversity
class RecommendationAlgorithm {
  /// Calculate recommendation score for a track based on user pattern
  /// Returns score from 0.0 to 1.0
  ///
  /// [contextBoost] - Additional contextual factor (time of day, mood, activity)
  /// [recentTracks] - Recently played tracks to avoid repetition
  static double calculateScore({
    required AudioFeatures trackFeatures,
    required UserPattern userPattern,
    double contextBoost = 0.0,
    List<String>? recentTrackIds,
  }) {
    // Dynamic weight factors based on pattern strength
    // If user has strong preferences, emphasize them more
    final patternStrength = userPattern.patternStrength;

    // Adaptive weights based on user's listening patterns
    final double energyWeight = 0.25 + (patternStrength * 0.05);
    final double valenceWeight = 0.25 + (patternStrength * 0.05);
    const double danceabilityWeight = 0.20;
    const double tempoWeight = 0.12;
    const double acousticWeight = 0.08;
    const double moodWeight = 0.10; // Key & mode compatibility

    // Calculate individual feature scores
    final energyScore = _calculateFeatureScore(
      trackFeatures.energy,
      userPattern.avgEnergy,
      userPattern.energyStdDev,
    );

    final valenceScore = _calculateFeatureScore(
      trackFeatures.valence,
      userPattern.avgValence,
      userPattern.valenceStdDev,
    );

    final danceabilityScore = _calculateFeatureScore(
      trackFeatures.danceability,
      userPattern.avgDanceability,
      userPattern.danceabilityStdDev,
    );

    final tempoScore = _calculateTempoScore(
      trackFeatures.tempo,
      userPattern.avgTempo,
      userPattern.tempoStdDev,
    );

    // Additional advanced features
    final acousticScore = _calculateAcousticScore(
      trackFeatures.acousticness,
      userPattern,
    );

    final moodScore = _calculateMoodCompatibility(
      trackFeatures.key,
      trackFeatures.mode,
      trackFeatures.valence,
    );

    // Weighted sum with all features
    var totalScore = (
      energyScore * energyWeight +
      valenceScore * valenceWeight +
      danceabilityScore * danceabilityWeight +
      tempoScore * tempoWeight +
      acousticScore * acousticWeight +
      moodScore * moodWeight
    );

    // Apply context boost (time of day, activity, etc.)
    if (contextBoost > 0) {
      totalScore = totalScore * (1.0 + contextBoost * 0.3);
    }

    // Penalty for recently played tracks
    if (recentTrackIds != null && recentTrackIds.contains(trackFeatures.trackId)) {
      totalScore *= 0.5; // 50% penalty for recent tracks
    }

    return totalScore.clamp(0.0, 1.0);
  }

  /// Rank tracks based on pattern matching with contextual awareness
  static List<Track> rankTracks({
    required List<Track> tracks,
    required Map<String, AudioFeatures> audioFeaturesMap,
    required UserPattern userPattern,
    List<String>? recentTrackIds,
    DateTime? currentTime,
  }) {
    // Calculate context boost based on time of day
    final contextBoost = currentTime != null
        ? _getTimeOfDayBoost(currentTime, userPattern)
        : 0.0;

    // Calculate scores for each track
    final tracksWithScores = tracks.map((track) {
      final features = audioFeaturesMap[track.id];
      if (features == null) {
        return Track(
          id: track.id,
          name: track.name,
          artist: track.artist,
          image: track.image,
          uri: track.uri,
          previewUrl: track.previewUrl,
          score: 0.0,
        );
      }

      final score = calculateScore(
        trackFeatures: features,
        userPattern: userPattern,
        contextBoost: contextBoost,
        recentTrackIds: recentTrackIds,
      );

      return Track(
        id: track.id,
        name: track.name,
        artist: track.artist,
        image: track.image,
        uri: track.uri,
        previewUrl: track.previewUrl,
        score: score,
      );
    }).toList();

    // Sort by score (highest first)
    tracksWithScores.sort((a, b) {
      final scoreA = a.score ?? 0.0;
      final scoreB = b.score ?? 0.0;
      return scoreB.compareTo(scoreA);
    });

    return tracksWithScores;
  }

  /// Get diverse recommendations with intelligent variety
  /// Uses sliding window approach to maintain diversity while keeping high scores
  static List<Track> getDiverseRecommendations({
    required List<Track> rankedTracks,
    required Map<String, AudioFeatures> audioFeaturesMap,
    int limit = 20,
    double diversityThreshold = 0.65,
  }) {
    if (rankedTracks.isEmpty) return [];

    final selected = <Track>[];
    final selectedFeatures = <AudioFeatures>[];

    // Group tracks by score ranges for better diversity
    final topTier = rankedTracks.where((t) => (t.score ?? 0) >= 0.8).toList();
    final midTier = rankedTracks.where((t) => (t.score ?? 0) >= 0.6 && (t.score ?? 0) < 0.8).toList();
    final lowerTier = rankedTracks.where((t) => (t.score ?? 0) < 0.6).toList();

    // Helper function to add diverse tracks from a tier
    void addFromTier(List<Track> tier, int maxFromTier) {
      int addedFromTier = 0;

      for (var track in tier) {
        if (selected.length >= limit || addedFromTier >= maxFromTier) break;

        final features = audioFeaturesMap[track.id];
        if (features == null) continue;

        // Check diversity against recently selected (sliding window of last 5)
        bool isDiverse = true;
        final recentWindow = selectedFeatures.length > 5
            ? selectedFeatures.sublist(selectedFeatures.length - 5)
            : selectedFeatures;

        for (var selectedFeature in recentWindow) {
          final similarity = features.similarityTo(selectedFeature);
          if (similarity > diversityThreshold) {
            isDiverse = false;
            break;
          }
        }

        if (isDiverse || selected.isEmpty) {
          selected.add(track);
          selectedFeatures.add(features);
          addedFromTier++;
        }
      }
    }

    // Add tracks from different tiers with priority
    // 60% from top tier, 30% from mid tier, 10% from lower tier
    addFromTier(topTier, (limit * 0.6).ceil());
    addFromTier(midTier, (limit * 0.3).ceil());
    addFromTier(lowerTier, (limit * 0.1).ceil());

    debugPrint('Selected ${selected.length} diverse tracks from ${rankedTracks.length} '
        '(top: ${topTier.length}, mid: ${midTier.length}, low: ${lowerTier.length})');

    return selected;
  }

  /// Calculate feature score using normal distribution
  /// Tracks closer to user's average preference get higher scores
  static double _calculateFeatureScore(
    double trackValue,
    double userAvg,
    double userStdDev,
  ) {
    // If user has no variance (listens to very similar music), be strict
    final stdDev = userStdDev < 0.05 ? 0.1 : userStdDev;

    // Calculate z-score
    final zScore = (trackValue - userAvg).abs() / stdDev;

    // Convert to probability (Gaussian-like decay)
    // e^(-z^2/2) gives us a bell curve centered at user's preference
    final score = math.exp(-math.pow(zScore, 2) / 2);

    return score;
  }

  /// Calculate tempo score (tempo has different scale than other features)
  static double _calculateTempoScore(
    double trackTempo,
    double userAvgTempo,
    double userTempoStdDev,
  ) {
    // Normalize tempo difference to 0-1 scale
    // Tempo range is typically 60-200 BPM
    final tempoDiff = (trackTempo - userAvgTempo).abs();
    final normalizedDiff = (tempoDiff / 100.0).clamp(0.0, 1.0);

    // If user has varied tempo preference, be more lenient
    final tolerance = userTempoStdDev < 0.1 ? 0.2 : userTempoStdDev * 2;

    // Score decreases with difference, but respects user's tempo variance
    final score = math.max(0.0, 1.0 - (normalizedDiff / tolerance));

    return score.clamp(0.0, 1.0);
  }

  /// Calculate acousticness score (preference for acoustic vs electronic)
  static double _calculateAcousticScore(
    double acousticness,
    UserPattern userPattern,
  ) {
    // If user has consistent pattern with acoustic music, match it
    // Otherwise, use neutral scoring
    final avgAcoustic = userPattern.avgEnergy > 0.7 ? 0.3 : 0.5;
    final diff = (acousticness - avgAcoustic).abs();
    return 1.0 - diff;
  }

  /// Calculate mood compatibility based on key, mode, and valence
  /// Musical theory: major keys (mode=1) are generally happier, minor keys (mode=0) are sadder
  static double _calculateMoodCompatibility(
    int key,
    int mode,
    double valence,
  ) {
    // Musical mood matching
    // Major key with high valence = perfect match (1.0)
    // Minor key with low valence = perfect match (1.0)
    // Mismatch = lower score

    if (mode == 1) {
      // Major key - should match higher valence
      return 0.5 + (valence * 0.5);
    } else {
      // Minor key - should match lower valence
      return 0.5 + ((1.0 - valence) * 0.5);
    }
  }

  /// Get context boost based on time of day
  /// Morning: energetic music
  /// Afternoon: focus/work music
  /// Evening: relaxing music
  /// Night: calm/chill music
  static double _getTimeOfDayBoost(DateTime time, UserPattern userPattern) {
    final hour = time.hour;

    // Check if user has time-based preferences
    if (userPattern.timeOfDayPreferences != null) {
      final key = '${hour ~/ 4}'; // 0-5, 6 periods of 4 hours
      return userPattern.timeOfDayPreferences![key] ?? 0.0;
    }

    // Default time-based context
    if (hour >= 6 && hour < 10) {
      // Morning: prefer energetic music
      return userPattern.avgEnergy > 0.6 ? 0.2 : 0.0;
    } else if (hour >= 10 && hour < 18) {
      // Daytime: balanced
      return 0.1;
    } else if (hour >= 18 && hour < 22) {
      // Evening: prefer upbeat but not too intense
      return userPattern.avgValence > 0.5 ? 0.15 : 0.0;
    } else {
      // Night: prefer calm music
      return userPattern.avgEnergy < 0.4 ? 0.2 : 0.0;
    }
  }

  /// Explain why a track was recommended (for transparency)
  static String explainRecommendation({
    required Track track,
    required AudioFeatures trackFeatures,
    required UserPattern userPattern,
  }) {
    final score = track.score ?? 0.0;
    final energyMatch = (1.0 - (trackFeatures.energy - userPattern.avgEnergy).abs()) * 100;
    final valenceMatch = (1.0 - (trackFeatures.valence - userPattern.avgValence).abs()) * 100;
    final danceMatch = (1.0 - (trackFeatures.danceability - userPattern.avgDanceability).abs()) * 100;

    return 'Match: ${(score * 100).toStringAsFixed(0)}%\n'
           'Energy: ${energyMatch.toStringAsFixed(0)}% | '
           'Mood: ${valenceMatch.toStringAsFixed(0)}% | '
           'Dance: ${danceMatch.toStringAsFixed(0)}%';
  }
}
