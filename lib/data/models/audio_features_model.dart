/// Audio Features Data Model for JSON serialization
///
/// This model extends the domain AudioFeatures entity with JSON serialization
/// capabilities for Spotify API responses and Firestore storage.

import '../../domain/entities/audio_features.dart';

class AudioFeaturesModel extends AudioFeatures {
  const AudioFeaturesModel({
    required super.id,
    required super.energy,
    required super.valence,
    required super.danceability,
    required super.tempo,
    super.acousticness,
    super.instrumentalness,
    super.liveness,
    super.speechiness,
    super.loudness,
    super.key,
    super.mode,
    super.timeSignature,
    super.durationMs,
  });

  /// Create from Spotify Audio Features API response
  factory AudioFeaturesModel.fromSpotifyJson(Map<String, dynamic> json) {
    return AudioFeaturesModel(
      id: json['id'] as String? ?? '',
      energy: (json['energy'] as num?)?.toDouble() ?? 0.0,
      valence: (json['valence'] as num?)?.toDouble() ?? 0.0,
      danceability: (json['danceability'] as num?)?.toDouble() ?? 0.0,
      tempo: (json['tempo'] as num?)?.toDouble() ?? 120.0,
      acousticness: (json['acousticness'] as num?)?.toDouble() ?? 0.0,
      instrumentalness: (json['instrumentalness'] as num?)?.toDouble() ?? 0.0,
      liveness: (json['liveness'] as num?)?.toDouble() ?? 0.0,
      speechiness: (json['speechiness'] as num?)?.toDouble() ?? 0.0,
      loudness: (json['loudness'] as num?)?.toDouble() ?? -10.0,
      key: json['key'] as int? ?? 0,
      mode: json['mode'] as int? ?? 1,
      timeSignature: json['time_signature'] as int? ?? 4,
      durationMs: json['duration_ms'] as int? ?? 0,
    );
  }

  /// Create from Firestore document
  factory AudioFeaturesModel.fromFirestore(Map<String, dynamic> data) {
    return AudioFeaturesModel(
      id: data['track_id'] as String? ?? data['id'] as String? ?? '',
      energy: (data['energy'] as num?)?.toDouble() ?? 0.0,
      valence: (data['valence'] as num?)?.toDouble() ?? 0.0,
      danceability: (data['danceability'] as num?)?.toDouble() ?? 0.0,
      tempo: (data['tempo'] as num?)?.toDouble() ?? 120.0,
      acousticness: (data['acousticness'] as num?)?.toDouble() ?? 0.0,
      instrumentalness: (data['instrumentalness'] as num?)?.toDouble() ?? 0.0,
      liveness: (data['liveness'] as num?)?.toDouble() ?? 0.0,
      speechiness: (data['speechiness'] as num?)?.toDouble() ?? 0.0,
      loudness: (data['loudness'] as num?)?.toDouble() ?? -10.0,
      key: data['key'] as int? ?? 0,
      mode: data['mode'] as int? ?? 1,
      timeSignature: data['time_signature'] as int? ?? 4,
      durationMs: data['duration_ms'] as int? ?? 0,
    );
  }

  /// Create from JSON (alias for fromSpotifyJson for API compatibility)
  factory AudioFeaturesModel.fromJson(Map<String, dynamic> json) =>
      AudioFeaturesModel.fromSpotifyJson(json);

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'track_id': id,
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
      'duration_ms': durationMs,
    };
  }

  /// Convert to domain entity
  AudioFeatures toEntity() => AudioFeatures(
        id: id,
        energy: energy,
        valence: valence,
        danceability: danceability,
        tempo: tempo,
        acousticness: acousticness,
        instrumentalness: instrumentalness,
        liveness: liveness,
        speechiness: speechiness,
        loudness: loudness,
        key: key,
        mode: mode,
        timeSignature: timeSignature,
        durationMs: durationMs,
      );

  /// Create model from domain entity
  factory AudioFeaturesModel.fromEntity(AudioFeatures entity) =>
      AudioFeaturesModel(
        id: entity.id,
        energy: entity.energy,
        valence: entity.valence,
        danceability: entity.danceability,
        tempo: entity.tempo,
        acousticness: entity.acousticness,
        instrumentalness: entity.instrumentalness,
        liveness: entity.liveness,
        speechiness: entity.speechiness,
        loudness: entity.loudness,
        key: entity.key,
        mode: entity.mode,
        timeSignature: entity.timeSignature,
        durationMs: entity.durationMs,
      );

  /// Create a summary map for logging/debugging
  Map<String, String> toSummary() {
    return {
      'energy': '${(energy * 100).toStringAsFixed(0)}%',
      'valence': '${(valence * 100).toStringAsFixed(0)}%',
      'danceability': '${(danceability * 100).toStringAsFixed(0)}%',
      'tempo': '${tempo.toStringAsFixed(0)} BPM',
      'acousticness': '${(acousticness * 100).toStringAsFixed(0)}%',
      'key': keySignature,
    };
  }
}
