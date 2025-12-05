/// Player BLoC for Audio Playback State Management
///
/// Manages the playback state using the BLoC pattern.
/// Provides a clean separation between UI and business logic.

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/track.dart';
import '../../../data/datasources/local/player_service.dart';

// ============== EVENTS ==============

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

/// Play a single track
class PlayTrack extends PlayerEvent {
  final Track track;

  const PlayTrack(this.track);

  @override
  List<Object?> get props => [track];
}

/// Play a queue of tracks
class PlayQueue extends PlayerEvent {
  final List<Track> tracks;
  final int startIndex;

  const PlayQueue(this.tracks, {this.startIndex = 0});

  @override
  List<Object?> get props => [tracks, startIndex];
}

/// Resume playback
class ResumePlayback extends PlayerEvent {
  const ResumePlayback();
}

/// Pause playback
class PausePlayback extends PlayerEvent {
  const PausePlayback();
}

/// Toggle play/pause
class TogglePlayPause extends PlayerEvent {
  const TogglePlayPause();
}

/// Stop playback
class StopPlayback extends PlayerEvent {
  const StopPlayback();
}

/// Seek to position
class SeekTo extends PlayerEvent {
  final Duration position;

  const SeekTo(this.position);

  @override
  List<Object?> get props => [position];
}

/// Seek to progress (0.0 - 1.0)
class SeekToProgress extends PlayerEvent {
  final double progress;

  const SeekToProgress(this.progress);

  @override
  List<Object?> get props => [progress];
}

/// Skip to next track
class SkipNext extends PlayerEvent {
  const SkipNext();
}

/// Skip to previous track
class SkipPrevious extends PlayerEvent {
  const SkipPrevious();
}

/// Skip to specific index in queue
class SkipToIndex extends PlayerEvent {
  final int index;

  const SkipToIndex(this.index);

  @override
  List<Object?> get props => [index];
}

/// Add track to queue
class AddToQueue extends PlayerEvent {
  final Track track;

  const AddToQueue(this.track);

  @override
  List<Object?> get props => [track];
}

/// Remove track from queue
class RemoveFromQueue extends PlayerEvent {
  final int index;

  const RemoveFromQueue(this.index);

  @override
  List<Object?> get props => [index];
}

/// Clear the queue
class ClearQueue extends PlayerEvent {
  const ClearQueue();
}

/// Shuffle the queue
class ShuffleQueue extends PlayerEvent {
  const ShuffleQueue();
}

/// Set volume
class SetVolume extends PlayerEvent {
  final double volume;

  const SetVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}

/// Internal event for state updates from PlayerService
class _PlaybackStateUpdated extends PlayerEvent {
  final PlaybackState state;

  const _PlaybackStateUpdated(this.state);

  @override
  List<Object?> get props => [state];
}

// ============== STATE ==============

class PlayerState extends Equatable {
  final PlayerStatus status;
  final Track? currentTrack;
  final Duration position;
  final Duration duration;
  final bool isBuffering;
  final List<Track> queue;
  final int currentIndex;
  final double volume;
  final String? errorMessage;

  const PlayerState({
    this.status = PlayerStatus.idle,
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isBuffering = false,
    this.queue = const [],
    this.currentIndex = 0,
    this.volume = 1.0,
    this.errorMessage,
  });

  bool get isPlaying => status == PlayerStatus.playing;
  bool get isPaused => status == PlayerStatus.paused;
  bool get hasTrack => currentTrack != null;
  bool get hasQueue => queue.length > 1;
  bool get canSkipNext => currentIndex < queue.length - 1;
  bool get canSkipPrevious => currentIndex > 0;

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  String get positionText => _formatDuration(position);
  String get durationText => _formatDuration(duration);
  String get remainingText => _formatDuration(duration - position);

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  PlayerState copyWith({
    PlayerStatus? status,
    Track? currentTrack,
    Duration? position,
    Duration? duration,
    bool? isBuffering,
    List<Track>? queue,
    int? currentIndex,
    double? volume,
    String? errorMessage,
  }) {
    return PlayerState(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isBuffering: isBuffering ?? this.isBuffering,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      volume: volume ?? this.volume,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentTrack,
        position,
        duration,
        isBuffering,
        queue,
        currentIndex,
        volume,
        errorMessage,
      ];
}

// ============== BLOC ==============

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final PlayerService _playerService;
  StreamSubscription<PlaybackState>? _stateSubscription;

  PlayerBloc({required PlayerService playerService})
      : _playerService = playerService,
        super(const PlayerState()) {
    // Register event handlers
    on<PlayTrack>(_onPlayTrack);
    on<PlayQueue>(_onPlayQueue);
    on<ResumePlayback>(_onResume);
    on<PausePlayback>(_onPause);
    on<TogglePlayPause>(_onTogglePlayPause);
    on<StopPlayback>(_onStop);
    on<SeekTo>(_onSeekTo);
    on<SeekToProgress>(_onSeekToProgress);
    on<SkipNext>(_onSkipNext);
    on<SkipPrevious>(_onSkipPrevious);
    on<SkipToIndex>(_onSkipToIndex);
    on<AddToQueue>(_onAddToQueue);
    on<RemoveFromQueue>(_onRemoveFromQueue);
    on<ClearQueue>(_onClearQueue);
    on<ShuffleQueue>(_onShuffleQueue);
    on<SetVolume>(_onSetVolume);
    on<_PlaybackStateUpdated>(_onPlaybackStateUpdated);

    // Listen to player service state
    _stateSubscription = _playerService.stateStream.listen((playbackState) {
      add(_PlaybackStateUpdated(playbackState));
    });
  }

  Future<void> _onPlayTrack(PlayTrack event, Emitter<PlayerState> emit) async {
    emit(state.copyWith(
      status: PlayerStatus.loading,
      currentTrack: event.track,
    ));

    await _playerService.play(event.track);
  }

  Future<void> _onPlayQueue(PlayQueue event, Emitter<PlayerState> emit) async {
    if (event.tracks.isEmpty) return;

    emit(state.copyWith(
      status: PlayerStatus.loading,
      queue: event.tracks,
      currentIndex: event.startIndex,
    ));

    await _playerService.playQueue(event.tracks, startIndex: event.startIndex);
  }

  Future<void> _onResume(ResumePlayback event, Emitter<PlayerState> emit) async {
    await _playerService.resume();
  }

  Future<void> _onPause(PausePlayback event, Emitter<PlayerState> emit) async {
    await _playerService.pause();
  }

  Future<void> _onTogglePlayPause(TogglePlayPause event, Emitter<PlayerState> emit) async {
    await _playerService.togglePlayPause();
  }

  Future<void> _onStop(StopPlayback event, Emitter<PlayerState> emit) async {
    await _playerService.stop();
    emit(const PlayerState());
  }

  Future<void> _onSeekTo(SeekTo event, Emitter<PlayerState> emit) async {
    await _playerService.seek(event.position);
  }

  Future<void> _onSeekToProgress(SeekToProgress event, Emitter<PlayerState> emit) async {
    await _playerService.seekToProgress(event.progress);
  }

  Future<void> _onSkipNext(SkipNext event, Emitter<PlayerState> emit) async {
    await _playerService.skipNext();
  }

  Future<void> _onSkipPrevious(SkipPrevious event, Emitter<PlayerState> emit) async {
    await _playerService.skipPrevious();
  }

  Future<void> _onSkipToIndex(SkipToIndex event, Emitter<PlayerState> emit) async {
    await _playerService.skipToIndex(event.index);
  }

  void _onAddToQueue(AddToQueue event, Emitter<PlayerState> emit) {
    _playerService.addToQueue(event.track);
    emit(state.copyWith(queue: _playerService.queue));
  }

  void _onRemoveFromQueue(RemoveFromQueue event, Emitter<PlayerState> emit) {
    _playerService.removeFromQueue(event.index);
    emit(state.copyWith(
      queue: _playerService.queue,
      currentIndex: _playerService.currentIndex,
    ));
  }

  void _onClearQueue(ClearQueue event, Emitter<PlayerState> emit) {
    _playerService.clearQueue();
    emit(const PlayerState());
  }

  void _onShuffleQueue(ShuffleQueue event, Emitter<PlayerState> emit) {
    _playerService.shuffleQueue();
    emit(state.copyWith(queue: _playerService.queue));
  }

  Future<void> _onSetVolume(SetVolume event, Emitter<PlayerState> emit) async {
    await _playerService.setVolume(event.volume);
    emit(state.copyWith(volume: event.volume));
  }

  void _onPlaybackStateUpdated(_PlaybackStateUpdated event, Emitter<PlayerState> emit) {
    final playbackState = event.state;

    emit(state.copyWith(
      status: playbackState.status,
      currentTrack: playbackState.currentTrack,
      position: playbackState.position,
      duration: playbackState.duration,
      isBuffering: playbackState.isBuffering,
      queue: _playerService.queue,
      currentIndex: _playerService.currentIndex,
      errorMessage: playbackState.errorMessage,
    ));
  }

  @override
  Future<void> close() async {
    await _stateSubscription?.cancel();
    await _playerService.dispose();
    return super.close();
  }
}
