/// Music Repository Implementation
///
/// Implements the MusicRepository interface using the Spotify API datasource.

import '../../domain/repositories/music_repository.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/audio_features.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../datasources/remote/spotify_api_datasource.dart';
import '../models/track_model.dart';
import '../models/audio_features_model.dart';

class MusicRepositoryImpl implements MusicRepository {
  final SpotifyApiDatasource _apiDatasource;

  MusicRepositoryImpl({required SpotifyApiDatasource apiDatasource})
      : _apiDatasource = apiDatasource;

  // ============== SEARCH ==============

  @override
  Future<Result<SearchResult, Failure>> searchTracks({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiDatasource.search(
        query: query,
        type: 'track',
        limit: limit,
        offset: offset,
      );

      final tracksData = response['tracks'] as Map<String, dynamic>;
      final items = tracksData['items'] as List;
      final tracks = items
          .map((item) => TrackModel.fromSpotifyJson(item).toEntity())
          .toList();

      return Result.success(SearchResult(
        tracks: tracks,
        total: tracksData['total'] as int,
        offset: tracksData['offset'] as int,
        limit: tracksData['limit'] as int,
      ));
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to search tracks: $e'));
    }
  }

  @override
  Future<Result<List<Artist>, Failure>> searchArtists({
    required String query,
    int limit = 20,
  }) async {
    try {
      final response = await _apiDatasource.search(
        query: query,
        type: 'artist',
        limit: limit,
      );

      final artistsData = response['artists'] as Map<String, dynamic>;
      final items = artistsData['items'] as List;
      final artists = items.map((item) => _mapArtist(item)).toList();

      return Result.success(artists);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to search artists: $e'));
    }
  }

  @override
  Future<Result<List<Album>, Failure>> searchAlbums({
    required String query,
    int limit = 20,
  }) async {
    try {
      final response = await _apiDatasource.search(
        query: query,
        type: 'album',
        limit: limit,
      );

      final albumsData = response['albums'] as Map<String, dynamic>;
      final items = albumsData['items'] as List;
      final albums = items.map((item) => _mapAlbum(item)).toList();

      return Result.success(albums);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to search albums: $e'));
    }
  }

  @override
  Future<Result<List<Playlist>, Failure>> searchPlaylists({
    required String query,
    int limit = 20,
  }) async {
    try {
      final response = await _apiDatasource.search(
        query: query,
        type: 'playlist',
        limit: limit,
      );

      final playlistsData = response['playlists'] as Map<String, dynamic>;
      final items = playlistsData['items'] as List;
      final playlists =
          items.where((item) => item != null).map((item) => _mapPlaylist(item)).toList();

      return Result.success(playlists);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to search playlists: $e'));
    }
  }

  // ============== TRACKS ==============

  @override
  Future<Result<Track, Failure>> getTrack(String trackId) async {
    try {
      final response = await _apiDatasource.getTrack(trackId);
      final track = TrackModel.fromSpotifyJson(response).toEntity();
      return Result.success(track);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get track: $e'));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getTracks(List<String> trackIds) async {
    if (trackIds.isEmpty) return const Result.success([]);

    try {
      final response = await _apiDatasource.getTracks(trackIds);
      final items = response['tracks'] as List;
      final tracks = items
          .where((item) => item != null)
          .map((item) => TrackModel.fromSpotifyJson(item).toEntity())
          .toList();

      return Result.success(tracks);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get tracks: $e'));
    }
  }

  @override
  Future<Result<AudioFeatures, Failure>> getAudioFeatures(String trackId) async {
    try {
      final response = await _apiDatasource.getAudioFeatures(trackId);
      final features = AudioFeaturesModel.fromJson(response).toEntity();
      return Result.success(features);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get audio features: $e'));
    }
  }

  @override
  Future<Result<List<AudioFeatures>, Failure>> getMultipleAudioFeatures(
    List<String> trackIds,
  ) async {
    if (trackIds.isEmpty) return const Result.success([]);

    try {
      final response = await _apiDatasource.getMultipleAudioFeatures(trackIds);
      final items = response['audio_features'] as List;
      final features = items
          .where((item) => item != null)
          .map((item) => AudioFeaturesModel.fromJson(item).toEntity())
          .toList();

      return Result.success(features);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get audio features: $e'));
    }
  }

  // ============== ARTISTS ==============

  @override
  Future<Result<Artist, Failure>> getArtist(String artistId) async {
    try {
      final response = await _apiDatasource.getArtist(artistId);
      return Result.success(_mapArtist(response));
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get artist: $e'));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getArtistTopTracks(String artistId) async {
    try {
      final response = await _apiDatasource.getArtistTopTracks(artistId);
      final items = response['tracks'] as List;
      final tracks = items
          .map((item) => TrackModel.fromSpotifyJson(item).toEntity())
          .toList();

      return Result.success(tracks);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get artist top tracks: $e'));
    }
  }

  @override
  Future<Result<List<Artist>, Failure>> getRelatedArtists(String artistId) async {
    try {
      final response = await _apiDatasource.getRelatedArtists(artistId);
      final items = response['artists'] as List;
      final artists = items.map((item) => _mapArtist(item)).toList();

      return Result.success(artists);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get related artists: $e'));
    }
  }

  // ============== ALBUMS ==============

  @override
  Future<Result<Album, Failure>> getAlbum(String albumId) async {
    try {
      final response = await _apiDatasource.getAlbum(albumId);
      return Result.success(_mapAlbum(response));
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get album: $e'));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getAlbumTracks(String albumId) async {
    try {
      final response = await _apiDatasource.getAlbumTracks(albumId);
      final items = response['items'] as List;
      final tracks = items
          .map((item) => TrackModel.fromSpotifyJson(item).toEntity())
          .toList();

      return Result.success(tracks);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get album tracks: $e'));
    }
  }

  // ============== PLAYLISTS ==============

  @override
  Future<Result<Playlist, Failure>> getPlaylist(String playlistId) async {
    try {
      final response = await _apiDatasource.getPlaylist(playlistId);
      return Result.success(_mapPlaylist(response));
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get playlist: $e'));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getPlaylistTracks(
    String playlistId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _apiDatasource.getPlaylistTracks(
        playlistId,
        limit: limit,
        offset: offset,
      );

      final items = response['items'] as List;
      final tracks = items
          .where((item) => item['track'] != null)
          .map((item) => TrackModel.fromSpotifyJson(item['track']).toEntity())
          .toList();

      return Result.success(tracks);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get playlist tracks: $e'));
    }
  }

  // ============== USER LIBRARY ==============

  @override
  Future<Result<List<Track>, Failure>> getSavedTracks({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiDatasource.getSavedTracks(
        limit: limit,
        offset: offset,
      );

      final items = response['items'] as List;
      final tracks = items
          .where((item) => item['track'] != null)
          .map((item) => TrackModel.fromSpotifyJson(item['track']).toEntity())
          .toList();

      return Result.success(tracks);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get saved tracks: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> saveTracks(List<String> trackIds) async {
    if (trackIds.isEmpty) return const Result.success(null);

    try {
      await _apiDatasource.saveTracks(trackIds);
      return const Result.success(null);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to save tracks: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> removeSavedTracks(List<String> trackIds) async {
    if (trackIds.isEmpty) return const Result.success(null);

    try {
      await _apiDatasource.removeSavedTracks(trackIds);
      return const Result.success(null);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to remove tracks: $e'));
    }
  }

  @override
  Future<Result<List<bool>, Failure>> checkSavedTracks(List<String> trackIds) async {
    if (trackIds.isEmpty) return const Result.success([]);

    try {
      final response = await _apiDatasource.checkSavedTracks(trackIds);
      return Result.success(List<bool>.from(response));
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to check saved tracks: $e'));
    }
  }

  @override
  Future<Result<List<Playlist>, Failure>> getUserPlaylists({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiDatasource.getCurrentUserPlaylists(
        limit: limit,
        offset: offset,
      );

      final items = response['items'] as List;
      final playlists =
          items.where((item) => item != null).map((item) => _mapPlaylist(item)).toList();

      return Result.success(playlists);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get playlists: $e'));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getRecentlyPlayed({int limit = 50}) async {
    try {
      final response = await _apiDatasource.getRecentlyPlayed(limit: limit);

      final items = response['items'] as List;
      final tracks = items
          .where((item) => item['track'] != null)
          .map((item) => TrackModel.fromSpotifyJson(item['track']).toEntity())
          .toList();

      return Result.success(tracks);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get recently played: $e'));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getTopTracks({
    String timeRange = 'medium_term',
    int limit = 50,
  }) async {
    try {
      final response = await _apiDatasource.getTopTracks(
        timeRange: timeRange,
        limit: limit,
      );

      final items = response['items'] as List;
      final tracks = items
          .map((item) => TrackModel.fromSpotifyJson(item).toEntity())
          .toList();

      return Result.success(tracks);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get top tracks: $e'));
    }
  }

  @override
  Future<Result<List<Artist>, Failure>> getTopArtists({
    String timeRange = 'medium_term',
    int limit = 50,
  }) async {
    try {
      final response = await _apiDatasource.getTopArtists(
        timeRange: timeRange,
        limit: limit,
      );

      final items = response['items'] as List;
      final artists = items.map((item) => _mapArtist(item)).toList();

      return Result.success(artists);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get top artists: $e'));
    }
  }

  // ============== RECOMMENDATIONS ==============

  @override
  Future<Result<List<Track>, Failure>> getRecommendations({
    List<String>? seedTracks,
    List<String>? seedArtists,
    List<String>? seedGenres,
    int limit = 20,
    Map<String, dynamic>? targetAudioFeatures,
  }) async {
    try {
      final response = await _apiDatasource.getRecommendations(
        seedTracks: seedTracks,
        seedArtists: seedArtists,
        seedGenres: seedGenres,
        limit: limit,
        targetAudioFeatures: targetAudioFeatures,
      );

      final items = response['tracks'] as List;
      final tracks = items
          .map((item) => TrackModel.fromSpotifyJson(item).toEntity())
          .toList();

      return Result.success(tracks);
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get recommendations: $e'));
    }
  }

  @override
  Future<Result<List<String>, Failure>> getAvailableGenreSeeds() async {
    try {
      final response = await _apiDatasource.getAvailableGenreSeeds();
      return Result.success(List<String>.from(response['genres']));
    } on SpotifyException catch (e) {
      return Result.error(SpotifyApiFailure(e.message));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(UnknownFailure('Failed to get genre seeds: $e'));
    }
  }

  // ============== HELPERS ==============

  Artist _mapArtist(Map<String, dynamic> json) {
    final images = json['images'] as List? ?? [];
    return Artist(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrls: images.map((img) => img['url'] as String).toList(),
      genres: List<String>.from(json['genres'] ?? []),
      popularity: json['popularity'] as int? ?? 0,
      followers: json['followers']?['total'] as int? ?? 0,
    );
  }

  Album _mapAlbum(Map<String, dynamic> json) {
    final images = json['images'] as List? ?? [];
    final artists = json['artists'] as List? ?? [];

    DateTime? releaseDate;
    final releaseDateStr = json['release_date'] as String?;
    if (releaseDateStr != null) {
      try {
        releaseDate = DateTime.parse(releaseDateStr);
      } catch (_) {
        // Handle partial dates like "2021" or "2021-03"
      }
    }

    return Album(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: images.isNotEmpty ? images.first['url'] as String : null,
      artists: artists.map((a) => _mapArtist(a)).toList(),
      albumType: json['album_type'] as String? ?? 'album',
      releaseDate: releaseDate,
      totalTracks: json['total_tracks'] as int? ?? 0,
    );
  }

  Playlist _mapPlaylist(Map<String, dynamic> json) {
    final images = json['images'] as List? ?? [];
    final owner = json['owner'] as Map<String, dynamic>;
    final tracks = json['tracks'] as Map<String, dynamic>?;

    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: images.isNotEmpty ? images.first['url'] as String : null,
      ownerId: owner['id'] as String,
      ownerName: owner['display_name'] as String? ?? owner['id'] as String,
      totalTracks: tracks?['total'] as int? ?? 0,
      isPublic: json['public'] as bool? ?? true,
      isCollaborative: json['collaborative'] as bool? ?? false,
    );
  }
}
