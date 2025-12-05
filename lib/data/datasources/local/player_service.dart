/// Audio Player Service
///
/// Provides a unified playback interface that supports:
/// 1. Preview playback using just_audio (30-second samples)
/// 2. Full playback via Spotify SDK (Premium required)
/// 3. Queue management and track navigation
/// 4. Playback state streaming
///
/// This abstraction allows seamless switching between playback modes
/// and provides a consistent API for the presentation layer.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../domain/entities/track.dart';

/// Playback mode
enum PlaybackMode {
  /// Using preview URLs with just_audio
  preview,

  /// Using Spotify SDK (requires Premium)
  spotifySdk,

  /// External playback (opens Spotify app)
  external,
}

/// Player state
enum PlayerStatus {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

/// Current playback state
class PlaybackState {
  final PlayerStatus status;
  final Track? currentTrack;
  final Duration position;
  final Duration duration;
  final bool isBuffering;
  final int? queueIndex;
  final int queueLength;
  final PlaybackMode mode;
  final String? errorMessage;

  const PlaybackState({
    this.status = PlayerStatus.idle,
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isBuffering = false,
    this.queueIndex,
    this.queueLength = 0,
    this.mode = PlaybackMode.preview,
    this.errorMessage,
  });

  bool get hasTrack => currentTrack != null;
  bool get isPlaying => status == PlayerStatus.playing;
  bool get isPaused => status == PlayerStatus.paused;
  bool get hasQueue => queueLength > 1;
  bool get canSkipNext => queueIndex != null && queueIndex! < queueLength - 1;
  bool get canSkipPrevious => queueIndex != null && queueIndex! > 0;

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  PlaybackState copyWith({
    PlayerStatus? status,
    Track? currentTrack,
    Duration? position,
    Duration? duration,
    bool? isBuffering,
    int? queueIndex,
    int? queueLength,
    PlaybackMode? mode,
    String? errorMessage,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isBuffering: isBuffering ?? this.isBuffering,
      queueIndex: queueIndex ?? this.queueIndex,
      queueLength: queueLength ?? this.queueLength,
      mode: mode ?? this.mode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Audio Player Service
class PlayerService {
  final AudioPlayer _audioPlayer;
  final List<Track> _queue = [];
  int _currentIndex = 0;
  Track? _currentTrack;

  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();

  PlayerService({AudioPlayer? audioPlayer})
      : _audioPlayer = audioPlayer ?? AudioPlayer() {
    _initializeListeners();
  }

  /// Stream of playback state changes
  Stream<PlaybackState> get stateStream => _stateController.stream;

  /// Current playback state
  PlaybackState get currentState => _buildCurrentState();

  /// Current track
  Track? get currentTrack => _currentTrack;

  /// Current queue
  List<Track> get queue => List.unmodifiable(_queue);

  /// Current queue index
  int get currentIndex => _currentIndex;

  /// Initialize audio player listeners
  void _initializeListeners() {
    // Player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      _emitState();
    });

    // Position updates
    _audioPlayer.positionStream.listen((position) {
      _emitState();
    });

    // Duration updates
    _audioPlayer.durationStream.listen((duration) {
      _emitState();
    });

    // Processing state (loading, buffering, etc.)
    _audioPlayer.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
      _emitState();
    });
  }

  /// Build current state from audio player
  PlaybackState _buildCurrentState() {
    final playerState = _audioPlayer.playerState;
    final processingState = playerState.processingState;

    PlayerStatus status;
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      status = PlayerStatus.loading;
    } else if (processingState == ProcessingState.completed) {
      status = PlayerStatus.completed;
    } else if (playerState.playing) {
      status = PlayerStatus.playing;
    } else if (_currentTrack != null) {
      status = PlayerStatus.paused;
    } else {
      status = PlayerStatus.idle;
    }

    return PlaybackState(
      status: status,
      currentTrack: _currentTrack,
      position: _audioPlayer.position,
      duration: _audioPlayer.duration ?? Duration.zero,
      isBuffering: processingState == ProcessingState.buffering,
      queueIndex: _queue.isNotEmpty ? _currentIndex : null,
      queueLength: _queue.length,
      mode: PlaybackMode.preview,
    );
  }

  /// Emit current state to stream
  void _emitState() {
    _stateController.add(_buildCurrentState());
  }

  /// Play a single track
  Future<void> play(Track track) async {
    _queue.clear();
    _queue.add(track);
    _currentIndex = 0;
    await _loadAndPlay(track);
  }

  /// Set queue and start playback
  Future<void> playQueue(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;

    _queue.clear();
    _queue.addAll(tracks.where((t) => t.hasPreview));
    _currentIndex = startIndex.clamp(0, _queue.length - 1);

    if (_queue.isNotEmpty) {
      await _loadAndPlay(_queue[_currentIndex]);
    }
  }

  /// Load and play a track
  Future<void> _loadAndPlay(Track track) async {
    _currentTrack = track;
    _emitState();

    if (track.previewUrl == null || track.previewUrl!.isEmpty) {
      debugPrint('No preview URL for track: ${track.name}');
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(track.previewUrl!);
      await _audioPlayer.play();
      debugPrint('Playing: ${track.name} by ${track.artist}');
    } catch (e) {
      debugPrint('Error playing track: $e');
      _stateController.add(PlaybackState(
        status: PlayerStatus.error,
        currentTrack: track,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Resume playback
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  /// Pause playback
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentTrack = null;
    _emitState();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Seek to percentage (0.0 - 1.0)
  Future<void> seekToProgress(double progress) async {
    final duration = _audioPlayer.duration;
    if (duration != null) {
      final position = Duration(
        milliseconds: (duration.inMilliseconds * progress).round(),
      );
      await seek(position);
    }
  }

  /// Skip to next track
  Future<void> skipNext() async {
    if (_queue.isEmpty) return;

    _currentIndex = (_currentIndex + 1) % _queue.length;
    await _loadAndPlay(_queue[_currentIndex]);
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    if (_queue.isEmpty) return;

    // If we're more than 3 seconds in, restart current track
    if (_audioPlayer.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    await _loadAndPlay(_queue[_currentIndex]);
  }

  /// Skip to specific index in queue
  Future<void> skipToIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;

    _currentIndex = index;
    await _loadAndPlay(_queue[_currentIndex]);
  }

  /// Handle track completion
  void _onTrackCompleted() {
    debugPrint('Track completed: ${_currentTrack?.name}');

    // Auto-play next if queue has more tracks
    if (_currentIndex < _queue.length - 1) {
      skipNext();
    }
  }

  /// Add track to end of queue
  void addToQueue(Track track) {
    if (track.hasPreview) {
      _queue.add(track);
      _emitState();
    }
  }

  /// Remove track from queue
  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;

    _queue.removeAt(index);

    // Adjust current index if needed
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex && _queue.isNotEmpty) {
      _currentIndex = _currentIndex.clamp(0, _queue.length - 1);
      _loadAndPlay(_queue[_currentIndex]);
    }

    _emitState();
  }

  /// Clear the queue
  void clearQueue() {
    _queue.clear();
    _currentIndex = 0;
    _currentTrack = null;
    _audioPlayer.stop();
    _emitState();
  }

  /// Shuffle the queue (keeps current track in place)
  void shuffleQueue() {
    if (_queue.length <= 1) return;

    final currentTrack = _queue[_currentIndex];
    _queue.removeAt(_currentIndex);
    _queue.shuffle();

    // Insert current track at beginning
    _queue.insert(0, currentTrack);
    _currentIndex = 0;

    _emitState();
  }

  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed.clamp(0.5, 2.0));
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _stateController.close();
  }
}
