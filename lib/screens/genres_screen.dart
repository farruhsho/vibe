import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/track.dart';
import '../services/spotify_service.dart';
import '../widgets/mini_player.dart';

class GenresScreen extends StatefulWidget {
  final String genreName;
  final AudioPlayer player;
  final GlobalKey<MiniPlayerState> miniPlayerKey;

  const GenresScreen({
    super.key,
    required this.genreName,
    required this.player,
    required this.miniPlayerKey,
  });

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  List<Track> tracks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGenreTracks();
  }

  Future<void> _loadGenreTracks() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Поиск треков через Spotify API по названию жанра
      final results = await SpotifyService.searchTracks(widget.genreName, limit: 30);

      setState(() {
        tracks = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _playTrack(Track track) async {
    if (track.previewUrl == null || track.previewUrl!.isEmpty) {
      if (mounted) {
        _showNoPreviewDialog(track);
      }
      return;
    }

    try {
      await widget.player.stop();
      await widget.player.setUrl(track.previewUrl!);
      await widget.player.play();
      if (mounted) {
        widget.miniPlayerKey.currentState?.setTrack(track);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка воспроизведения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNoPreviewDialog(Track track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Preview недоступен',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Для трека "${track.name}" preview не доступен.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              'Это ограничение Spotify API - не все треки имеют 30-секундный preview.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              final url = 'https://open.spotify.com/track/${track.id}';
              try {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Не удалось открыть Spotify: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Открыть в Spotify'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1E1E1E),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.genreName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getGenreColor(),
                      const Color(0xFF121212),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getGenreIcon(),
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),

          // Track list
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1DB954),
                ),
              ),
            )
          else if (tracks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_off,
                      size: 80,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Треки не найдены',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = tracks[index];
                    return _buildTrackItem(track, index);
                  },
                  childCount: tracks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(Track track, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.image.isNotEmpty
                  ? Image.network(
                      track.image,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.grey),
                    ),
            ),
          ],
        ),
        title: Text(
          track.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artist,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (track.previewUrl == null || track.previewUrl!.isEmpty)
              Tooltip(
                message: 'Preview недоступен',
                child: Icon(
                  Icons.music_off,
                  color: Colors.grey[600],
                  size: 14,
                ),
              )
            else
              const Tooltip(
                message: 'Preview доступен',
                child: Icon(
                  Icons.music_note,
                  color: Color(0xFF1DB954),
                  size: 14,
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                track.previewUrl != null && track.previewUrl!.isNotEmpty
                    ? Icons.play_circle_filled
                    : Icons.open_in_new,
              ),
              color: const Color(0xFF1DB954),
              iconSize: 32,
              tooltip: track.previewUrl != null && track.previewUrl!.isNotEmpty
                  ? 'Воспроизвести preview'
                  : 'Открыть в Spotify',
              onPressed: () => _playTrack(track),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGenreColor() {
    switch (widget.genreName.toLowerCase()) {
      case 'электроника':
        return const Color(0xFF667eea);
      case 'рок':
        return const Color(0xFFf97316);
      case 'поп':
        return const Color(0xFFec4899);
      case 'хип-хоп':
        return const Color(0xFFfbbf24);
      case 'джаз':
        return const Color(0xFF8b5cf6);
      case 'классика':
        return const Color(0xFF06b6d4);
      case 'r&b':
        return const Color(0xFFef4444);
      case 'ambient':
        return const Color(0xFF10b981);
      default:
        return const Color(0xFF667eea);
    }
  }

  IconData _getGenreIcon() {
    switch (widget.genreName.toLowerCase()) {
      case 'электроника':
        return Icons.electric_bolt;
      case 'рок':
        return Icons.music_note;
      case 'поп':
        return Icons.star;
      case 'хип-хоп':
        return Icons.headphones;
      case 'джаз':
        return Icons.piano;
      case 'классика':
        return Icons.music_video;
      case 'r&b':
        return Icons.audiotrack;
      case 'ambient':
        return Icons.spa;
      default:
        return Icons.music_note;
    }
  }
}
