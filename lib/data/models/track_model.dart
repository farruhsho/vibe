/// Track Data Model for JSON serialization
///
/// This model extends the domain Track entity with JSON serialization
/// capabilities for Spotify API responses and Firestore storage.

import '../../domain/entities/track.dart';
import '../../domain/entities/audio_features.dart';
import 'audio_features_model.dart';

class TrackModel extends Track {
  const TrackModel({
    required super.id,
    required super.name,
    required super.artist,
    required super.imageUrl,
    required super.spotifyUri,
    super.previewUrl,
    super.albumName,
    super.durationMs,
    super.popularity,
    super.audioFeatures,
    super.recommendationScore,
    super.isSaved,
    super.explicit,
  });

  /// Create from Spotify API response
  factory TrackModel.fromSpotifyJson(Map<String, dynamic> json) {
    // Extract artist names
    final artists = json['artists'] as List<dynamic>? ?? [];
    final artistNames = artists
        .map((a) => a['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .join(', ');

    // Extract album image (prefer medium size)
    final album = json['album'] as Map<String, dynamic>? ?? {};
    final images = album['images'] as List<dynamic>? ?? [];
    String imageUrl = '';
    if (images.isNotEmpty) {
      // Try to get 300x300 image, fallback to first available
      final mediumImage = images.firstWhere(
        (img) => (img['width'] as int?) == 300,
        orElse: () => images.first,
      );
      imageUrl = mediumImage['url'] as String? ?? '';
    }

    return TrackModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Track',
      artist: artistNames.isNotEmpty ? artistNames : 'Unknown Artist',
      imageUrl: imageUrl,
      spotifyUri: json['uri'] as String? ?? '',
      previewUrl: json['preview_url'] as String?,
      albumName: album['name'] as String?,
      durationMs: json['duration_ms'] as int?,
      popularity: json['popularity'] as int?,
      explicit: json['explicit'] as bool? ?? false,
    );
  }

  /// Create from Firestore document
  factory TrackModel.fromFirestore(Map<String, dynamic> data) {
    AudioFeatures? audioFeatures;
    if (data['audio_features'] != null) {
      audioFeatures = AudioFeaturesModel.fromFirestore(
        data['audio_features'] as Map<String, dynamic>,
      );
    }

    return TrackModel(
      id: data['track_id'] as String? ?? data['id'] as String? ?? '',
      name: data['name'] as String? ?? data['track_name'] as String? ?? '',
      artist: data['artist'] as String? ?? '',
      imageUrl: data['image_url'] as String? ?? data['image'] as String? ?? '',
      spotifyUri: data['uri'] as String? ?? data['spotify_uri'] as String? ?? '',
      previewUrl: data['preview_url'] as String?,
      albumName: data['album_name'] as String?,
      durationMs: data['duration_ms'] as int?,
      popularity: data['popularity'] as int?,
      audioFeatures: audioFeatures,
      recommendationScore: (data['score'] as num?)?.toDouble(),
      explicit: data['explicit'] as bool? ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'track_id': id,
      'name': name,
      'artist': artist,
      'image_url': imageUrl,
      'spotify_uri': spotifyUri,
      'preview_url': previewUrl,
      'album_name': albumName,
      'duration_ms': durationMs,
      'popularity': popularity,
      'explicit': explicit,
      if (audioFeatures != null)
        'audio_features': (audioFeatures as AudioFeaturesModel?)?.toFirestore() ??
            AudioFeaturesModel.fromEntity(audioFeatures!).toFirestore(),
      if (recommendationScore != null) 'score': recommendationScore,
    };
  }

  /// Convert to domain entity
  Track toEntity() => Track(
        id: id,
        name: name,
        artist: artist,
        imageUrl: imageUrl,
        spotifyUri: spotifyUri,
        previewUrl: previewUrl,
        albumName: albumName,
        durationMs: durationMs,
        popularity: popularity,
        audioFeatures: audioFeatures,
        recommendationScore: recommendationScore,
        isSaved: isSaved,
        explicit: explicit,
      );

  /// Create model from domain entity
  factory TrackModel.fromEntity(Track entity) => TrackModel(
        id: entity.id,
        name: entity.name,
        artist: entity.artist,
        imageUrl: entity.imageUrl,
        spotifyUri: entity.spotifyUri,
        previewUrl: entity.previewUrl,
        albumName: entity.albumName,
        durationMs: entity.durationMs,
        popularity: entity.popularity,
        audioFeatures: entity.audioFeatures,
        recommendationScore: entity.recommendationScore,
        isSaved: entity.isSaved,
        explicit: entity.explicit,
      );

  /// Copy with audio features attached
  TrackModel withAudioFeatures(AudioFeatures features) => TrackModel(
        id: id,
        name: name,
        artist: artist,
        imageUrl: imageUrl,
        spotifyUri: spotifyUri,
        previewUrl: previewUrl,
        albumName: albumName,
        durationMs: durationMs,
        popularity: popularity,
        audioFeatures: features,
        recommendationScore: recommendationScore,
        isSaved: isSaved,
        explicit: explicit,
      );

  /// Copy with recommendation score
  TrackModel withScore(double score) => TrackModel(
        id: id,
        name: name,
        artist: artist,
        imageUrl: imageUrl,
        spotifyUri: spotifyUri,
        previewUrl: previewUrl,
        albumName: albumName,
        durationMs: durationMs,
        popularity: popularity,
        audioFeatures: audioFeatures,
        recommendationScore: score,
        isSaved: isSaved,
        explicit: explicit,
      );
}
