import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/mini_player.dart';
import '../widgets/rating_dialog.dart';
import '../services/spotify_service.dart';
import '../services/pattern_analyzer.dart';
import '../services/user_history_service.dart';
import '../models/track.dart';
import '../models/user_pattern.dart';
import '../models/mood_categories.dart';
import 'analytics_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'spotify_connect_screen.dart';

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
  List<Track> spotifyRecommendations = [];
  bool loading = false;
  bool loadingRecommendations = false;
  String? errorMessage;
  UserPattern? userPattern;

  // Используем первые 20 категорий для отображения
  List<MoodCategory> get displayedMoods => MoodCategories.all.take(20).toList();

  @override
  void initState() {
    super.initState();
    _loadSpotifyRecommendations();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> _loadSpotifyRecommendations() async {
    setState(() {
      loadingRecommendations = true;
    });

    try {
      // Получаем популярные треки и рекомендации
      final recommendations = await SpotifyService.getPopularRecommendations();
      setState(() {
        spotifyRecommendations = recommendations;
        loadingRecommendations = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки рекомендаций: $e');
      setState(() {
        loadingRecommendations = false;
      });
    }
  }

  Future<void> loadAI(String mood) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      // Сохраняем выбор настроения в истории
      await UserHistoryService.addMoodSelection(mood);

      final tracks = await SpotifyService.getAIRecommendations(mood);
      setState(() {
        aiTracks = tracks;
        loading = false;
      });

      // Автоматически воспроизвести первый трек с preview и установить очередь
      if (tracks.isNotEmpty && mounted) {
        // Filter tracks with preview URLs
        final tracksWithPreview = tracks.where(
          (t) => t.previewUrl != null && t.previewUrl!.isNotEmpty,
        ).toList();

        final tracksWithoutPreview = tracks.length - tracksWithPreview.length;

        if (tracksWithPreview.isNotEmpty) {
          try {
            await player.stop();
            await player.setUrl(tracksWithPreview.first.previewUrl!);

            // Set the queue in mini player
            miniPlayerKey.currentState?.setQueue(tracksWithPreview, startIndex: 0);

            await player.play();

            debugPrint('🎵 Автовоспроизведение: ${tracksWithPreview.first.name}');
            debugPrint('🎵 Очередь: ${tracksWithPreview.length} треков с preview, ${tracksWithoutPreview} без');

            if (mounted) {
              String message = '🎵 ${tracks.length} треков';
              if (tracksWithPreview.isNotEmpty) {
                message += ' (${tracksWithPreview.length} с превью)';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF1DB954),
                ),
              );
            }
          } catch (e) {
            debugPrint('⚠️ Ошибка автовоспроизведения: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ Ошибка: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          // Все треки без превью, но показываем их всё равно
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📱 Найдено ${tracks.length} треков. Нажмите на трек чтобы открыть в Spotify.'),
                backgroundColor: const Color(0xFF1DB954),
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () {},
                  textColor: Colors.white,
                ),
              ),
            );
          }
        }
      }
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

        // Find track index in current list and set queue
        final trackIndex = aiTracks.indexOf(track);
        if (trackIndex != -1) {
          final tracksWithPreview = aiTracks.where(
            (t) => t.previewUrl != null && t.previewUrl!.isNotEmpty,
          ).toList();
          final queueIndex = tracksWithPreview.indexOf(track);
          if (queueIndex != -1) {
            miniPlayerKey.currentState?.setQueue(tracksWithPreview, startIndex: queueIndex);
          } else {
            miniPlayerKey.currentState?.setTrack(track);
          }
        } else {
          miniPlayerKey.currentState?.setTrack(track);
        }

        // Fetch audio features if not present
        var audioFeatures = track.audioFeatures ?? await SpotifyService.getAudioFeatures(track.id);

        // Save to listening history with audio features
        if (audioFeatures != null) {
          await PatternAnalyzer.addToListeningHistory(
            trackId: track.id,
            trackName: track.name,
            artist: track.artist,
            audioFeatures: audioFeatures,
          );
        }

        // Show rating dialog after playing (for research data)
        if (track.score != null && track.score! > 0) {
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) {
              showRatingDialog(context, track);
            }
          });
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
    } else {
      // Если нет превью - открываем в Spotify
      try {
        final uri = Uri.parse(track.uri);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Не удается открыть трек в Spotify'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
            icon: const Icon(Icons.album, color: Color(0xFF1DB954)),
            tooltip: 'Подключить Spotify',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SpotifyConnectScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Аналитика',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
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
          // Поиск
          SearchScreen(player: player, miniPlayerKey: miniPlayerKey),
          // Библиотека
          LibraryScreen(player: player, miniPlayerKey: miniPlayerKey),
          // Аналитика
          const AnalyticsScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(player: player, key: miniPlayerKey),
          BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            selectedItemColor: const Color(0xFF1DB954),
            unselectedItemColor: Colors.grey,
            backgroundColor: const Color(0xFF1E1E1E),
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome),
                label: 'Главная',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Поиск',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Библиотека',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Аналитика',
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
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Категории по настроению',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
                const SizedBox(height: 20),

                // Горизонтальные категории-кружочки
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: MoodCategories.all.length,
                    itemBuilder: (context, index) {
                      final mood = MoodCategories.all[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            // Кружок с иконкой
                            GestureDetector(
                              onTap: () => loadAI(mood.name),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      mood.color,
                                      mood.color.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: mood.color.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        mood.icon,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                    // Кнопка Play в углу
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => loadAI(mood.name),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.play_arrow,
                                            color: mood.color,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Название
                            SizedBox(
                              width: 100,
                              child: Text(
                                mood.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Рекомендуемая музыка от Spotify
                const Text(
                  'Рекомендуем для вас',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // Горизонтальный список рекомендаций
        if (loadingRecommendations)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFF1DB954)),
              ),
            ),
          )
        else if (spotifyRecommendations.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: spotifyRecommendations.length,
                itemBuilder: (context, index) {
                  final track = spotifyRecommendations[index];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => playTrack(track),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Обложка с кнопкой Play
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: track.image.isNotEmpty
                                    ? Image.network(
                                        track.image,
                                        width: 160,
                                        height: 160,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 160,
                                            height: 160,
                                            color: Colors.grey[800],
                                            child: const Icon(
                                              Icons.music_note,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 160,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                              ),
                              // Play button overlay
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1DB954),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Название трека
                          Text(
                            track.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Исполнитель
                          Text(
                            track.artist,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
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
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 80,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Выбери настроение',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Нажми на категорию или кнопку Play\nчтобы начать слушать',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Рекомендации',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${aiTracks.length} треков',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
        if (aiTracks.isNotEmpty)
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