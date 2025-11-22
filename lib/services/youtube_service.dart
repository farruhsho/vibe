import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeService {
  static final _yt = YoutubeExplode();

  /// Search for a track on YouTube and return the audio stream URL
  static Future<String?> getAudioStreamUrl(String trackName, String artist) async {
    try {
      final query = '$trackName $artist';
      debugPrint('🔍 Searching YouTube for: $query');

      // Search for the video
      final searchResults = await _yt.search.search(query);

      if (searchResults.isEmpty) {
        debugPrint('❌ No results found on YouTube');
        return null;
      }

      final videoId = searchResults.first.id;
      debugPrint('✅ Found video: ${searchResults.first.title} (${videoId.value})');

      // Get the audio stream
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Get the best audio-only stream
      final audioStream = manifest.audioOnly.withHighestBitrate();

      if (audioStream == null) {
        debugPrint('❌ No audio stream found');
        return null;
      }

      final streamUrl = audioStream.url.toString();
      debugPrint('🎵 Audio stream URL obtained (${audioStream.bitrate.kiloBitsPerSecond} kbps)');

      return streamUrl;
    } catch (e) {
      debugPrint('❌ Error getting YouTube audio: $e');
      return null;
    }
  }

  /// Search YouTube and return video info
  static Future<Map<String, dynamic>?> searchTrack(String trackName, String artist) async {
    try {
      final query = '$trackName $artist';
      final searchResults = await _yt.search.search(query);

      if (searchResults.isEmpty) return null;

      final video = searchResults.first;

      return {
        'videoId': video.id.value,
        'title': video.title,
        'author': video.author,
        'thumbnail': video.thumbnails.highResUrl,
        'duration': video.duration?.inSeconds ?? 0,
      };
    } catch (e) {
      debugPrint('Error searching YouTube: $e');
      return null;
    }
  }

  /// Get direct audio URL for a specific YouTube video ID
  static Future<String?> getAudioUrlByVideoId(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      return audioStream?.url.toString();
    } catch (e) {
      debugPrint('Error getting audio by video ID: $e');
      return null;
    }
  }

  /// Close the YouTube client
  static void dispose() {
    _yt.close();
  }
}
