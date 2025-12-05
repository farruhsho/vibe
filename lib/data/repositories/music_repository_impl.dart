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
      final tracks = await _apiDatasource.searchTracks(query, limit: limit);

      return Result.success(SearchResult(
        tracks: tracks.map((t) => t.toEntity()).toList(),
        total: tracks.length,
        offset: offset,
        limit: limit,
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
    // Not implemented in current datasource - return empty list
    return const Result.success([]);
  }

  @override
  Future<Result<List<Album>, Failure>> searchAlbums({
    required String query,
    int limit = 20,
  }) async {
    // Not implemented in current datasource - return empty list
    return const Result.success([]);
  }

  @override
  Future<Result<List<Playlist>, Failure>> searchPlaylists({
    required String query,
    int limit = 20,
  }) async {
    // Not implemented in current datasource - return empty list
    return const Result.success([]);
  }

  // ============== TRACKS ==============

  @override
  Future<Result<Track, Failure>> getTrack(String trackId) async {
    try {
      final track = await _apiDatasource.getTrack(trackId);
      return Result.success(track.toEntity());
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
      final tracks = await _apiDatasource.getTracks(trackIds);
      return Result.success(tracks.map((t) => t.toEntity()).toList());
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
      final features = await _apiDatasource.getAudioFeatures(trackId);
      return Result.success(features.toEntity());
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
      final features = await _apiDatasource.getMultipleAudioFeatures(trackIds);
      return Result.success(features.map((f) => f.toEntity()).toList());
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
    // Not implemented in current datasource
    return Result.error(SpotifyApiFailure('Artist lookup not implemented'));
  }

  @override
  Future<Result<List<Track>, Failure>> getArtistTopTracks(String artistId) async {
    // Not implemented in current datasource
    return const Result.success([]);
  }

  @override
  Future<Result<List<Artist>, Failure>> getRelatedArtists(String artistId) async {
    // Not implemented in current datasource
    return const Result.success([]);
  }

  // ============== ALBUMS ==============

  @override
  Future<Result<Album, Failure>> getAlbum(String albumId) async {
    // Not implemented in current datasource
    return Result.error(SpotifyApiFailure('Album lookup not implemented'));
  }

  @override
  Future<Result<List<Track>, Failure>> getAlbumTracks(String albumId) async {
    // Not implemented in current datasource
    return const Result.success([]);
  }

  // ============== PLAYLISTS ==============

  @override
  Future<Result<Playlist, Failure>> getPlaylist(String playlistId) async {
    // Not implemented in current datasource
    return Result.error(SpotifyApiFailure('Playlist lookup not implemented'));
  }

  @override
  Future<Result<List<Track>, Failure>> getPlaylistTracks(
    String playlistId, {
    int limit = 100,
    int offset = 0,
  }) async {
    // Not implemented in current datasource
    return const Result.success([]);
  }

  // ============== USER LIBRARY ==============

  @override
  Future<Result<List<Track>, Failure>> getSavedTracks({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final tracks = await _apiDatasource.getSavedTracks(
        limit: limit,
        offset: offset,
      );
      return Result.success(tracks.map((t) => t.toEntity()).toList());
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
      await _apiDatasource.removeTracks(trackIds);
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
      final savedMap = await _apiDatasource.checkSavedTracks(trackIds);
      // Convert map to list maintaining order
      final results = trackIds.map((id) => savedMap[id] ?? false).toList();
      return Result.success(results);
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
    // Not implemented in current datasource
    return const Result.success([]);
  }

  @override
  Future<Result<List<Track>, Failure>> getRecentlyPlayed({int limit = 50}) async {
    try {
      final tracks = await _apiDatasource.getRecentlyPlayed(limit: limit);
      return Result.success(tracks.map((t) => t.toEntity()).toList());
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
      final tracks = await _apiDatasource.getTopTracks(
        timeRange: timeRange,
        limit: limit,
      );
      return Result.success(tracks.map((t) => t.toEntity()).toList());
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
    // Not implemented in current datasource
    return const Result.success([]);
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
      final tracks = await _apiDatasource.getRecommendations(
        seedTracks: seedTracks,
        seedArtists: seedArtists,
        seedGenres: seedGenres,
        limit: limit,
        targetEnergy: targetAudioFeatures?['energy'] as double?,
        targetValence: targetAudioFeatures?['valence'] as double?,
        targetDanceability: targetAudioFeatures?['danceability'] as double?,
        targetTempo: targetAudioFeatures?['tempo'] as double?,
      );
      return Result.success(tracks.map((t) => t.toEntity()).toList());
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
    // Not implemented in current datasource - return common genres
    return const Result.success([
      'acoustic', 'afrobeat', 'alt-rock', 'alternative', 'ambient',
      'anime', 'black-metal', 'bluegrass', 'blues', 'bossanova',
      'brazil', 'breakbeat', 'british', 'cantopop', 'chicago-house',
      'children', 'chill', 'classical', 'club', 'comedy',
      'country', 'dance', 'dancehall', 'death-metal', 'deep-house',
      'disco', 'disney', 'drum-and-bass', 'dub', 'dubstep',
      'edm', 'electro', 'electronic', 'emo', 'folk',
      'forro', 'french', 'funk', 'garage', 'german',
      'gospel', 'goth', 'grindcore', 'groove', 'grunge',
      'guitar', 'happy', 'hard-rock', 'hardcore', 'hardstyle',
      'heavy-metal', 'hip-hop', 'holidays', 'honky-tonk', 'house',
      'idm', 'indian', 'indie', 'indie-pop', 'industrial',
      'iranian', 'j-dance', 'j-idol', 'j-pop', 'j-rock',
      'jazz', 'k-pop', 'kids', 'latin', 'latino',
      'malay', 'mandopop', 'metal', 'metal-misc', 'metalcore',
      'minimal-techno', 'movies', 'mpb', 'new-age', 'new-release',
      'opera', 'pagode', 'party', 'philippines-opm', 'piano',
      'pop', 'pop-film', 'post-dubstep', 'power-pop', 'progressive-house',
      'psych-rock', 'punk', 'punk-rock', 'r-n-b', 'rainy-day',
      'reggae', 'reggaeton', 'road-trip', 'rock', 'rock-n-roll',
      'rockabilly', 'romance', 'sad', 'salsa', 'samba',
      'sertanejo', 'show-tunes', 'singer-songwriter', 'ska', 'sleep',
      'songwriter', 'soul', 'soundtracks', 'spanish', 'study',
      'summer', 'swedish', 'synth-pop', 'tango', 'techno',
      'trance', 'trip-hop', 'turkish', 'work-out', 'world-music',
    ]);
  }
}
