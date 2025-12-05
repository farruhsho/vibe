/// Mini Player Widget
///
/// A compact player widget shown at the bottom of screens.
/// Displays current track info with playback controls.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../blocs/player/player_bloc.dart';
import '../theme/app_theme.dart';
import '../../data/datasources/local/player_service.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const MiniPlayer({
    super.key,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        // Don't show if no track
        if (!state.hasTrack || state.status == PlayerStatus.idle) {
          return const SizedBox.shrink();
        }

        final track = state.currentTrack!;

        return GestureDetector(
          onTap: onTap,
          onHorizontalDragEnd: (details) {
            // Swipe to dismiss
            if (details.primaryVelocity != null &&
                details.primaryVelocity!.abs() > 500) {
              onDismiss?.call();
              context.read<PlayerBloc>().add(const StopPlayback());
            }
          },
          child: Container(
            height: AppDimens.miniPlayerHeight,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              border: const Border(
                top: BorderSide(
                  color: AppColors.surfaceLight,
                  width: 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                _buildProgressBar(state),

                // Player content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingM,
                    ),
                    child: Row(
                      children: [
                        // Album art
                        _buildAlbumArt(track.albumImageUrl),
                        const SizedBox(width: AppDimens.paddingM),

                        // Track info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artistNames,
                                style: AppTextStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Controls
                        _buildControls(context, state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(PlayerState state) {
    return LinearProgressIndicator(
      value: state.progress.clamp(0.0, 1.0),
      backgroundColor: AppColors.surface,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      minHeight: 2,
    );
  }

  Widget _buildAlbumArt(String? imageUrl) {
    return Container(
      width: AppDimens.albumArtSize,
      height: AppDimens.albumArtSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildPlaceholder(),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surface,
      child: const Icon(
        Icons.music_note,
        color: AppColors.textTertiary,
        size: 28,
      ),
    );
  }

  Widget _buildControls(BuildContext context, PlayerState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like button
        IconButton(
          icon: const Icon(Icons.favorite_border),
          iconSize: 22,
          color: AppColors.textSecondary,
          onPressed: () {
            // TODO: Implement like functionality
          },
        ),

        // Play/Pause button
        _buildPlayPauseButton(context, state),

        // Skip next button
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 28,
          color: state.canSkipNext
              ? AppColors.textPrimary
              : AppColors.textTertiary,
          onPressed: state.canSkipNext
              ? () => context.read<PlayerBloc>().add(const SkipNext())
              : null,
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(BuildContext context, PlayerState state) {
    final isLoading =
        state.status == PlayerStatus.loading || state.isBuffering;

    if (isLoading) {
      return Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          state.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
        iconSize: 24,
        color: AppColors.background,
        padding: EdgeInsets.zero,
        onPressed: () {
          context.read<PlayerBloc>().add(const TogglePlayPause());
        },
      ),
    );
  }
}

/// Full-screen player bottom sheet
class FullPlayerSheet extends StatelessWidget {
  const FullPlayerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (!state.hasTrack) {
          return const SizedBox.shrink();
        }

        final track = state.currentTrack!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.backgroundLight,
                AppColors.background,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.paddingL),

                // Album art
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingXL,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: track.albumImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: track.albumImageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.surface,
                                child: const Icon(
                                  Icons.music_note,
                                  size: 100,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.paddingL),

                // Track info
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingL,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.name,
                                  style: AppTextStyles.h3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  track.artistNames,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_border),
                            color: AppColors.textSecondary,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.paddingM),

                // Progress slider
                _buildProgressSlider(context, state),
                const SizedBox(height: AppDimens.paddingS),

                // Time labels
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingL,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.positionText,
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        state.durationText,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.paddingM),

                // Main controls
                _buildMainControls(context, state),
                const SizedBox(height: AppDimens.paddingL),

                // Additional controls
                _buildAdditionalControls(context, state),
                const SizedBox(height: AppDimens.paddingL),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressSlider(BuildContext context, PlayerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        ),
        child: Slider(
          value: state.progress.clamp(0.0, 1.0),
          onChanged: (value) {
            context.read<PlayerBloc>().add(SeekToProgress(value));
          },
          activeColor: AppColors.textPrimary,
          inactiveColor: AppColors.surfaceLight,
        ),
      ),
    );
  }

  Widget _buildMainControls(BuildContext context, PlayerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle
          IconButton(
            icon: const Icon(Icons.shuffle),
            iconSize: 24,
            color: AppColors.textSecondary,
            onPressed: () {
              context.read<PlayerBloc>().add(const ShuffleQueue());
            },
          ),

          // Previous
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 40,
            color: state.canSkipPrevious
                ? AppColors.textPrimary
                : AppColors.textTertiary,
            onPressed: state.canSkipPrevious
                ? () => context.read<PlayerBloc>().add(const SkipPrevious())
                : null,
          ),

          // Play/Pause
          _buildLargePlayButton(context, state),

          // Next
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 40,
            color: state.canSkipNext
                ? AppColors.textPrimary
                : AppColors.textTertiary,
            onPressed: state.canSkipNext
                ? () => context.read<PlayerBloc>().add(const SkipNext())
                : null,
          ),

          // Repeat (placeholder)
          IconButton(
            icon: const Icon(Icons.repeat),
            iconSize: 24,
            color: AppColors.textSecondary,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLargePlayButton(BuildContext context, PlayerState state) {
    final isLoading =
        state.status == PlayerStatus.loading || state.isBuffering;

    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        shape: BoxShape.circle,
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
                ),
              ),
            )
          : IconButton(
              icon: Icon(
                state.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              iconSize: 36,
              color: AppColors.background,
              onPressed: () {
                context.read<PlayerBloc>().add(const TogglePlayPause());
              },
            ),
    );
  }

  Widget _buildAdditionalControls(BuildContext context, PlayerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.devices),
            color: AppColors.textSecondary,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share),
            color: AppColors.textSecondary,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.queue_music),
            color: AppColors.textSecondary,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
