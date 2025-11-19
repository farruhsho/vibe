class Track {
  final String id;
  final String name;
  final String artist;
  final String image;
  final String uri;
  final String? previewUrl;
  final double? score;

  Track({
    required this.id,
    required this.name,
    required this.artist,
    required this.image,
    required this.uri,
    this.previewUrl,
    this.score,
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
    };
  }

  @override
  String toString() {
    return 'Track(name: $name, artist: $artist, score: $score)';
  }
}
