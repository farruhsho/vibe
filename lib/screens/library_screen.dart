import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../widgets/mini_player.dart';
import 'genres_screen.dart';

class LibraryScreen extends StatefulWidget {
  final AudioPlayer player;
  final GlobalKey<MiniPlayerState> miniPlayerKey;

  const LibraryScreen({
    super.key,
    required this.player,
    required this.miniPlayerKey,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Библиотека',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF1DB954),
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF1DB954),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Жанры'),
                      Tab(text: 'Избранное'),
                      Tab(text: 'История'),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGenresTab(),
                  _buildFavoritesTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenresTab() {
    final genres = [
      {
        'name': 'Электроника',
        'icon': Icons.electric_bolt,
        'color': const Color(0xFF667eea),
        'count': '120 треков',
      },
      {
        'name': 'Рок',
        'icon': Icons.music_note,
        'color': const Color(0xFFf97316),
        'count': '85 треков',
      },
      {
        'name': 'Поп',
        'icon': Icons.star,
        'color': const Color(0xFFec4899),
        'count': '200 треков',
      },
      {
        'name': 'Хип-хоп',
        'icon': Icons.headphones,
        'color': const Color(0xFFfbbf24),
        'count': '95 треков',
      },
      {
        'name': 'Джаз',
        'icon': Icons.piano,
        'color': const Color(0xFF8b5cf6),
        'count': '45 треков',
      },
      {
        'name': 'Классика',
        'icon': Icons.music_video,
        'color': const Color(0xFF06b6d4),
        'count': '60 треков',
      },
      {
        'name': 'R&B',
        'icon': Icons.audiotrack,
        'color': const Color(0xFFef4444),
        'count': '75 треков',
      },
      {
        'name': 'Ambient',
        'icon': Icons.spa,
        'color': const Color(0xFF10b981),
        'count': '50 треков',
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GenresScreen(
                  genreName: genre['name'] as String,
                  player: widget.player,
                  miniPlayerKey: widget.miniPlayerKey,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  genre['color'] as Color,
                  (genre['color'] as Color).withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (genre['color'] as Color).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    genre['icon'] as IconData,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        genre['icon'] as IconData,
                        color: Colors.white,
                        size: 32,
                      ),
                      const Spacer(),
                      Text(
                        genre['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        genre['count'] as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет избранных треков',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Треки, которые вам понравятся\nпоявятся здесь',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'История пуста',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ваши прослушанные треки\nбудут отображаться здесь',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
