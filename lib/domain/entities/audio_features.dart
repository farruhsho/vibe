/// Audio Features entity for music analysis
///
/// Based on Spotify's Audio Features API:
/// https://developer.spotify.com/documentation/web-api/reference/get-audio-features
///
/// This entity contains all 13 audio features provided by Spotify,
/// used for the recommendation algorithm.

import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Complete audio features for a track
class AudioFeatures extends Equatable {
  /// The Spotify track ID
  final String trackId;

  /// Energy: 0.0 to 1.0
  /// Represents a perceptual measure of intensity and activity.
  /// High energy tracks feel fast, loud, and noisy.
  /// Typically, metal has high energy, Bach prelude has low energy.
  final double energy;

  /// Valence: 0.0 to 1.0
  /// Describes the musical positiveness conveyed by a track.
  /// High valence sounds more positive (happy, cheerful, euphoric).
  /// Low valence sounds more negative (sad, depressed, angry).
  final double valence;

  /// Danceability: 0.0 to 1.0
  /// Describes how suitable a track is for dancing based on tempo,
  /// rhythm stability, beat strength, and overall regularity.
  final double danceability;

  /// Tempo: Beats per minute (BPM)
  /// The overall estimated tempo of a track.
  /// Typical range: 50-200 BPM
  final double tempo;

  /// Acousticness: 0.0 to 1.0
  /// A confidence measure of whether the track is acoustic.
  /// 1.0 represents high confidence the track is acoustic.
  final double acousticness;

  /// Instrumentalness: 0.0 to 1.0
  /// Predicts whether a track contains no vocals.
  /// Values above 0.5 represent instrumental tracks.
  final double instrumentalness;

  /// Liveness: 0.0 to 1.0
  /// Detects the presence of an audience in the recording.
  /// Values above 0.8 indicate the track was likely performed live.
  final double liveness;

  /// Speechiness: 0.0 to 1.0
  /// Detects the presence of spoken words in a track.
  /// Values between 0.33 and 0.66 describe tracks with both music and speech.
  final double speechiness;

  /// Loudness: -60 to 0 dB
  /// The overall loudness of a track in decibels (dB).
  /// Values typically range between -60 and 0 dB.
  final double loudness;

  /// Key: 0-11 (C, C#, D, D#, E, F, F#, G, G#, A, A#, B)
  /// The key the track is in using standard Pitch Class notation.
  /// -1 if no key was detected.
  final int key;

  /// Mode: 0 = minor, 1 = major
  /// Indicates the modality (major or minor) of a track.
  final int mode;

  /// Time Signature: 3-7
  /// An estimated time signature ranging from 3 to 7 (3/4 to 7/4).
  final int timeSignature;

  const AudioFeatures({
    required this.trackId,
    required this.energy,
    required this.valence,
    required this.danceability,
    required this.tempo,
    this.acousticness = 0.0,
    this.instrumentalness = 0.0,
    this.liveness = 0.0,
    this.speechiness = 0.0,
    this.loudness = -10.0,
    this.key = 0,
    this.mode = 1,
    this.timeSignature = 4,
  });

  /// Key name (e.g., "C", "D#", "A")
  String get keyName {
    const keyNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return key >= 0 && key < 12 ? keyNames[key] : 'Unknown';
  }

  /// Mode name ("Major" or "Minor")
  String get modeName => mode == 1 ? 'Major' : 'Minor';

  /// Full key signature (e.g., "C Major", "A Minor")
  String get keySignature => '$keyName $modeName';

  /// Normalized tempo (0.0 to 1.0) for comparison
  /// Maps 50-200 BPM to 0.0-1.0
  double get normalizedTempo => ((tempo - 50) / 150).clamp(0.0, 1.0);

  /// Normalized loudness (0.0 to 1.0) for comparison
  /// Maps -60 to 0 dB to 0.0-1.0
  double get normalizedLoudness => ((loudness + 60) / 60).clamp(0.0, 1.0);

  /// Calculate similarity score between two audio features
  /// Returns value from 0.0 (completely different) to 1.0 (identical)
  ///
  /// Uses weighted Euclidean distance in the feature space
  double similarityTo(AudioFeatures other) {
    // Weights for each feature in similarity calculation
    const weights = {
      'energy': 0.20,
      'valence': 0.20,
      'danceability': 0.15,
      'tempo': 0.12,
      'acousticness': 0.10,
      'instrumentalness': 0.08,
      'liveness': 0.05,
      'speechiness': 0.05,
      'loudness': 0.03,
      'mode': 0.02,
    };

    // Calculate weighted sum of squared differences
    double weightedSumOfSquares = 0.0;

    weightedSumOfSquares += weights['energy']! * math.pow(energy - other.energy, 2);
    weightedSumOfSquares += weights['valence']! * math.pow(valence - other.valence, 2);
    weightedSumOfSquares += weights['danceability']! * math.pow(danceability - other.danceability, 2);
    weightedSumOfSquares += weights['tempo']! * math.pow(normalizedTempo - other.normalizedTempo, 2);
    weightedSumOfSquares += weights['acousticness']! * math.pow(acousticness - other.acousticness, 2);
    weightedSumOfSquares += weights['instrumentalness']! * math.pow(instrumentalness - other.instrumentalness, 2);
    weightedSumOfSquares += weights['liveness']! * math.pow(liveness - other.liveness, 2);
    weightedSumOfSquares += weights['speechiness']! * math.pow(speechiness - other.speechiness, 2);
    weightedSumOfSquares += weights['loudness']! * math.pow(normalizedLoudness - other.normalizedLoudness, 2);
    weightedSumOfSquares += weights['mode']! * (mode == other.mode ? 0.0 : 1.0);

    // Convert distance to similarity (inverse relationship)
    // Maximum possible distance is 1.0 (if all features are at opposite extremes)
    final distance = math.sqrt(weightedSumOfSquares);
    return (1.0 - distance).clamp(0.0, 1.0);
  }

  /// Calculate cosine similarity with another audio feature set
  /// Better for comparing feature vectors
  double cosineSimilarityTo(AudioFeatures other) {
    final thisVector = [
      energy, valence, danceability, normalizedTempo, acousticness,
      instrumentalness, liveness, speechiness, normalizedLoudness,
    ];
    final otherVector = [
      other.energy, other.valence, other.danceability, other.normalizedTempo,
      other.acousticness, other.instrumentalness, other.liveness,
      other.speechiness, other.normalizedLoudness,
    ];

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < thisVector.length; i++) {
      dotProduct += thisVector[i] * otherVector[i];
      normA += thisVector[i] * thisVector[i];
      normB += otherVector[i] * otherVector[i];
    }

    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Get the feature vector as a list
  List<double> toVector() => [
        energy,
        valence,
        danceability,
        normalizedTempo,
        acousticness,
        instrumentalness,
        liveness,
        speechiness,
        normalizedLoudness,
      ];

  /// Create a copy with updated fields
  AudioFeatures copyWith({
    String? trackId,
    double? energy,
    double? valence,
    double? danceability,
    double? tempo,
    double? acousticness,
    double? instrumentalness,
    double? liveness,
    double? speechiness,
    double? loudness,
    int? key,
    int? mode,
    int? timeSignature,
  }) {
    return AudioFeatures(
      trackId: trackId ?? this.trackId,
      energy: energy ?? this.energy,
      valence: valence ?? this.valence,
      danceability: danceability ?? this.danceability,
      tempo: tempo ?? this.tempo,
      acousticness: acousticness ?? this.acousticness,
      instrumentalness: instrumentalness ?? this.instrumentalness,
      liveness: liveness ?? this.liveness,
      speechiness: speechiness ?? this.speechiness,
      loudness: loudness ?? this.loudness,
      key: key ?? this.key,
      mode: mode ?? this.mode,
      timeSignature: timeSignature ?? this.timeSignature,
    );
  }

  @override
  List<Object?> get props => [
        trackId, energy, valence, danceability, tempo, acousticness,
        instrumentalness, liveness, speechiness, loudness, key, mode, timeSignature,
      ];

  @override
  String toString() =>
      'AudioFeatures(energy: ${energy.toStringAsFixed(2)}, '
      'valence: ${valence.toStringAsFixed(2)}, '
      'danceability: ${danceability.toStringAsFixed(2)}, '
      'tempo: ${tempo.toStringAsFixed(0)} BPM, '
      'key: $keySignature)';
}
