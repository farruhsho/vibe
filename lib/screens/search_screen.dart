import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/track.dart';
import '../services/spotify_service.dart';
import '../services/user_history_service.dart';
import '../widgets/mini_player.dart';

class SearchScreen extends StatefulWidget {
  final AudioPlayer player;
  final GlobalKey<MiniPlayerState> miniPlayerKey;

  const SearchScreen({
    super.key,
    required this.player,
    required this.miniPlayerKey,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Track> searchResults = [];
  List<String> recentSearches = [];
  bool isSearching = false;
  String selectedFilter = 'all'; // all, track, artist, album

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final searches = await UserHistoryService.getRecentSearches(limit: 10);
    if (mounted) {
      setState(() {
        recentSearches = searches;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      // Сохраняем поисковый запрос в истории
      await UserHistoryService.addSearchQuery(query);

      // Обновляем локальную историю
      await _loadRecentSearches();

      // Поиск через Spotify API с реальными данными
      final results = await SpotifyService.searchTracks(query, limit: 50);

      // Apply filter if needed
      List<Track> filtered = results;
      if (selectedFilter != 'all') {
        // Note: для реальной фильтрации нужно будет добавить type в Track
        filtered = results;
      }

      setState(() {
        searchResults = filtered;
        isSearching = false;
      });
    } catch (e) {
      setState(() {
        isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка поиска: ${e.toString().replaceAll('Exception: ', '')}'),
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
            content: Text('Ошибка воспроизведения: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
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
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Поиск треков, артистов, альбомов...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  searchResults = [];
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length >= 2) {
                        _performSearch(value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Все', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Треки', 'track'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Артисты', 'artist'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Альбомы', 'album'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1DB954),
                      ),
                    )
                  : searchResults.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final track = searchResults[index];
                            return _buildTrackItem(track);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
        if (_searchController.text.isNotEmpty) {
          _performSearch(_searchController.text);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1DB954) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    // Если поле поиска пустое, показываем историю
    if (_searchController.text.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recentSearches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Недавние запросы',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await UserHistoryService.clearSearchHistory();
                      await _loadRecentSearches();
                    },
                    child: const Text(
                      'Очистить',
                      style: TextStyle(color: Color(0xFF1DB954)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...recentSearches.map((query) => ListTile(
                    leading: const Icon(Icons.history, color: Colors.grey),
                    title: Text(
                      query,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                    onTap: () {
                      _searchController.text = query;
                      _performSearch(query);
                    },
                  )),
              const SizedBox(height: 32),
            ],
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 80,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Начните вводить запрос',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Найдите свою любимую музыку',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Если поиск не дал результатов
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          const Text(
            'Ничего не найдено',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте другой запрос',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(Track track) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
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
            // Показываем индикатор preview
            if (track.previewUrl == null || track.previewUrl!.isEmpty)
              Tooltip(
                message: 'Preview недоступен',
                child: Icon(
                  Icons.music_off,
                  color: Colors.grey[600],
                  size: 16,
                ),
              )
            else
              const Tooltip(
                message: 'Preview доступен',
                child: Icon(
                  Icons.music_note,
                  color: Color(0xFF1DB954),
                  size: 16,
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
            IconButton(
              icon: const Icon(Icons.more_vert),
              color: Colors.grey[600],
              onPressed: () => _showTrackOptions(track),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackOptions(Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: Colors.white),
                title: const Text(
                  'Добавить в избранное',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  navigator.pop();
                  try {
                    await SpotifyService.addToFavorites(track);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Добавлено в избранное'),
                          backgroundColor: Color(0xFF1DB954),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Ошибка: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music, color: Colors.white),
                title: const Text(
                  'Добавить в очередь',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Добавлено в очередь')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: const Text(
                  'Поделиться',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
