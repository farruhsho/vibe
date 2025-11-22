import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/track.dart';

class ImprovedMiniPlayer extends StatefulWidget {
  final AudioPlayer player;

  const ImprovedMiniPlayer({
    required this.player,
    super.key,
  });

  @override
  State<ImprovedMiniPlayer> createState() => ImprovedMiniPlayerState();
}

class ImprovedMiniPlayerState extends State<ImprovedMiniPlayer>
    with SingleTickerProviderStateMixin {
  Track? _currentTrack;
  List<Track> _queue = [];
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Listen for track completion
    widget.player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
    setState(() => _currentTrack = nextTrack);
  }

  void playPrevious() async {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    final prevTrack = _queue[_currentIndex];
    setState(() => _currentTrack = prevTrack);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: widget.player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final playing = playerState?.playing ?? false;
        final processing = playerState?.processingState;

        if (_currentTrack == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => _showExpandedPlayer(context),
          child: Container(
            height: 80,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E1E1E),
                  const Color(0xFF2A2A2A),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1DB954).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Progress bar at the bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: StreamBuilder<Duration?>(
                      stream: widget.player.positionStream,
                      builder: (context, positionSnapshot) {
                        final position = positionSnapshot.data ?? Duration.zero;
                        final duration = widget.player.duration ?? Duration.zero;
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0;

                        return Container(
                          height: 3,
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
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.transparent,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Album art with animation
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Hero(
                            tag: 'album_art_${_currentTrack?.id ?? ''}',
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _currentTrack != null &&
                                        _currentTrack!.image.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: _currentTrack!.image,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey[800],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Color(0xFF1DB954)),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.music_note,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF1DB954),
                                              const Color(0xFF1DB954)
                                                  .withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Track info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentTrack?.name ?? 'Загрузка...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (playing)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      child: const Icon(
                                        Icons.graphic_eq,
                                        color: Color(0xFF1DB954),
                                        size: 14,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      _currentTrack?.artist ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Previous button
                            IconButton(
                              icon: Icon(
                                Icons.skip_previous_rounded,
                                color: _queue.length > 1
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                              onPressed: _queue.length > 1 ? playPrevious : null,
                              iconSize: 28,
                              padding: EdgeInsets.zero,
                            ),

                            // Play/Pause button
                            Container(
                              width: 44,
                              height: 44,
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
                                    color: const Color(0xFF1DB954)
                                        .withOpacity(0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: processing == ProcessingState.loading ||
                                      processing == ProcessingState.buffering
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        playing
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        if (playing) {
                                          widget.player.pause();
                                        } else {
                                          widget.player.play();
                                        }
                                      },
                                      iconSize: 26,
                                      padding: EdgeInsets.zero,
                                    ),
                            ),

                            const SizedBox(width: 4),

                            // Next button
                            IconButton(
                              icon: Icon(
                                Icons.skip_next_rounded,
                                color: _queue.length > 1
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                              onPressed: _queue.length > 1 ? playNext : null,
                              iconSize: 28,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

// Expanded player (full screen)
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
      height: MediaQuery.of(context).size.height * 0.9,
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
                  icon: const Icon(Icons.expand_more,
                      color: Colors.white, size: 32),
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
                const SizedBox(width: 48),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Album Art
          Hero(
            tag: 'album_art_${currentTrack?.id ?? ''}',
            child: Container(
              width: MediaQuery.of(context).size.width - 64,
              height: MediaQuery.of(context).size.width - 64,
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withOpacity(0.5),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: currentTrack != null && currentTrack!.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: currentTrack!.image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1DB954)),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1DB954),
                              const Color(0xFF1DB954).withOpacity(0.5),
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

          const SizedBox(height: 40),

          // Track info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  currentTrack?.name ?? 'Неизвестный трек',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  currentTrack?.artist ?? 'Неизвестный исполнитель',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Progress slider
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
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 18),
                        activeTrackColor: const Color(0xFF1DB954),
                        inactiveTrackColor: Colors.grey[800],
                        thumbColor: const Color(0xFF1DB954),
                        overlayColor:
                            const Color(0xFF1DB954).withOpacity(0.3),
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
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
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
                // Shuffle
                IconButton(
                  icon: Icon(Icons.shuffle, color: Colors.grey[700]),
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
                  iconSize: 52,
                ),

                // Play/Pause
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    final processing = snapshot.data?.processingState;

                    return Container(
                      width: 80,
                      height: 80,
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
                            color:
                                const Color(0xFF1DB954).withOpacity(0.6),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: processing == ProcessingState.loading ||
                              processing == ProcessingState.buffering
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (playing) {
                                  player.pause();
                                } else {
                                  player.play();
                                }
                              },
                              iconSize: 48,
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
                  iconSize: 52,
                ),

                // Repeat
                IconButton(
                  icon: Icon(Icons.repeat, color: Colors.grey[700]),
                  onPressed: null,
                  iconSize: 28,
                ),
              ],
            ),
          ),

          const Spacer(),

          const SizedBox(height: 32),
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
}
