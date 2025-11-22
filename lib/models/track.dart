import 'audio_features.dart';

class Track {
  final String id;
  final String name;
  final String artist;
  final String image;
  final String uri;
  final String? previewUrl;
  final double? score;
  final AudioFeatures? audioFeatures;
  final String? youtubeVideoId;
  final String? youtubeStreamUrl;

  Track({
    required this.id,
    required this.name,
    required this.artist,
    required this.image,
    required this.uri,
    this.previewUrl,
    this.score,
    this.audioFeatures,
    this.youtubeVideoId,
    this.youtubeStreamUrl,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      artist: json['artist'] ?? 'Unknown Artist',
      image: json['image'] ?? '',
      uri: json['uri'] ?? '',
      previewUrl: json['preview_url'],
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      audioFeatures: json['audio_features'] != null
          ? AudioFeatures.fromJson(json['audio_features'])
          : null,
      youtubeVideoId: json['youtube_video_id'],
      youtubeStreamUrl: json['youtube_stream_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'image': image,
      'uri': uri,
      'preview_url': previewUrl,
      if (score != null) 'score': score,
      if (audioFeatures != null) 'audio_features': audioFeatures!.toJson(),
      if (youtubeVideoId != null) 'youtube_video_id': youtubeVideoId,
      if (youtubeStreamUrl != null) 'youtube_stream_url': youtubeStreamUrl,
    };
  }

  /// Create a copy with updated YouTube data
  Track copyWith({
    String? id,
    String? name,
    String? artist,
    String? image,
    String? uri,
    String? previewUrl,
    double? score,
    AudioFeatures? audioFeatures,
    String? youtubeVideoId,
    String? youtubeStreamUrl,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      image: image ?? this.image,
      uri: uri ?? this.uri,
      previewUrl: previewUrl ?? this.previewUrl,
      score: score ?? this.score,
      audioFeatures: audioFeatures ?? this.audioFeatures,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      youtubeStreamUrl: youtubeStreamUrl ?? this.youtubeStreamUrl,
    );
  }

  @override
  String toString() {
    return 'Track(name: $name, artist: $artist, score: $score)';
  }
}
