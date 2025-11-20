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

  Track({
    required this.id,
    required this.name,
    required this.artist,
    required this.image,
    required this.uri,
    this.previewUrl,
    this.score,
    this.audioFeatures,
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
    };
  }

  @override
  String toString() {
    return 'Track(name: $name, artist: $artist, score: $score)';
  }
}
