/// Track Card Widget
///
/// A reusable widget for displaying track information.
/// Supports different display modes: list, grid, and compact.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../domain/entities/track.dart';
import '../theme/app_theme.dart';

/// Display mode for track cards
enum TrackCardMode {
  list, // Full width list item
  grid, // Square grid item
  compact, // Minimal horizontal card
  horizontal, // Horizontal scrolling card
}

class TrackCard extends StatelessWidget {
  final Track track;
  final TrackCardMode mode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onPlayTap;
  final VoidCallback? onMoreTap;
  final bool isPlaying;
  final bool showPlayButton;
  final bool showMoreButton;
  final bool showDuration;
  final int? index; // For numbered lists

  const TrackCard({
    super.key,
    required this.track,
    this.mode = TrackCardMode.list,
    this.onTap,
    this.onLongPress,
    this.onPlayTap,
    this.onMoreTap,
    this.isPlaying = false,
    this.showPlayButton = true,
    this.showMoreButton = true,
    this.showDuration = true,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case TrackCardMode.list:
        return _buildListCard(context);
      case TrackCardMode.grid:
        return _buildGridCard(context);
      case TrackCardMode.compact:
        return _buildCompactCard(context);
      case TrackCardMode.horizontal:
        return _buildHorizontalCard(context);
    }
  }

  Widget _buildListCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
          child: Row(
            children: [
              // Index number (optional)
              if (index != null) ...[
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index! + 1}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: AppDimens.paddingS),
              ],

              // Album art
              _buildAlbumArt(size: 56),
              const SizedBox(width: AppDimens.paddingM),

              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isPlaying ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (track.explicit)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textTertiary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'E',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            track.artistNames,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Duration
              if (showDuration) ...[
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  track.formattedDuration,
                  style: AppTextStyles.bodySmall,
                ),
              ],

              // More button
              if (showMoreButton) ...[
                const SizedBox(width: AppDimens.paddingXS),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  iconSize: 20,
                  color: AppColors.textSecondary,
                  onPressed: onMoreTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art with play button overlay
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: _buildAlbumArt(
                    borderRadius: AppDimens.radiusM,
                  ),
                ),
                if (showPlayButton)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _buildPlayButton(),
                  ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingS),

            // Track info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isPlaying ? AppColors.primary : AppColors.textPrimary,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.paddingS),
          child: Row(
            children: [
              _buildAlbumArt(size: 40),
              const SizedBox(width: AppDimens.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isPlaying ? AppColors.primary : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artistNames,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildAlbumArt(
                    size: 150,
                    borderRadius: AppDimens.radiusM,
                  ),
                  if (showPlayButton)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _buildPlayButton(size: 36),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.paddingS),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isPlaying ? AppColors.primary : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artistNames,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt({
    double? size,
    double borderRadius = AppDimens.radiusS,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: AppColors.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: track.albumImageUrl != null
          ? CachedNetworkImage(
              imageUrl: track.albumImageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildShimmer(),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: Container(color: AppColors.surface),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surface,
      child: const Icon(
        Icons.music_note,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildPlayButton({double size = 44}) {
    return Material(
      elevation: 4,
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPlayTap ?? onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}

/// Loading skeleton for track cards
class TrackCardSkeleton extends StatelessWidget {
  final TrackCardMode mode;

  const TrackCardSkeleton({
    super.key,
    this.mode = TrackCardMode.list,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: _buildSkeleton(),
    );
  }

  Widget _buildSkeleton() {
    switch (mode) {
      case TrackCardMode.list:
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
              ),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 180,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case TrackCardMode.grid:
      case TrackCardMode.horizontal:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 70,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );
      case TrackCardMode.compact:
        return Padding(
          padding: const EdgeInsets.all(AppDimens.paddingS),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
              ),
              const SizedBox(width: AppDimens.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 70,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}
