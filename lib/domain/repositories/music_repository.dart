/// Music Repository Interface
///
/// Defines the contract for all music-related operations.
/// This includes searching, fetching tracks, and managing user library.

import '../entities/track.dart';
import '../entities/audio_features.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';

/// Search result containing tracks and pagination info
class SearchResult {
  final List<Track> tracks;
  final int total;
  final int offset;
  final int limit;
  final bool hasMore;

  const SearchResult({
    required this.tracks,
    required this.total,
    this.offset = 0,
    this.limit = 20,
  }) : hasMore = offset + tracks.length < total;

  int get nextOffset => offset + limit;
}

/// Artist entity for domain layer
class Artist {
  final String id;
  final String name;
  final List<String> imageUrls;
  final List<String> genres;
  final int popularity;
  final int followers;

  const Artist({
    required this.id,
    required this.name,
    this.imageUrls = const [],
    this.genres = const [],
    this.popularity = 0,
    this.followers = 0,
  });

  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;
}

/// Album entity for domain layer
class Album {
  final String id;
  final String name;
  final String? imageUrl;
  final List<Artist> artists;
  final String albumType;
  final DateTime? releaseDate;
  final int totalTracks;

  const Album({
    required this.id,
    required this.name,
    this.imageUrl,
    this.artists = const [],
    this.albumType = 'album',
    this.releaseDate,
    this.totalTracks = 0,
  });

  String get artistNames => artists.map((a) => a.name).join(', ');
}

/// Playlist entity for domain layer
class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String ownerId;
  final String ownerName;
  final int totalTracks;
  final bool isPublic;
  final bool isCollaborative;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    this.totalTracks = 0,
    this.isPublic = true,
    this.isCollaborative = false,
  });
}

/// Music repository interface
abstract class MusicRepository {
  // ============== SEARCH ==============

  /// Search for tracks
  Future<Result<SearchResult, Failure>> searchTracks({
    required String query,
    int limit = 20,
    int offset = 0,
  });

  /// Search for artists
  Future<Result<List<Artist>, Failure>> searchArtists({
    required String query,
    int limit = 20,
  });

  /// Search for albums
  Future<Result<List<Album>, Failure>> searchAlbums({
    required String query,
    int limit = 20,
  });

  /// Search for playlists
  Future<Result<List<Playlist>, Failure>> searchPlaylists({
    required String query,
    int limit = 20,
  });

  // ============== TRACKS ==============

  /// Get track by ID
  Future<Result<Track, Failure>> getTrack(String trackId);

  /// Get multiple tracks by IDs
  Future<Result<List<Track>, Failure>> getTracks(List<String> trackIds);

  /// Get audio features for a track
  Future<Result<AudioFeatures, Failure>> getAudioFeatures(String trackId);

  /// Get audio features for multiple tracks
  Future<Result<List<AudioFeatures>, Failure>> getMultipleAudioFeatures(
    List<String> trackIds,
  );

  // ============== ARTISTS ==============

  /// Get artist by ID
  Future<Result<Artist, Failure>> getArtist(String artistId);

  /// Get artist's top tracks
  Future<Result<List<Track>, Failure>> getArtistTopTracks(String artistId);

  /// Get related artists
  Future<Result<List<Artist>, Failure>> getRelatedArtists(String artistId);

  // ============== ALBUMS ==============

  /// Get album by ID
  Future<Result<Album, Failure>> getAlbum(String albumId);

  /// Get album tracks
  Future<Result<List<Track>, Failure>> getAlbumTracks(String albumId);

  // ============== PLAYLISTS ==============

  /// Get playlist by ID
  Future<Result<Playlist, Failure>> getPlaylist(String playlistId);

  /// Get playlist tracks
  Future<Result<List<Track>, Failure>> getPlaylistTracks(
    String playlistId, {
    int limit = 100,
    int offset = 0,
  });

  // ============== USER LIBRARY ==============

  /// Get user's saved tracks
  Future<Result<List<Track>, Failure>> getSavedTracks({
    int limit = 50,
    int offset = 0,
  });

  /// Save tracks to user's library
  Future<Result<void, Failure>> saveTracks(List<String> trackIds);

  /// Remove tracks from user's library
  Future<Result<void, Failure>> removeSavedTracks(List<String> trackIds);

  /// Check if tracks are saved
  Future<Result<List<bool>, Failure>> checkSavedTracks(List<String> trackIds);

  /// Get user's playlists
  Future<Result<List<Playlist>, Failure>> getUserPlaylists({
    int limit = 50,
    int offset = 0,
  });

  /// Get user's recently played tracks
  Future<Result<List<Track>, Failure>> getRecentlyPlayed({int limit = 50});

  /// Get user's top tracks
  Future<Result<List<Track>, Failure>> getTopTracks({
    String timeRange = 'medium_term',
    int limit = 50,
  });

  /// Get user's top artists
  Future<Result<List<Artist>, Failure>> getTopArtists({
    String timeRange = 'medium_term',
    int limit = 50,
  });

  // ============== RECOMMENDATIONS ==============

  /// Get Spotify recommendations based on seeds
  Future<Result<List<Track>, Failure>> getRecommendations({
    List<String>? seedTracks,
    List<String>? seedArtists,
    List<String>? seedGenres,
    int limit = 20,
    Map<String, dynamic>? targetAudioFeatures,
  });

  /// Get available genre seeds
  Future<Result<List<String>, Failure>> getAvailableGenreSeeds();
}
