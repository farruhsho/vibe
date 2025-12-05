/// Mood Selector Widget
///
/// A widget for selecting mood categories for personalized recommendations.
/// Features animated cards with gradients based on mood type.

import 'package:flutter/material.dart';

import '../../domain/repositories/recommendation_repository.dart';
import '../theme/app_theme.dart';

class MoodSelector extends StatelessWidget {
  final MoodCategory? selectedMood;
  final ValueChanged<MoodCategory> onMoodSelected;
  final bool showLabels;
  final bool singleRow;
  final double cardSize;

  const MoodSelector({
    super.key,
    this.selectedMood,
    required this.onMoodSelected,
    this.showLabels = true,
    this.singleRow = false,
    this.cardSize = 100,
  });

  @override
  Widget build(BuildContext context) {
    if (singleRow) {
      return SizedBox(
        height: cardSize + (showLabels ? 30 : 0),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          itemCount: MoodCategory.values.length,
          separatorBuilder: (context, index) =>
              const SizedBox(width: AppDimens.paddingM),
          itemBuilder: (context, index) {
            final mood = MoodCategory.values[index];
            return _MoodCard(
              mood: mood,
              isSelected: selectedMood == mood,
              onTap: () => onMoodSelected(mood),
              size: cardSize,
              showLabel: showLabels,
            );
          },
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: AppDimens.paddingM,
        mainAxisSpacing: AppDimens.paddingM,
      ),
      itemCount: MoodCategory.values.length,
      itemBuilder: (context, index) {
        final mood = MoodCategory.values[index];
        return _MoodCard(
          mood: mood,
          isSelected: selectedMood == mood,
          onTap: () => onMoodSelected(mood),
          showLabel: showLabels,
        );
      },
    );
  }
}

class _MoodCard extends StatefulWidget {
  final MoodCategory mood;
  final bool isSelected;
  final VoidCallback onTap;
  final double? size;
  final bool showLabel;

  const _MoodCard({
    required this.mood,
    required this.isSelected,
    required this.onTap,
    this.size,
    this.showLabel = true,
  });

  @override
  State<_MoodCard> createState() => _MoodCardState();
}

class _MoodCardState extends State<_MoodCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: _getMoodGradient(widget.mood),
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                border: widget.isSelected
                    ? Border.all(
                        color: Colors.white,
                        width: 3,
                      )
                    : null,
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: _getMoodColor(widget.mood).withValues(alpha: 0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getMoodIcon(widget.mood),
                      size: widget.size != null ? widget.size! * 0.4 : 36,
                      color: Colors.white,
                    ),
                    if (!widget.showLabel && widget.size == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.mood.displayName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.showLabel && widget.size != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.mood.displayName,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: widget.isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  LinearGradient _getMoodGradient(MoodCategory mood) {
    final color = _getMoodColor(mood);
    return LinearGradient(
      colors: [
        color,
        color.withValues(alpha: 0.7),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getMoodColor(MoodCategory mood) {
    switch (mood) {
      case MoodCategory.energetic:
        return AppColors.moodEnergetic;
      case MoodCategory.chill:
        return AppColors.moodChill;
      case MoodCategory.happy:
        return AppColors.moodHappy;
      case MoodCategory.sad:
        return AppColors.moodSad;
      case MoodCategory.focus:
        return AppColors.moodFocus;
      case MoodCategory.workout:
        return AppColors.moodWorkout;
      case MoodCategory.party:
        return AppColors.moodParty;
      case MoodCategory.romantic:
        return AppColors.moodRomantic;
      case MoodCategory.sleep:
        return AppColors.moodSleep;
      case MoodCategory.meditation:
        return AppColors.moodMeditation;
    }
  }

  IconData _getMoodIcon(MoodCategory mood) {
    switch (mood) {
      case MoodCategory.energetic:
        return Icons.bolt;
      case MoodCategory.chill:
        return Icons.spa;
      case MoodCategory.happy:
        return Icons.emoji_emotions;
      case MoodCategory.sad:
        return Icons.water_drop;
      case MoodCategory.focus:
        return Icons.center_focus_strong;
      case MoodCategory.workout:
        return Icons.fitness_center;
      case MoodCategory.party:
        return Icons.celebration;
      case MoodCategory.romantic:
        return Icons.favorite;
      case MoodCategory.sleep:
        return Icons.bedtime;
      case MoodCategory.meditation:
        return Icons.self_improvement;
    }
  }
}

/// Compact mood chip for inline selection
class MoodChip extends StatelessWidget {
  final MoodCategory mood;
  final bool isSelected;
  final VoidCallback onTap;

  const MoodChip({
    super.key,
    required this.mood,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingS,
            ),
            decoration: BoxDecoration(
              color: isSelected ? _getMoodColor(mood) : AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
              border: Border.all(
                color: isSelected ? _getMoodColor(mood) : AppColors.surfaceLight,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getMoodIcon(mood),
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  mood.displayName,
                  style: AppTextStyles.label.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(MoodCategory mood) {
    switch (mood) {
      case MoodCategory.energetic:
        return AppColors.moodEnergetic;
      case MoodCategory.chill:
        return AppColors.moodChill;
      case MoodCategory.happy:
        return AppColors.moodHappy;
      case MoodCategory.sad:
        return AppColors.moodSad;
      case MoodCategory.focus:
        return AppColors.moodFocus;
      case MoodCategory.workout:
        return AppColors.moodWorkout;
      case MoodCategory.party:
        return AppColors.moodParty;
      case MoodCategory.romantic:
        return AppColors.moodRomantic;
      case MoodCategory.sleep:
        return AppColors.moodSleep;
      case MoodCategory.meditation:
        return AppColors.moodMeditation;
    }
  }

  IconData _getMoodIcon(MoodCategory mood) {
    switch (mood) {
      case MoodCategory.energetic:
        return Icons.bolt;
      case MoodCategory.chill:
        return Icons.spa;
      case MoodCategory.happy:
        return Icons.emoji_emotions;
      case MoodCategory.sad:
        return Icons.water_drop;
      case MoodCategory.focus:
        return Icons.center_focus_strong;
      case MoodCategory.workout:
        return Icons.fitness_center;
      case MoodCategory.party:
        return Icons.celebration;
      case MoodCategory.romantic:
        return Icons.favorite;
      case MoodCategory.sleep:
        return Icons.bedtime;
      case MoodCategory.meditation:
        return Icons.self_improvement;
    }
  }
}

/// Horizontal scrollable mood chips
class MoodChipList extends StatelessWidget {
  final MoodCategory? selectedMood;
  final ValueChanged<MoodCategory?> onMoodChanged;
  final bool allowDeselect;

  const MoodChipList({
    super.key,
    this.selectedMood,
    required this.onMoodChanged,
    this.allowDeselect = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
        itemCount: MoodCategory.values.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppDimens.paddingS),
        itemBuilder: (context, index) {
          final mood = MoodCategory.values[index];
          return MoodChip(
            mood: mood,
            isSelected: selectedMood == mood,
            onTap: () {
              if (selectedMood == mood && allowDeselect) {
                onMoodChanged(null);
              } else {
                onMoodChanged(mood);
              }
            },
          );
        },
      ),
    );
  }
}
