import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

class MiniPlayer extends StatefulWidget {
  final AudioPlayer player;

  const MiniPlayer({
    required this.player,
    super.key,
  });

  @override
  State<MiniPlayer> createState() => MiniPlayerState();
}

class MiniPlayerState extends State<MiniPlayer> {
  Track? _currentTrack;
  List<Track> _queue = [];
  int _currentIndex = 0;

  void setTrack(Track track) {
    setState(() {
      _currentTrack = track;
    });
  }

  void setQueue(List<Track> tracks, {int startIndex = 0}) {
    setState(() {
      _queue = tracks;
      _currentIndex = startIndex;
      if (tracks.isNotEmpty && startIndex < tracks.length) {
        _currentTrack = tracks[startIndex];
      }
    });
  }

  void playNext() async {
    if (_queue.isEmpty) return;

    _currentIndex = (_currentIndex + 1) % _queue.length;
    final nextTrack = _queue[_currentIndex];

    if (nextTrack.previewUrl != null && nextTrack.previewUrl!.isNotEmpty) {
      try {
        await widget.player.setUrl(nextTrack.previewUrl!);
        await widget.player.play();
        setState(() {
          _currentTrack = nextTrack;
        });
      } catch (e) {
        debugPrint('Error playing next track: $e');
        // Try the next track if this one fails
        if (_queue.length > 1) {
          playNext();
        }
      }
    }
  }

  void playPrevious() async {
    if (_queue.isEmpty) return;

    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    final prevTrack = _queue[_currentIndex];

    if (prevTrack.previewUrl != null && prevTrack.previewUrl!.isNotEmpty) {
      try {
        await widget.player.setUrl(prevTrack.previewUrl!);
        await widget.player.play();
        setState(() {
          _currentTrack = prevTrack;
        });
      } catch (e) {
        debugPrint('Error playing previous track: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen for track completion to auto-play next
    widget.player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: widget.player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final playing = playerState?.playing ?? false;
        final processing = playerState?.processingState;

        // Show mini player if there's a track (even if not playing)
        if (_currentTrack == null) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E1E1E),
                const Color(0xFF121212),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Прогресс-бар (полная ширина)
              StreamBuilder<Duration?>(
                stream: widget.player.positionStream,
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final duration = widget.player.duration ?? Duration.zero;
                  final progress = duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0.0;

                  return GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      // Seek on drag
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null && duration.inMilliseconds > 0) {
                        final localPosition = details.localPosition;
                        final percentage = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
                        final newPosition = Duration(
                          milliseconds: (duration.inMilliseconds * percentage).round(),
                        );
                        widget.player.seek(newPosition);
                      }
                    },
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1DB954),
                            const Color(0xFF1ED760),
                          ],
                        ),
                      ),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[800],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1DB954),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  );
                },
              ),

              // Основной контент плеера
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Обложка с анимацией
                    GestureDetector(
                      onTap: () => _showExpandedPlayer(context),
                      child: Hero(
                        tag: 'album_art_${_currentTrack?.id ?? ''}',
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _currentTrack != null && _currentTrack!.image.isNotEmpty
                                ? Image.network(
                                    _currentTrack!.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF1DB954),
                                          const Color(0xFF1DB954).withValues(alpha: 0.5),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Информация о треке
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showExpandedPlayer(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentTrack?.name ?? 'Загрузка...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Иконка воспроизведения
                                if (playing)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.graphic_eq,
                                      color: const Color(0xFF1DB954),
                                      size: 14,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    _currentTrack?.artist ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            // Время и очередь
                            const SizedBox(height: 2),
                            StreamBuilder<Duration?>(
                              stream: widget.player.positionStream,
                              builder: (context, positionSnapshot) {
                                final position = positionSnapshot.data ?? Duration.zero;
                                final duration = widget.player.duration ?? Duration.zero;
                                return Row(
                                  children: [
                                    Text(
                                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (_queue.length > 1) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1DB954).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '${_currentIndex + 1}/${_queue.length}',
                                          style: const TextStyle(
                                            color: Color(0xFF1DB954),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Кнопки управления
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Previous button
                        IconButton(
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            color: _queue.length > 1 ? Colors.white : Colors.grey[700],
                          ),
                          onPressed: _queue.length > 1 ? playPrevious : null,
                          iconSize: 32,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),

                        const SizedBox(width: 8),

                        // Play/Pause button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1DB954),
                                Color(0xFF1ED760),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1DB954).withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: processing == ProcessingState.loading ||
                                  processing == ProcessingState.buffering
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    if (playing) {
                                      widget.player.pause();
                                    } else {
                                      widget.player.play();
                                    }
                                  },
                                  iconSize: 32,
                                  padding: EdgeInsets.zero,
                                ),
                        ),

                        const SizedBox(width: 8),

                        // Next button
                        IconButton(
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color: _queue.length > 1 ? Colors.white : Colors.grey[700],
                          ),
                          onPressed: _queue.length > 1 ? playNext : null,
                          iconSize: 32,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showExpandedPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExpandedPlayer(
        player: widget.player,
        currentTrack: _currentTrack,
        queue: _queue,
        currentIndex: _currentIndex,
        onNext: playNext,
        onPrevious: playPrevious,
      ),
    );
  }
}

// Расширенный плеер (полноэкранный)
class _ExpandedPlayer extends StatelessWidget {
  final AudioPlayer player;
  final Track? currentTrack;
  final List<Track> queue;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _ExpandedPlayer({
    required this.player,
    required this.currentTrack,
    required this.queue,
    required this.currentIndex,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF121212),
            Colors.black,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.expand_more, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
                Column(
                  children: [
                    const Text(
                      'Сейчас играет',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (queue.length > 1)
                      Text(
                        '${currentIndex + 1} из ${queue.length}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    // Show options menu
                    _showOptionsMenu(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Album Art
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Hero(
              tag: 'album_art_${currentTrack?.id ?? ''}',
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width - 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1DB954).withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: currentTrack != null && currentTrack!.image.isNotEmpty
                      ? Image.network(
                          currentTrack!.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 80,
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1DB954),
                                const Color(0xFF1DB954).withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Track Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  currentTrack?.name ?? 'Неизвестный трек',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  currentTrack?.artist ?? 'Неизвестный исполнитель',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: StreamBuilder<Duration?>(
              stream: player.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final duration = player.duration ?? Duration.zero;

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: const Color(0xFF1DB954),
                        inactiveTrackColor: Colors.grey[800],
                        thumbColor: const Color(0xFF1DB954),
                        overlayColor: const Color(0xFF1DB954).withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: duration.inMilliseconds > 0
                            ? position.inMilliseconds.toDouble()
                            : 0.0,
                        max: duration.inMilliseconds.toDouble() > 0
                            ? duration.inMilliseconds.toDouble()
                            : 1.0,
                        onChanged: (value) {
                          player.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Shuffle (disabled for now)
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: Colors.grey[700],
                  ),
                  onPressed: null,
                  iconSize: 28,
                ),

                // Previous
                IconButton(
                  icon: Icon(
                    Icons.skip_previous_rounded,
                    color: queue.length > 1 ? Colors.white : Colors.grey[700],
                  ),
                  onPressed: queue.length > 1 ? onPrevious : null,
                  iconSize: 48,
                ),

                // Play/Pause
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    final processing = snapshot.data?.processingState;

                    return Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1DB954),
                            Color(0xFF1ED760),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1DB954).withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: processing == ProcessingState.loading ||
                              processing == ProcessingState.buffering
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (playing) {
                                  player.pause();
                                } else {
                                  player.play();
                                }
                              },
                              iconSize: 40,
                            ),
                    );
                  },
                ),

                // Next
                IconButton(
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: queue.length > 1 ? Colors.white : Colors.grey[700],
                  ),
                  onPressed: queue.length > 1 ? onNext : null,
                  iconSize: 48,
                ),

                // Repeat (disabled for now)
                IconButton(
                  icon: Icon(
                    Icons.repeat,
                    color: Colors.grey[700],
                  ),
                  onPressed: null,
                  iconSize: 28,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Queue preview
          if (queue.length > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Далее в очереди',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: queue.length > 5 ? 5 : queue.length,
                      itemBuilder: (context, index) {
                        final nextIndex = (currentIndex + index + 1) % queue.length;
                        final track = queue[nextIndex];
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  track.image,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.queue_music, color: Colors.white),
                title: const Text('Показать очередь', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show queue
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: Colors.white),
                title: const Text('Добавить в избранное', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Add to favorites
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: const Text('Поделиться', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Share track
                },
              ),
            ],
          ),
        );
      },
    );
  }
}