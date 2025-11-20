import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/track.dart';
import '../models/audio_features.dart';
import '../config/api_config.dart';
import 'recommendation_algorithm.dart';
import 'pattern_analyzer.dart';

class SpotifyService {
  // Spotify API credentials (from config)
  static final String _clientId = ApiConfig.spotifyClientId;
  static final String _clientSecret = ApiConfig.spotifyClientSecret;

  // Кэш для токена
  static String? _cachedToken;
  static DateTime? _tokenExpiry;

  /// Получить токен через Client Credentials Flow (без авторизации пользователя)
  static Future<String> getClientCredentialsToken() async {
    // Проверяем кэш
    if (_cachedToken != null && _tokenExpiry != null) {
      if (DateTime.now().isBefore(_tokenExpiry!)) {
        return _cachedToken!;
      }
    }

    try {
      final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));

      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedToken = data['access_token'];
        final expiresIn = data['expires_in'] as int; // seconds
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); // -60 для запаса

        debugPrint('✅ Spotify token получен, действителен до: $_tokenExpiry');
        return _cachedToken!;
      } else {
        throw Exception('Failed to get token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения Spotify token: $e');
      rethrow;
    }
  }

  /// Получить AI-рекомендации с использованием продвинутого алгоритма
  static Future<List<Track>> getAIRecommendations(String mood) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      // 1. Get user pattern (if available)
      final userPattern = await PatternAnalyzer.getUserPattern(user.uid);

      // 2. Get real Spotify tracks for the mood - ВСЕГДА используем реальные треки!
      List<Track> moodTracks = await _getSpotifyTracksForMood(mood);
      debugPrint('✅ Получено ${moodTracks.length} реальных треков из Spotify для "$mood"');

      // 3. If no user pattern yet, return tracks as-is
      if (userPattern == null || !userPattern.isReliable) {
        debugPrint('No reliable pattern yet, returning ${moodTracks.length} tracks for mood: $mood');
        return moodTracks;
      }

      // 4. Get recent track IDs to avoid repetition
      final recentTrackIds = await _getRecentTrackIds(user.uid);

      // 5. Create audio features map
      final audioFeaturesMap = <String, AudioFeatures>{};
      for (var track in moodTracks) {
        if (track.audioFeatures != null) {
          audioFeaturesMap[track.id] = track.audioFeatures!;
        }
      }

      // 6. Rank tracks using advanced algorithm
      final rankedTracks = RecommendationAlgorithm.rankTracks(
        tracks: moodTracks,
        audioFeaturesMap: audioFeaturesMap,
        userPattern: userPattern,
        recentTrackIds: recentTrackIds,
        currentTime: DateTime.now(),
      );

      // 7. Get diverse recommendations
      final recommendations = RecommendationAlgorithm.getDiverseRecommendations(
        rankedTracks: rankedTracks,
        audioFeaturesMap: audioFeaturesMap,
        limit: 20,
      );

      debugPrint('AI Recommendations: ${recommendations.length} tracks '
          '(pattern strength: ${(userPattern.patternStrength * 100).toStringAsFixed(0)}%, '
          'analyzed: ${userPattern.totalTracksAnalyzed} tracks)');

      return recommendations;
    } catch (e) {
      debugPrint('Error in AI recommendations: $e');
      // Fallback to simple mock tracks
      return _getMockTracksForMood(mood);
    }
  }

  /// Get recent track IDs to avoid repetition
  static Future<List<String>> _getRecentTrackIds(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['track_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();
    } catch (e) {
      debugPrint('Error getting recent tracks: $e');
      return [];
    }
  }

  /// Get real Spotify tracks for mood using seed genres and audio features
  static Future<List<Track>> _getSpotifyTracksForMood(String mood) async {
    final token = await getClientCredentialsToken();

    // Map moods to Spotify seed genres and audio features
    String seedGenres;
    Map<String, double> targetFeatures;

    switch (mood.toLowerCase()) {
      case 'energetic':
      case 'power':
      case 'adrenaline':
      case 'workout':
        seedGenres = 'rock,edm,metal';
        targetFeatures = {'energy': 0.9, 'valence': 0.7, 'danceability': 0.8};
        break;
      case 'chill':
      case 'peaceful':
      case 'ambient':
      case 'sleep':
      case 'meditation':
        seedGenres = 'ambient,chill,acoustic';
        targetFeatures = {'energy': 0.3, 'valence': 0.6, 'danceability': 0.4};
        break;
      case 'happy':
      case 'uplifting':
      case 'euphoric':
      case 'sunny':
        seedGenres = 'pop,indie-pop,happy';
        targetFeatures = {'energy': 0.7, 'valence': 0.9, 'danceability': 0.75};
        break;
      case 'party':
      case 'dance':
      case 'club':
        seedGenres = 'dance,edm,party';
        targetFeatures = {'energy': 0.9, 'valence': 0.85, 'danceability': 0.95};
        break;
      case 'focus':
      case 'study':
      case 'work':
      case 'productive':
        seedGenres = 'classical,piano,study';
        targetFeatures = {'energy': 0.5, 'valence': 0.5, 'danceability': 0.3};
        break;
      case 'romantic':
      case 'love':
      case 'dinner':
        seedGenres = 'romance,soul,r-n-b';
        targetFeatures = {'energy': 0.45, 'valence': 0.85, 'danceability': 0.5};
        break;
      case 'running':
      case 'gaming':
        seedGenres = 'electronic,edm,techno';
        targetFeatures = {'energy': 0.9, 'valence': 0.7, 'danceability': 0.75};
        break;
      case 'sad':
      case 'melancholic':
      case 'rainy':
        seedGenres = 'sad,indie,alternative';
        targetFeatures = {'energy': 0.3, 'valence': 0.25, 'danceability': 0.3};
        break;
      case 'lofi':
      case 'reading':
        seedGenres = 'lo-fi,chill,jazz';
        targetFeatures = {'energy': 0.35, 'valence': 0.6, 'danceability': 0.5};
        break;
      case 'latin':
      case 'salsa':
        seedGenres = 'latin,salsa,reggaeton';
        targetFeatures = {'energy': 0.8, 'valence': 0.85, 'danceability': 0.9};
        break;
      case 'jazz':
      case 'jazz_mood':
        seedGenres = 'jazz,blues,soul';
        targetFeatures = {'energy': 0.45, 'valence': 0.65, 'danceability': 0.45};
        break;
      case 'metal':
      case 'aggressive':
        seedGenres = 'metal,hard-rock,punk';
        targetFeatures = {'energy': 0.95, 'valence': 0.4, 'danceability': 0.6};
        break;
      case 'pop':
      case 'pop_vibes':
        seedGenres = 'pop,indie-pop,dance-pop';
        targetFeatures = {'energy': 0.7, 'valence': 0.8, 'danceability': 0.75};
        break;
      case 'kpop':
        seedGenres = 'k-pop,pop,dance';
        targetFeatures = {'energy': 0.85, 'valence': 0.85, 'danceability': 0.9};
        break;
      case 'jpop':
        seedGenres = 'j-pop,j-rock,anime';
        targetFeatures = {'energy': 0.8, 'valence': 0.85, 'danceability': 0.85};
        break;
      default:
        seedGenres = 'pop,rock,indie';
        targetFeatures = {'energy': 0.6, 'valence': 0.6, 'danceability': 0.6};
    }

    // Build recommendations URL with audio features
    final params = {
      'seed_genres': seedGenres,
      'limit': '30',
      'market': 'US',
      'target_energy': targetFeatures['energy'].toString(),
      'target_valence': targetFeatures['valence'].toString(),
      'target_danceability': targetFeatures['danceability'].toString(),
    };

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/recommendations?$queryString'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tracks = (data['tracks'] as List).map((item) {
        final artists = (item['artists'] as List)
            .map((a) => a['name'] as String)
            .join(', ');

        final images = item['album']['images'] as List;
        final imageUrl = images.isNotEmpty ? images[0]['url'] as String : '';

        return Track(
          id: item['id'],
          name: item['name'],
          artist: artists,
          image: imageUrl,
          uri: item['uri'],
          previewUrl: item['preview_url'],
        );
      }).toList();

      debugPrint('✅ Spotify recommendations для "$mood": ${tracks.length} треков');
      return tracks;
    } else {
      throw Exception('Recommendations failed: ${response.statusCode}');
    }
  }

  /// Получить популярные рекомендации для главного экрана
  static Future<List<Track>> getPopularRecommendations() async {
    final token = await getClientCredentialsToken();

    // Используем несколько популярных жанров для разнообразия
    final params = {
      'seed_genres': 'pop,rock,hip-hop,indie,electronic',
      'limit': '20',
      'market': 'US',
      'target_popularity': '70', // Популярные треки
    };

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/recommendations?$queryString'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tracks = (data['tracks'] as List).map((item) {
          final artists = (item['artists'] as List)
              .map((a) => a['name'] as String)
              .join(', ');

          final images = item['album']['images'] as List;
          final imageUrl = images.isNotEmpty ? images[0]['url'] as String : '';

          return Track(
            id: item['id'],
            name: item['name'],
            artist: artists,
            image: imageUrl,
            uri: item['uri'],
            previewUrl: item['preview_url'],
          );
        }).toList();

        debugPrint('✅ Загружено ${tracks.length} популярных рекомендаций');
        return tracks;
      } else {
        debugPrint('⚠️ Ошибка получения рекомендаций: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Ошибка получения популярных рекомендаций: $e');
      return [];
    }
  }

  /// Mock треки для разных настроений
  static List<Track> _getMockTracksForMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'chill':
        return _generateChillTracks();
      case 'energetic':
        return _generateEnergeticTracks();
      case 'happy':
        return _generateHappyTracks();
      case 'focus':
        return _generateFocusTracks();
      case 'party':
        return _generatePartyTracks();
      case 'workout':
        return _generateWorkoutTracks();
      case 'sleep':
        return _generateSleepTracks();
      case 'romantic':
        return _generateRomanticTracks();
      default:
        return _generateChillTracks();
    }
  }

  /// Generate diverse chill tracks
  static List<Track> _generateChillTracks() {
    return [
      Track(
        id: 'mock_chill_1',
        name: 'Sunset Dreams',
        artist: 'Ambient Artist',
        image: 'https://via.placeholder.com/300/667eea/ffffff?text=Chill+1',
        uri: 'spotify:track:mock1',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_chill_1',
          energy: 0.3,
          valence: 0.6,
          danceability: 0.4,
          tempo: 85,
          acousticness: 0.7,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_chill_2',
        name: 'Ocean Waves',
        artist: 'Relaxation Band',
        image: 'https://via.placeholder.com/300/667eea/ffffff?text=Chill+2',
        uri: 'spotify:track:mock2',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_chill_2',
          energy: 0.25,
          valence: 0.7,
          danceability: 0.35,
          tempo: 78,
          acousticness: 0.8,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_chill_3',
        name: 'Moonlight Melody',
        artist: 'Calm Collective',
        image: 'https://via.placeholder.com/300/667eea/ffffff?text=Chill+3',
        uri: 'spotify:track:mock3',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_chill_3',
          energy: 0.28,
          valence: 0.65,
          danceability: 0.38,
          tempo: 82,
          acousticness: 0.75,
          mode: 0,
        ),
      ),
      Track(
        id: 'mock_chill_4',
        name: 'Floating Clouds',
        artist: 'Serenity Now',
        image: 'https://via.placeholder.com/300/667eea/ffffff?text=Chill+4',
        uri: 'spotify:track:mock_c4',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_chill_4',
          energy: 0.22,
          valence: 0.55,
          danceability: 0.32,
          tempo: 72,
          acousticness: 0.85,
          mode: 0,
        ),
      ),
      Track(
        id: 'mock_chill_5',
        name: 'Gentle Rain',
        artist: 'Nature Sounds',
        image: 'https://via.placeholder.com/300/667eea/ffffff?text=Chill+5',
        uri: 'spotify:track:mock_c5',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_chill_5',
          energy: 0.18,
          valence: 0.5,
          danceability: 0.3,
          tempo: 68,
          acousticness: 0.95,
          mode: 1,
        ),
      ),
    ];
  }

  /// Generate energetic tracks
  static List<Track> _generateEnergeticTracks() {
    return [
      Track(
        id: 'mock_energy_1',
        name: 'Electric Thunder',
        artist: 'Power Surge',
        image: 'https://via.placeholder.com/300/f97316/ffffff?text=Energy+1',
        uri: 'spotify:track:mock4',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_energy_1',
          energy: 0.92,
          valence: 0.75,
          danceability: 0.85,
          tempo: 140,
          acousticness: 0.1,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_energy_2',
        name: 'Adrenaline Rush',
        artist: 'High Voltage',
        image: 'https://via.placeholder.com/300/f97316/ffffff?text=Energy+2',
        uri: 'spotify:track:mock5',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_energy_2',
          energy: 0.88,
          valence: 0.8,
          danceability: 0.82,
          tempo: 135,
          acousticness: 0.15,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_energy_3',
        name: 'Turbo Mode',
        artist: 'Fast Lane',
        image: 'https://via.placeholder.com/300/f97316/ffffff?text=Energy+3',
        uri: 'spotify:track:mock6',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_energy_3',
          energy: 0.9,
          valence: 0.78,
          danceability: 0.88,
          tempo: 145,
          acousticness: 0.08,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_energy_4',
        name: 'Velocity',
        artist: 'Speed Demons',
        image: 'https://via.placeholder.com/300/f97316/ffffff?text=Energy+4',
        uri: 'spotify:track:mock_e4',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_energy_4',
          energy: 0.95,
          valence: 0.82,
          danceability: 0.9,
          tempo: 150,
          acousticness: 0.05,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_energy_5',
        name: 'Rocket Fuel',
        artist: 'Nitro Boost',
        image: 'https://via.placeholder.com/300/f97316/ffffff?text=Energy+5',
        uri: 'spotify:track:mock_e5',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_energy_5',
          energy: 0.93,
          valence: 0.85,
          danceability: 0.87,
          tempo: 142,
          acousticness: 0.12,
          mode: 1,
        ),
      ),
    ];
  }

  /// Generate happy tracks
  static List<Track> _generateHappyTracks() {
    return [
      Track(
        id: 'mock_happy_1',
        name: 'Sunshine Vibes',
        artist: 'Happy Squad',
        image: 'https://via.placeholder.com/300/fbbf24/ffffff?text=Happy+1',
        uri: 'spotify:track:mock7',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_happy_1',
          energy: 0.65,
          valence: 0.95,
          danceability: 0.75,
          tempo: 115,
          acousticness: 0.3,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_happy_2',
        name: 'Good Morning',
        artist: 'Smile More',
        image: 'https://via.placeholder.com/300/fbbf24/ffffff?text=Happy+2',
        uri: 'spotify:track:mock8',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_happy_2',
          energy: 0.7,
          valence: 0.92,
          danceability: 0.78,
          tempo: 120,
          acousticness: 0.25,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_happy_3',
        name: 'Joy Ride',
        artist: 'Positive Vibes',
        image: 'https://via.placeholder.com/300/fbbf24/ffffff?text=Happy+3',
        uri: 'spotify:track:mock9',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_happy_3',
          energy: 0.68,
          valence: 0.88,
          danceability: 0.72,
          tempo: 118,
          acousticness: 0.35,
          mode: 1,
        ),
      ),
    ];
  }

  /// Generate focus tracks
  static List<Track> _generateFocusTracks() {
    return [
      Track(
        id: 'mock_focus_1',
        name: 'Deep Concentration',
        artist: 'Study Beats',
        image: 'https://via.placeholder.com/300/a855f7/ffffff?text=Focus+1',
        uri: 'spotify:track:mock10',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_focus_1',
          energy: 0.45,
          valence: 0.5,
          danceability: 0.5,
          tempo: 95,
          acousticness: 0.6,
          instrumentalness: 0.8,
          mode: 0,
        ),
      ),
      Track(
        id: 'mock_focus_2',
        name: 'Mind Flow',
        artist: 'Productivity Tunes',
        image: 'https://via.placeholder.com/300/a855f7/ffffff?text=Focus+2',
        uri: 'spotify:track:mock11',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_focus_2',
          energy: 0.4,
          valence: 0.55,
          danceability: 0.45,
          tempo: 90,
          acousticness: 0.65,
          instrumentalness: 0.85,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_focus_3',
        name: 'Zen Workspace',
        artist: 'Focus Masters',
        image: 'https://via.placeholder.com/300/a855f7/ffffff?text=Focus+3',
        uri: 'spotify:track:mock12',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_focus_3',
          energy: 0.38,
          valence: 0.48,
          danceability: 0.42,
          tempo: 88,
          acousticness: 0.7,
          instrumentalness: 0.9,
          mode: 0,
        ),
      ),
    ];
  }

  /// Generate party tracks
  static List<Track> _generatePartyTracks() {
    return [
      Track(
        id: 'mock_party_1',
        name: 'Dance All Night',
        artist: 'DJ Hype',
        image: 'https://via.placeholder.com/300/ec4899/ffffff?text=Party+1',
        uri: 'spotify:track:mock13',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_party_1',
          energy: 0.95,
          valence: 0.85,
          danceability: 0.95,
          tempo: 128,
          acousticness: 0.05,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_party_2',
        name: 'Bass Drop',
        artist: 'Club Master',
        image: 'https://via.placeholder.com/300/ec4899/ffffff?text=Party+2',
        uri: 'spotify:track:mock14',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_party_2',
          energy: 0.98,
          valence: 0.88,
          danceability: 0.92,
          tempo: 130,
          acousticness: 0.03,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_party_3',
        name: 'Weekend Fever',
        artist: 'Night Owls',
        image: 'https://via.placeholder.com/300/ec4899/ffffff?text=Party+3',
        uri: 'spotify:track:mock15',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_party_3',
          energy: 0.97,
          valence: 0.9,
          danceability: 0.97,
          tempo: 132,
          acousticness: 0.02,
          mode: 1,
        ),
      ),
    ];
  }

  /// Generate workout tracks
  static List<Track> _generateWorkoutTracks() {
    return [
      Track(
        id: 'mock_workout_1',
        name: 'Beast Mode',
        artist: 'Gym Motivation',
        image: 'https://via.placeholder.com/300/ef4444/ffffff?text=Workout+1',
        uri: 'spotify:track:mock_w1',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_workout_1',
          energy: 0.98,
          valence: 0.7,
          danceability: 0.8,
          tempo: 155,
          acousticness: 0.05,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_workout_2',
        name: 'Power Hour',
        artist: 'Fitness Beats',
        image: 'https://via.placeholder.com/300/ef4444/ffffff?text=Workout+2',
        uri: 'spotify:track:mock_w2',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_workout_2',
          energy: 0.96,
          valence: 0.75,
          danceability: 0.85,
          tempo: 150,
          acousticness: 0.03,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_workout_3',
        name: 'Maximum Effort',
        artist: 'Training Zone',
        image: 'https://via.placeholder.com/300/ef4444/ffffff?text=Workout+3',
        uri: 'spotify:track:mock_w3',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_workout_3',
          energy: 0.99,
          valence: 0.8,
          danceability: 0.82,
          tempo: 160,
          acousticness: 0.02,
          mode: 1,
        ),
      ),
    ];
  }

  /// Generate sleep tracks
  static List<Track> _generateSleepTracks() {
    return [
      Track(
        id: 'mock_sleep_1',
        name: 'Deep Rest',
        artist: 'Sleep Therapy',
        image: 'https://via.placeholder.com/300/4f46e5/ffffff?text=Sleep+1',
        uri: 'spotify:track:mock_s1',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_sleep_1',
          energy: 0.15,
          valence: 0.4,
          danceability: 0.2,
          tempo: 60,
          acousticness: 0.9,
          instrumentalness: 0.95,
          mode: 0,
        ),
      ),
      Track(
        id: 'mock_sleep_2',
        name: 'Night Whispers',
        artist: 'Dreamscape',
        image: 'https://via.placeholder.com/300/4f46e5/ffffff?text=Sleep+2',
        uri: 'spotify:track:mock_s2',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_sleep_2',
          energy: 0.12,
          valence: 0.35,
          danceability: 0.18,
          tempo: 55,
          acousticness: 0.95,
          instrumentalness: 0.98,
          mode: 0,
        ),
      ),
      Track(
        id: 'mock_sleep_3',
        name: 'Peaceful Slumber',
        artist: 'Calm Nights',
        image: 'https://via.placeholder.com/300/4f46e5/ffffff?text=Sleep+3',
        uri: 'spotify:track:mock_s3',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_sleep_3',
          energy: 0.1,
          valence: 0.3,
          danceability: 0.15,
          tempo: 50,
          acousticness: 0.98,
          instrumentalness: 1.0,
          mode: 0,
        ),
      ),
    ];
  }

  /// Generate romantic tracks
  static List<Track> _generateRomanticTracks() {
    return [
      Track(
        id: 'mock_romantic_1',
        name: 'Love Story',
        artist: 'Romance Band',
        image: 'https://via.placeholder.com/300/f472b6/ffffff?text=Romantic+1',
        uri: 'spotify:track:mock_r1',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_romantic_1',
          energy: 0.45,
          valence: 0.85,
          danceability: 0.6,
          tempo: 100,
          acousticness: 0.6,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_romantic_2',
        name: 'Heartbeat',
        artist: 'Love Notes',
        image: 'https://via.placeholder.com/300/f472b6/ffffff?text=Romantic+2',
        uri: 'spotify:track:mock_r2',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_romantic_2',
          energy: 0.5,
          valence: 0.9,
          danceability: 0.65,
          tempo: 105,
          acousticness: 0.55,
          mode: 1,
        ),
      ),
      Track(
        id: 'mock_romantic_3',
        name: 'Forever Yours',
        artist: 'Sweet Melodies',
        image: 'https://via.placeholder.com/300/f472b6/ffffff?text=Romantic+3',
        uri: 'spotify:track:mock_r3',
        previewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3',
        audioFeatures: AudioFeatures(
          trackId: 'mock_romantic_3',
          energy: 0.48,
          valence: 0.88,
          danceability: 0.58,
          tempo: 98,
          acousticness: 0.65,
          mode: 1,
        ),
      ),
    ];
  }

  /// Добавить трек в избранное
  static Future<void> addToFavorites(Track track) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      final docData = track.toJson();
      docData['added_at'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(track.id)
          .set(docData);
    } catch (e) {
      throw Exception('Ошибка добавления в избранное: $e');
    }
  }

  /// Удалить трек из избранного
  static Future<void> removeFromFavorites(String trackId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(trackId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления из избранного: $e');
    }
  }

  /// Добавить трек в историю прослушиваний
  static Future<void> addToHistory(Track track) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .add({
        'track_id': track.id,
        'track_name': track.name,
        'artist': track.artist,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Удаляем старую историю (храним только последние 50)
      final oldDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      if (oldDocs.docs.length > 50) {
        for (int i = 50; i < oldDocs.docs.length; i++) {
          await oldDocs.docs[i].reference.delete();
        }
      }
    } catch (e) {
      // Не критичная ошибка, просто логируем (ИСПРАВЛЕНО: debugPrint вместо print)
      if (kDebugMode) {
        debugPrint('Warning: Failed to add to history: $e');
      }
    }
  }

  /// Получить актуальный токен (с обновлением если нужно)
  static Future<String?> getValidSpotifyToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final expiresAt = data['token_expires_at'];

      // Проверяем, не протух ли токен
      if (expiresAt != null && expiresAt is Timestamp) {
        final expiry = expiresAt.toDate();
        final now = DateTime.now();

        // Если токен протухает в течение 5 минут - обновляем
        if (now.isAfter(expiry.subtract(const Duration(minutes: 5)))) {
          return await _refreshSpotifyToken(user.uid, data['spotify_refresh_token']);
        }
      }

      return data['spotify_access_token'];
    } catch (e) {
      // ИСПРАВЛЕНО: debugPrint вместо print
      if (kDebugMode) {
        debugPrint('Error getting token: $e');
      }
      return null;
    }
  }

  /// Обновить Spotify токен через refresh token
  static Future<String?> _refreshSpotifyToken(String userId, String refreshToken) async {
    final clientId = ApiConfig.spotifyClientId;
    // NOTE: В продакшене Client Secret должен быть в Cloud Function!

    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'];

        // Сохраняем новый токен
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'spotify_access_token': newAccessToken,
          'token_expires_at': DateTime.now().add(const Duration(hours: 1)),
        });

        return newAccessToken;
      }
    } catch (e) {
      // ИСПРАВЛЕНО: debugPrint вместо print
      if (kDebugMode) {
        debugPrint('Error refreshing token: $e');
      }
    }

    return null;
  }

  /// Fetch audio features for a track from Spotify API
  static Future<AudioFeatures?> getAudioFeatures(String trackId) async {
    try {
      final token = await getClientCredentialsToken();

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/audio-features/$trackId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AudioFeatures.fromJson(data);
      } else {
        debugPrint('Failed to fetch audio features: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching audio features: $e');
      return null;
    }
  }

  /// Fetch audio features for multiple tracks at once
  static Future<Map<String, AudioFeatures>> getMultipleAudioFeatures(
    List<String> trackIds,
  ) async {
    if (trackIds.isEmpty) return {};

    try {
      final token = await getClientCredentialsToken();

      // Spotify API allows up to 100 track IDs
      final ids = trackIds.take(100).join(',');

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/audio-features?ids=$ids'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = <String, AudioFeatures>{};

        for (var item in (data['audio_features'] as List)) {
          if (item != null) {
            final audioFeature = AudioFeatures.fromJson(item);
            features[audioFeature.trackId] = audioFeature;
          }
        }

        return features;
      } else {
        debugPrint('Failed to fetch audio features: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      debugPrint('Error fetching multiple audio features: $e');
      return {};
    }
  }

  /// Search tracks on Spotify
  static Future<List<Track>> searchTracks(String query, {int limit = 20}) async {
    try {
      // Используем Client Credentials token
      final token = await getClientCredentialsToken();

      final encodedQuery = Uri.encodeComponent(query);
      // Добавляем market=US для получения preview URLs
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/search?q=$encodedQuery&type=track&limit=$limit&market=US'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['tracks']['items'] as List;

        final allTracks = items.map((item) {
          final artists = (item['artists'] as List)
              .map((a) => a['name'] as String)
              .join(', ');

          final images = item['album']['images'] as List;
          final imageUrl = images.isNotEmpty ? images[0]['url'] as String : '';

          return Track(
            id: item['id'],
            name: item['name'],
            artist: artists,
            image: imageUrl,
            uri: item['uri'],
            previewUrl: item['preview_url'],
          );
        }).toList();

        // Разделяем на треки с preview и без
        final tracksWithPreview = allTracks.where((t) => t.previewUrl != null && t.previewUrl!.isNotEmpty).toList();
        final tracksWithoutPreview = allTracks.where((t) => t.previewUrl == null || t.previewUrl!.isEmpty).toList();

        debugPrint('✅ Найдено ${items.length} треков для "$query" (${tracksWithPreview.length} с preview, ${tracksWithoutPreview.length} без preview)');

        // Приоритет трекам с preview, но показываем все
        return [...tracksWithPreview, ...tracksWithoutPreview];
      } else {
        debugPrint('❌ Search failed: ${response.statusCode} - ${response.body}');
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error searching tracks: $e');
      rethrow;
    }
  }
}