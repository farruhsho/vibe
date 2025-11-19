import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/mini_player.dart';
import '../services/spotify_service.dart';
import '../models/track.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final player = AudioPlayer();
  final miniPlayerKey = GlobalKey<MiniPlayerState>();
  List<Track> aiTracks = [];
  bool loading = false;
  String? errorMessage;

  final moods = [
    {'name': 'chill', 'icon': Icons.spa, 'color': Colors.blue},
    {'name': 'energetic', 'icon': Icons.flash_on, 'color': Colors.orange},
    {'name': 'happy', 'icon': Icons.sentiment_satisfied, 'color': Colors.yellow},
    {'name': 'focus', 'icon': Icons.psychology, 'color': Colors.purple},
    {'name': 'party', 'icon': Icons.celebration, 'color': Colors.pink},
  ];

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> loadAI(String mood) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final tracks = await SpotifyService.getAIRecommendations(mood);
      setState(() {
        aiTracks = tracks;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $errorMessage'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Повтор',
              onPressed: () => loadAI(mood),
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  void playTrack(Track track) async {
    if (track.previewUrl != null && track.previewUrl!.isNotEmpty) {
      try {
        await player.setUrl(track.previewUrl!);
        await player.play();
        miniPlayerKey.currentState?.setTrack(track);

        // Сохраняем в историю
        await SpotifyService.addToHistory(track);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка воспроизведения: $e')),
          );
        }
      }
    } else {
      // Если нет превью - открываем в Spotify
      final uri = Uri.parse(track.uri);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibe', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          // AI Рекомендации
          _buildAITab(),
          // Избранное
          _buildFavoritesTab(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(player: player, key: miniPlayerKey),
          BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            selectedItemColor: Colors.purple,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome),
                label: 'AI',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Избранное',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAITab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Выбери настроение',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: moods.map((mood) {
                    return ActionChip(
                      avatar: Icon(
                        mood['icon'] as IconData,
                        color: mood['color'] as Color,
                      ),
                      label: Text(
                        (mood['name'] as String)[0].toUpperCase() +
                            (mood['name'] as String).substring(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => loadAI(mood['name'] as String),
                      // ИСПРАВЛЕНО: withOpacity → withValues
                      backgroundColor: (mood['color'] as Color).withValues(alpha: 0.2),
                      side: BorderSide(color: mood['color'] as Color),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        if (loading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (errorMessage != null)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else if (aiTracks.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'Выбери настроение выше\nдля AI-рекомендаций',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) {
                  final track = aiTracks[i];
                  return _buildTrackTile(track, showScore: true);
                },
                childCount: aiTracks.length,
              ),
            ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Не авторизован'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .orderBy('added_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Избранное пусто\n❤️ добавляй треки из AI-рекомендаций',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final track = Track.fromJson(data);
            return _buildTrackTile(track, isFavorite: true, docId: docs[i].id);
          },
        );
      },
    );
  }

  Widget _buildTrackTile(Track track, {bool showScore = false, bool isFavorite = false, String? docId}) {
    return ListTile(
      leading: track.image.isNotEmpty
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          track.image,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 56,
              height: 56,
              color: Colors.grey,
              child: const Icon(Icons.music_note),
            );
          },
        ),
      )
          : Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note),
      ),
      title: Text(
        track.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (showScore && track.score != null)
            Text(
              '${(track.score! * 100).round()}% совпадение',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isFavorite)
            IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () async {
                await SpotifyService.addToFavorites(track);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Добавлено в избранное ❤️'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (docId != null) {
                  await SpotifyService.removeFromFavorites(docId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Удалено из избранного'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                }
              },
            ),
          IconButton(
            icon: Icon(
              track.previewUrl != null && track.previewUrl!.isNotEmpty
                  ? Icons.play_arrow
                  : Icons.open_in_new,
            ),
            onPressed: () => playTrack(track),
          ),
        ],
      ),
    );
  }
}