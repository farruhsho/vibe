import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/audio_features.dart';
import '../models/user_pattern.dart';
import 'dart:math' as math;

/// Service for analyzing user listening patterns from audio features
class PatternAnalyzer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Analyze user listening history and update their pattern
  /// Now includes time-of-day analysis for contextual recommendations
  static Future<UserPattern?> analyzeUserPattern(String userId) async {
    try {
      // Get user's listening history with audio features
      final historySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .orderBy('timestamp', descending: true)
          .limit(100) // Analyze last 100 tracks
          .get();

      if (historySnapshot.docs.isEmpty) {
        debugPrint('No listening history found for user $userId');
        return null;
      }

      // Extract audio features and timestamps from history
      final List<AudioFeatures> features = [];
      final List<DateTime> timestamps = [];

      for (var doc in historySnapshot.docs) {
        final data = doc.data();
        if (data['audio_features'] != null) {
          features.add(AudioFeatures.fromJson(data['audio_features']));

          // Extract timestamp for time-based analysis
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp != null) {
            timestamps.add(timestamp.toDate());
          }
        }
      }

      if (features.isEmpty) {
        debugPrint('No audio features found in history');
        return null;
      }

      // Calculate average values
      final avgEnergy = _calculateAverage(features.map((f) => f.energy).toList());
      final avgValence = _calculateAverage(features.map((f) => f.valence).toList());
      final avgDanceability = _calculateAverage(features.map((f) => f.danceability).toList());
      final avgTempo = _calculateAverage(features.map((f) => f.tempo).toList());

      // Calculate standard deviations (for pattern strength)
      final energyStdDev = _calculateStdDev(features.map((f) => f.energy).toList(), avgEnergy);
      final valenceStdDev = _calculateStdDev(features.map((f) => f.valence).toList(), avgValence);
      final danceabilityStdDev = _calculateStdDev(features.map((f) => f.danceability).toList(), avgDanceability);
      final tempoStdDev = _calculateStdDev(features.map((f) => f.tempo).toList(), avgTempo);

      // Analyze time-of-day patterns
      final timeOfDayPreferences = _analyzeTimeOfDayPatterns(features, timestamps);

      final pattern = UserPattern(
        userId: userId,
        avgEnergy: avgEnergy,
        avgValence: avgValence,
        avgDanceability: avgDanceability,
        avgTempo: avgTempo,
        totalTracksAnalyzed: features.length,
        lastUpdated: DateTime.now(),
        energyStdDev: energyStdDev,
        valenceStdDev: valenceStdDev,
        danceabilityStdDev: danceabilityStdDev,
        tempoStdDev: tempoStdDev / 200.0, // Normalize tempo std dev
        timeOfDayPreferences: timeOfDayPreferences,
      );

      // Save pattern to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('patterns')
          .doc('current')
          .set(pattern.toJson());

      debugPrint('Pattern analyzed: $pattern');
      return pattern;
    } catch (e) {
      debugPrint('Error analyzing pattern: $e');
      return null;
    }
  }

  /// Get current user pattern from Firestore
  static Future<UserPattern?> getUserPattern(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('patterns')
          .doc('current')
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserPattern.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error getting user pattern: $e');
      return null;
    }
  }

  /// Add track to listening history with audio features
  static Future<void> addToListeningHistory({
    required String trackId,
    required String trackName,
    required String artist,
    required AudioFeatures audioFeatures,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .add({
        'track_id': trackId,
        'track_name': trackName,
        'artist': artist,
        'audio_features': audioFeatures.toJson(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Limit history to 100 most recent tracks
      final oldDocs = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .orderBy('timestamp', descending: true)
          .get();

      if (oldDocs.docs.length > 100) {
        for (int i = 100; i < oldDocs.docs.length; i++) {
          await oldDocs.docs[i].reference.delete();
        }
      }

      debugPrint('Added to listening history: $trackName');
    } catch (e) {
      debugPrint('Error adding to listening history: $e');
    }
  }

  /// Save user rating for a recommendation
  static Future<void> saveRecommendationRating({
    required String trackId,
    required int rating,
    required double predictedScore,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ratings')
          .add({
        'track_id': trackId,
        'rating': rating,
        'predicted_score': predictedScore,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('Rating saved: $rating/5 for track $trackId');
    } catch (e) {
      debugPrint('Error saving rating: $e');
    }
  }

  /// Get recommendation accuracy statistics
  static Future<Map<String, double>> getAccuracyStats(String userId) async {
    try {
      final ratings = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .get();

      if (ratings.docs.isEmpty) {
        return {'average_rating': 0.0, 'total_ratings': 0.0, 'accuracy': 0.0};
      }

      double totalRating = 0.0;
      double totalError = 0.0;

      for (var doc in ratings.docs) {
        final data = doc.data();
        final rating = (data['rating'] as num).toDouble();
        final predicted = (data['predicted_score'] as num?)?.toDouble() ?? 0.5;

        totalRating += rating;
        // Calculate error between predicted (0-1) and actual rating (1-5 normalized to 0-1)
        totalError += (predicted - (rating - 1) / 4).abs();
      }

      final avgRating = totalRating / ratings.docs.length;
      final avgError = totalError / ratings.docs.length;
      final accuracy = (1.0 - avgError).clamp(0.0, 1.0);

      return {
        'average_rating': avgRating,
        'total_ratings': ratings.docs.length.toDouble(),
        'accuracy': accuracy,
      };
    } catch (e) {
      debugPrint('Error getting accuracy stats: $e');
      return {'average_rating': 0.0, 'total_ratings': 0.0, 'accuracy': 0.0};
    }
  }

  // Helper: Calculate average
  static double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  // Helper: Calculate standard deviation
  static double _calculateStdDev(List<double> values, double mean) {
    if (values.isEmpty) return 0.0;
    final variance = values
        .map((x) => math.pow(x - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }

  /// Analyze time-of-day listening patterns
  /// Returns a map of time period (0-5) to preference boost (0.0-1.0)
  /// Periods: 0 (0-4h), 1 (4-8h), 2 (8-12h), 3 (12-16h), 4 (16-20h), 5 (20-24h)
  static Map<String, double> _analyzeTimeOfDayPatterns(
    List<AudioFeatures> features,
    List<DateTime> timestamps,
  ) {
    if (features.length != timestamps.length || features.isEmpty) {
      return {};
    }

    // Group tracks by time period
    final Map<int, List<AudioFeatures>> periodFeatures = {};
    for (int i = 0; i < 6; i++) {
      periodFeatures[i] = [];
    }

    for (int i = 0; i < features.length; i++) {
      final hour = timestamps[i].hour;
      final period = hour ~/ 4; // 0-5
      periodFeatures[period]?.add(features[i]);
    }

    // Calculate preference for each period
    final Map<String, double> preferences = {};

    for (var entry in periodFeatures.entries) {
      if (entry.value.isEmpty) continue;

      final period = entry.key;
      final tracks = entry.value;

      // Calculate average energy for this period
      final avgEnergy = _calculateAverage(tracks.map((f) => f.energy).toList());
      final avgValence = _calculateAverage(tracks.map((f) => f.valence).toList());

      // Normalize to 0-1 preference score
      // Higher energy/valence during typical active hours = higher preference
      double preference = 0.5;

      if (period == 1 || period == 2) {
        // Morning/Noon: prefer energetic music
        preference = avgEnergy * 0.6 + avgValence * 0.4;
      } else if (period == 3 || period == 4) {
        // Afternoon/Evening: balanced
        preference = (avgEnergy + avgValence) / 2;
      } else {
        // Night/Early morning: prefer calm music
        preference = (1.0 - avgEnergy) * 0.6 + avgValence * 0.4;
      }

      preferences[period.toString()] = preference.clamp(0.0, 1.0);
    }

    debugPrint('Time-of-day preferences: $preferences');
    return preferences;
  }
}
