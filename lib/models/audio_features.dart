/// Audio features for track analysis
/// Based on Spotify API audio features
class AudioFeatures {
  final String trackId;
  final double energy;        // 0.0-1.0: intensity and activity
  final double valence;       // 0.0-1.0: musical positiveness
  final double danceability;  // 0.0-1.0: how suitable for dancing
  final double tempo;         // BPM (beats per minute)
  final double acousticness;  // 0.0-1.0: confidence of acoustic
  final double instrumentalness; // 0.0-1.0: vocal content prediction
  final double liveness;      // 0.0-1.0: presence of audience
  final double speechiness;   // 0.0-1.0: presence of spoken words
  final double loudness;      // -60 to 0 db
  final int key;              // 0-11 (C, C#, D, ...)
  final int mode;             // 0 (minor) or 1 (major)
  final int timeSignature;    // 3-7

  AudioFeatures({
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

  factory AudioFeatures.fromJson(Map<String, dynamic> json) {
    return AudioFeatures(
      trackId: json['id'] ?? json['track_id'] ?? '',
      energy: (json['energy'] as num?)?.toDouble() ?? 0.5,
      valence: (json['valence'] as num?)?.toDouble() ?? 0.5,
      danceability: (json['danceability'] as num?)?.toDouble() ?? 0.5,
      tempo: (json['tempo'] as num?)?.toDouble() ?? 120.0,
      acousticness: (json['acousticness'] as num?)?.toDouble() ?? 0.0,
      instrumentalness: (json['instrumentalness'] as num?)?.toDouble() ?? 0.0,
      liveness: (json['liveness'] as num?)?.toDouble() ?? 0.0,
      speechiness: (json['speechiness'] as num?)?.toDouble() ?? 0.0,
      loudness: (json['loudness'] as num?)?.toDouble() ?? -10.0,
      key: (json['key'] as num?)?.toInt() ?? 0,
      mode: (json['mode'] as num?)?.toInt() ?? 1,
      timeSignature: (json['time_signature'] as num?)?.toInt() ?? 4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'track_id': trackId,
      'energy': energy,
      'valence': valence,
      'danceability': danceability,
      'tempo': tempo,
      'acousticness': acousticness,
      'instrumentalness': instrumentalness,
      'liveness': liveness,
      'speechiness': speechiness,
      'loudness': loudness,
      'key': key,
      'mode': mode,
      'time_signature': timeSignature,
    };
  }

  /// Calculate similarity score between two audio features (0.0 - 1.0)
  double similarityTo(AudioFeatures other) {
    final energyDiff = (energy - other.energy).abs();
    final valenceDiff = (valence - other.valence).abs();
    final danceDiff = (danceability - other.danceability).abs();
    final tempoDiff = ((tempo - other.tempo) / 200.0).abs().clamp(0.0, 1.0);

    // Weighted average (main features have more weight)
    final similarity = 1.0 - (
      energyDiff * 0.3 +
      valenceDiff * 0.3 +
      danceDiff * 0.25 +
      tempoDiff * 0.15
    );

    return similarity.clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'AudioFeatures(energy: ${energy.toStringAsFixed(2)}, '
           'valence: ${valence.toStringAsFixed(2)}, '
           'danceability: ${danceability.toStringAsFixed(2)}, '
           'tempo: ${tempo.toStringAsFixed(0)} BPM)';
  }
}
