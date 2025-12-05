/// Audio Features entity for music analysis
///
/// Based on Spotify's Audio Features API:
/// https://developer.spotify.com/documentation/web-api/reference/get-audio-features
///
/// This entity contains all 13 audio features provided by Spotify,
/// used for the recommendation algorithm.

import 'dart:math' as math;

/// Complete audio features for a track
class AudioFeatures {
  /// The Spotify track ID
  final String id;

  /// Energy: 0.0 to 1.0
  final double energy;

  /// Valence: 0.0 to 1.0
  final double valence;

  /// Danceability: 0.0 to 1.0
  final double danceability;

  /// Tempo: Beats per minute (BPM)
  final double tempo;

  /// Acousticness: 0.0 to 1.0
  final double acousticness;

  /// Instrumentalness: 0.0 to 1.0
  final double instrumentalness;

  /// Liveness: 0.0 to 1.0
  final double liveness;

  /// Speechiness: 0.0 to 1.0
  final double speechiness;

  /// Loudness: -60 to 0 dB
  final double loudness;

  /// Key: 0-11 (C, C#, D, D#, E, F, F#, G, G#, A, A#, B)
  final int key;

  /// Mode: 0 = minor, 1 = major
  final int mode;

  /// Time Signature: 3-7
  final int timeSignature;

  /// Duration in milliseconds
  final int durationMs;

  const AudioFeatures({
    required this.id,
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
    this.durationMs = 0,
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
  double get normalizedTempo => ((tempo - 50) / 150).clamp(0.0, 1.0);

  /// Normalized loudness (0.0 to 1.0) for comparison
  double get normalizedLoudness => ((loudness + 60) / 60).clamp(0.0, 1.0);

  /// Calculate similarity score between two audio features
  double similarityTo(AudioFeatures other) {
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

    final distance = math.sqrt(weightedSumOfSquares);
    return (1.0 - distance).clamp(0.0, 1.0);
  }

  /// Calculate cosine similarity with another audio feature set
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
    String? id,
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
    int? durationMs,
  }) {
    return AudioFeatures(
      id: id ?? this.id,
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
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioFeatures && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AudioFeatures(energy: ${energy.toStringAsFixed(2)}, '
      'valence: ${valence.toStringAsFixed(2)}, '
      'danceability: ${danceability.toStringAsFixed(2)}, '
      'tempo: ${tempo.toStringAsFixed(0)} BPM, '
      'key: $keySignature)';
}
