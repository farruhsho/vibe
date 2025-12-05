/// Spotify Web API Data Source
///
/// Provides access to Spotify's Web API endpoints for:
/// - Searching tracks, artists, albums
/// - Getting track audio features
/// - Getting recommendations
/// - Managing user library
/// - Controlling playback (Premium required)
///
/// API Reference: https://developer.spotify.com/documentation/web-api

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/track_model.dart';
import '../../models/audio_features_model.dart';

/// Spotify API endpoints
class SpotifyEndpoints {
  static const String search = '/search';
  static const String tracks = '/tracks';
  static const String audioFeatures = '/audio-features';
  static const String recommendations = '/recommendations';
  static const String me = '/me';
  static const String meTracks = '/me/tracks';
  static const String meTopTracks = '/me/top/tracks';
  static const String meRecentlyPlayed = '/me/player/recently-played';
  static const String player = '/me/player';
  static const String playerPlay = '/me/player/play';
  static const String playerPause = '/me/player/pause';
  static const String playerNext = '/me/player/next';
  static const String playerPrevious = '/me/player/previous';
  static const String playerSeek = '/me/player/seek';
}

/// Spotify API Data Source
class SpotifyApiDatasource {
  final http.Client _httpClient;
  final String Function() _getAccessToken;

  SpotifyApiDatasource({
    required String Function() getAccessToken,
    http.Client? httpClient,
  })  : _getAccessToken = getAccessToken,
        _httpClient = httpClient ?? http.Client();

  /// Base API URL
  static const _baseUrl = 'https://api.spotify.com/v1';

  /// Make authenticated API request
  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    final token = _getAccessToken();
    if (token.isEmpty) {
      throw AuthException.noToken();
    }

    Uri uri = Uri.parse('$_baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await _httpClient.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _httpClient.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await _httpClient.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await _httpClient.delete(uri, headers: headers);
        break;
      default:
        throw SpotifyException(message: 'Unsupported HTTP method: $method');
    }

    // Handle rate limiting
    if (response.statusCode == 429) {
      final retryAfter = response.headers['retry-after'];
      throw SpotifyException(
        message: 'Rate limited. Retry after ${retryAfter}s',
        code: 'RATE_LIMITED',
        statusCode: 429,
      );
    }

    // Handle errors
    if (response.statusCode >= 400) {
      _handleApiError(response);
    }

    // Return empty map for 204 No Content
    if (response.statusCode == 204 || response.body.isEmpty) {
      return {};
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _handleApiError(http.Response response) {
    Map<String, dynamic>? errorBody;
    try {
      errorBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    final message = errorBody?['error']?['message'] ?? 'API request failed';

    throw SpotifyException.apiError(response.statusCode, message);
  }

  // ============== SEARCH ==============

  /// Search for tracks, artists, or albums
  Future<List<TrackModel>> searchTracks(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];

    final response = await _request(
      'GET',
      SpotifyEndpoints.search,
      queryParams: {
        'q': query,
        'type': 'track',
        'limit': limit.toString(),
        'market': 'US',
      },
    );

    final items = response['tracks']?['items'] as List<dynamic>? ?? [];
    return items.map((item) => TrackModel.fromSpotifyJson(item)).toList();
  }

  // ============== TRACKS ==============

  /// Get a single track by ID
  Future<TrackModel> getTrack(String trackId) async {
    final response = await _request('GET', '${SpotifyEndpoints.tracks}/$trackId');
    return TrackModel.fromSpotifyJson(response);
  }

  /// Get multiple tracks by IDs (max 50)
  Future<List<TrackModel>> getTracks(List<String> trackIds) async {
    if (trackIds.isEmpty) return [];
    if (trackIds.length > 50) {
      trackIds = trackIds.take(50).toList();
    }

    final response = await _request(
      'GET',
      SpotifyEndpoints.tracks,
      queryParams: {'ids': trackIds.join(',')},
    );

    final items = response['tracks'] as List<dynamic>? ?? [];
    return items.map((item) => TrackModel.fromSpotifyJson(item)).toList();
  }

  // ============== AUDIO FEATURES ==============

  /// Get audio features for a single track
  Future<AudioFeaturesModel> getAudioFeatures(String trackId) async {
    final response = await _request(
      'GET',
      '${SpotifyEndpoints.audioFeatures}/$trackId',
    );
    return AudioFeaturesModel.fromSpotifyJson(response);
  }

  /// Get audio features for multiple tracks (max 100)
  Future<List<AudioFeaturesModel>> getMultipleAudioFeatures(
    List<String> trackIds,
  ) async {
    if (trackIds.isEmpty) return [];
    if (trackIds.length > 100) {
      trackIds = trackIds.take(100).toList();
    }

    final response = await _request(
      'GET',
      SpotifyEndpoints.audioFeatures,
      queryParams: {'ids': trackIds.join(',')},
    );

    final items = response['audio_features'] as List<dynamic>? ?? [];
    return items
        .where((item) => item != null)
        .map((item) => AudioFeaturesModel.fromSpotifyJson(item))
        .toList();
  }

  // ============== RECOMMENDATIONS ==============

  /// Get recommendations based on seed tracks/artists/genres
  Future<List<TrackModel>> getRecommendations({
    List<String>? seedTracks,
    List<String>? seedArtists,
    List<String>? seedGenres,
    double? targetEnergy,
    double? targetValence,
    double? targetDanceability,
    double? targetTempo,
    double? minEnergy,
    double? maxEnergy,
    double? minValence,
    double? maxValence,
    int limit = 20,
  }) async {
    // Need at least one seed
    if ((seedTracks?.isEmpty ?? true) &&
        (seedArtists?.isEmpty ?? true) &&
        (seedGenres?.isEmpty ?? true)) {
      throw SpotifyException(
        message: 'At least one seed (track, artist, or genre) required',
        code: 'MISSING_SEEDS',
      );
    }

    final params = <String, String>{
      'limit': limit.toString(),
      'market': 'US',
    };

    // Add seeds (total max 5)
    if (seedTracks?.isNotEmpty ?? false) {
      params['seed_tracks'] = seedTracks!.take(5).join(',');
    }
    if (seedArtists?.isNotEmpty ?? false) {
      params['seed_artists'] = seedArtists!.take(5).join(',');
    }
    if (seedGenres?.isNotEmpty ?? false) {
      params['seed_genres'] = seedGenres!.take(5).join(',');
    }

    // Add target audio features
    if (targetEnergy != null) params['target_energy'] = targetEnergy.toString();
    if (targetValence != null) params['target_valence'] = targetValence.toString();
    if (targetDanceability != null) {
      params['target_danceability'] = targetDanceability.toString();
    }
    if (targetTempo != null) params['target_tempo'] = targetTempo.toString();

    // Add min/max constraints
    if (minEnergy != null) params['min_energy'] = minEnergy.toString();
    if (maxEnergy != null) params['max_energy'] = maxEnergy.toString();
    if (minValence != null) params['min_valence'] = minValence.toString();
    if (maxValence != null) params['max_valence'] = maxValence.toString();

    final response = await _request(
      'GET',
      SpotifyEndpoints.recommendations,
      queryParams: params,
    );

    final items = response['tracks'] as List<dynamic>? ?? [];
    return items.map((item) => TrackModel.fromSpotifyJson(item)).toList();
  }

  // ============== USER LIBRARY ==============

  /// Get user's saved tracks
  Future<List<TrackModel>> getSavedTracks({int limit = 50, int offset = 0}) async {
    final response = await _request(
      'GET',
      SpotifyEndpoints.meTracks,
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    final items = response['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => TrackModel.fromSpotifyJson(item['track']))
        .toList();
  }

  /// Save tracks to user's library
  Future<void> saveTracks(List<String> trackIds) async {
    await _request(
      'PUT',
      SpotifyEndpoints.meTracks,
      queryParams: {'ids': trackIds.join(',')},
    );
  }

  /// Remove tracks from user's library
  Future<void> removeTracks(List<String> trackIds) async {
    await _request(
      'DELETE',
      SpotifyEndpoints.meTracks,
      queryParams: {'ids': trackIds.join(',')},
    );
  }

  /// Check if tracks are saved
  Future<Map<String, bool>> checkSavedTracks(List<String> trackIds) async {
    final response = await _request(
      'GET',
      '${SpotifyEndpoints.meTracks}/contains',
      queryParams: {'ids': trackIds.join(',')},
    );

    // Response is just an array of booleans
    final results = response['_raw'] as String? ?? '[]';
    final booleans = (jsonDecode(results) as List<dynamic>).cast<bool>();

    return {
      for (int i = 0; i < trackIds.length && i < booleans.length; i++)
        trackIds[i]: booleans[i],
    };
  }

  // ============== USER TOP ITEMS ==============

  /// Get user's top tracks
  Future<List<TrackModel>> getTopTracks({
    String timeRange = 'medium_term', // short_term, medium_term, long_term
    int limit = 50,
  }) async {
    final response = await _request(
      'GET',
      SpotifyEndpoints.meTopTracks,
      queryParams: {
        'time_range': timeRange,
        'limit': limit.toString(),
      },
    );

    final items = response['items'] as List<dynamic>? ?? [];
    return items.map((item) => TrackModel.fromSpotifyJson(item)).toList();
  }

  /// Get user's recently played tracks
  Future<List<TrackModel>> getRecentlyPlayed({int limit = 50}) async {
    final response = await _request(
      'GET',
      SpotifyEndpoints.meRecentlyPlayed,
      queryParams: {'limit': limit.toString()},
    );

    final items = response['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => TrackModel.fromSpotifyJson(item['track']))
        .toList();
  }

  // ============== PLAYBACK CONTROL ==============
  // Note: These require Spotify Premium

  /// Get current playback state
  Future<Map<String, dynamic>> getPlaybackState() async {
    return _request('GET', SpotifyEndpoints.player);
  }

  /// Start/resume playback
  Future<void> play({String? deviceId, List<String>? uris, int? positionMs}) async {
    final params = <String, String>{};
    if (deviceId != null) params['device_id'] = deviceId;

    final body = <String, dynamic>{};
    if (uris != null) body['uris'] = uris;
    if (positionMs != null) body['position_ms'] = positionMs;

    await _request(
      'PUT',
      SpotifyEndpoints.playerPlay,
      queryParams: params.isNotEmpty ? params : null,
      body: body.isNotEmpty ? body : null,
    );
  }

  /// Pause playback
  Future<void> pause({String? deviceId}) async {
    final params = <String, String>{};
    if (deviceId != null) params['device_id'] = deviceId;

    await _request(
      'PUT',
      SpotifyEndpoints.playerPause,
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  /// Skip to next track
  Future<void> skipToNext({String? deviceId}) async {
    final params = <String, String>{};
    if (deviceId != null) params['device_id'] = deviceId;

    await _request(
      'POST',
      SpotifyEndpoints.playerNext,
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  /// Skip to previous track
  Future<void> skipToPrevious({String? deviceId}) async {
    final params = <String, String>{};
    if (deviceId != null) params['device_id'] = deviceId;

    await _request(
      'POST',
      SpotifyEndpoints.playerPrevious,
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  /// Seek to position in track
  Future<void> seek(int positionMs, {String? deviceId}) async {
    final params = <String, String>{
      'position_ms': positionMs.toString(),
    };
    if (deviceId != null) params['device_id'] = deviceId;

    await _request(
      'PUT',
      SpotifyEndpoints.playerSeek,
      queryParams: params,
    );
  }
}
