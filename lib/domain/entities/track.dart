/// Track entity representing a music track
///
/// This is a domain entity that contains the core business data
/// for a music track, independent of any data source.

import 'package:equatable/equatable.dart';
import 'audio_features.dart';

/// Immutable track entity
class Track extends Equatable {
  /// Spotify track ID
  final String id;

  /// Track name/title
  final String name;

  /// Artist name(s), comma-separated if multiple
  final String artist;

  /// Album artwork URL
  final String imageUrl;

  /// Spotify URI for opening in Spotify app
  final String spotifyUri;

  /// Preview URL for 30-second sample (may be null)
  final String? previewUrl;

  /// Album name
  final String? albumName;

  /// Track duration in milliseconds
  final int? durationMs;

  /// Popularity score (0-100)
  final int? popularity;

  /// Audio features (for recommendation algorithm)
  final AudioFeatures? audioFeatures;

  /// Recommendation score (0.0-1.0) from algorithm
  final double? recommendationScore;

  /// Whether this track is saved in user's library
  final bool? isSaved;

  const Track({
    required this.id,
    required this.name,
    required this.artist,
    required this.imageUrl,
    required this.spotifyUri,
    this.previewUrl,
    this.albumName,
    this.durationMs,
    this.popularity,
    this.audioFeatures,
    this.recommendationScore,
    this.isSaved,
  });

  /// Whether this track has a playable preview
  bool get hasPreview => previewUrl != null && previewUrl!.isNotEmpty;

  /// Formatted duration string (e.g., "3:45")
  String get formattedDuration {
    if (durationMs == null) return '--:--';
    final minutes = (durationMs! / 60000).floor();
    final seconds = ((durationMs! % 60000) / 1000).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Creates a copy with optional field updates
  Track copyWith({
    String? id,
    String? name,
    String? artist,
    String? imageUrl,
    String? spotifyUri,
    String? previewUrl,
    String? albumName,
    int? durationMs,
    int? popularity,
    AudioFeatures? audioFeatures,
    double? recommendationScore,
    bool? isSaved,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      imageUrl: imageUrl ?? this.imageUrl,
      spotifyUri: spotifyUri ?? this.spotifyUri,
      previewUrl: previewUrl ?? this.previewUrl,
      albumName: albumName ?? this.albumName,
      durationMs: durationMs ?? this.durationMs,
      popularity: popularity ?? this.popularity,
      audioFeatures: audioFeatures ?? this.audioFeatures,
      recommendationScore: recommendationScore ?? this.recommendationScore,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        artist,
        imageUrl,
        spotifyUri,
        previewUrl,
        albumName,
        durationMs,
        popularity,
        audioFeatures,
        recommendationScore,
        isSaved,
      ];

  @override
  String toString() => 'Track(id: $id, name: $name, artist: $artist)';
}

/// Lightweight track reference for history/favorites
class TrackReference extends Equatable {
  final String trackId;
  final String name;
  final String artist;
  final String? imageUrl;
  final DateTime timestamp;

  const TrackReference({
    required this.trackId,
    required this.name,
    required this.artist,
    this.imageUrl,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [trackId, name, artist, imageUrl, timestamp];
}
