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

  void setTrack(Track track) {
    setState(() {
      _currentTrack = track;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: widget.player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final playing = playerState?.playing ?? false;

        // Если ничего не играет и не было трека - не показываем
        if (_currentTrack == null && !playing) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black87,
            boxShadow: [
              BoxShadow(
                // ИСПРАВЛЕНО: withOpacity → withValues
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Обложка
              if (_currentTrack != null && _currentTrack!.image.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _currentTrack!.image,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note, color: Colors.white),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    // ИСПРАВЛЕНО: withOpacity → withValues
                    color: Colors.purple.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white, size: 32),
                ),

              const SizedBox(width: 12),

              // Информация о треке
              Expanded(
                child: _currentTrack != null
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentTrack!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentTrack!.artist,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
                    : const Text(
                  'Загрузка...',
                  style: TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(width: 12),

              // Прогресс-бар
              StreamBuilder<Duration?>(
                stream: widget.player.positionStream,
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final duration = widget.player.duration ?? Duration.zero;

                  return SizedBox(
                    width: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${position.inSeconds}s',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: duration.inMilliseconds > 0
                              ? position.inMilliseconds / duration.inMilliseconds
                              : 0.0,
                          backgroundColor: Colors.grey[700],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(width: 12),

              // Кнопка Play/Pause
              const Container(
                decoration: BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
                child: _PlayPauseButton(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Отдельный виджет для кнопки Play/Pause - ИСПРАВЛЕНО: const constructor
class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton();

  @override
  Widget build(BuildContext context) {
    final miniPlayer = context.findAncestorStateOfType<MiniPlayerState>()!;

    return StreamBuilder<PlayerState>(
      stream: miniPlayer.widget.player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;

        return IconButton(
          icon: Icon(
            playing ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            if (playing) {
              miniPlayer.widget.player.pause();
            } else {
              miniPlayer.widget.player.play();
            }
          },
        );
      },
    );
  }
}