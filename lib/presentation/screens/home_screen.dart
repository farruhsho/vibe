/// Home Screen
///
/// Main screen of the app displaying personalized recommendations,
/// mood-based playlists, and quick access to music discovery.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/track.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/player/player_bloc.dart';
import '../theme/app_theme.dart';
import '../widgets/track_card.dart';
import '../widgets/mood_selector.dart';
import '../widgets/mini_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MoodCategory? _selectedMood;
  bool _isLoading = false;

  // Placeholder data - in real app, this would come from BLoC
  List<Track> _recommendations = [];
  List<Track> _recentlyPlayed = [];
  List<Track> _moodTracks = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    // TODO: Load data from repositories via BLoC
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  Future<void> _onMoodSelected(MoodCategory mood) async {
    setState(() {
      _selectedMood = mood;
      _isLoading = true;
    });
    // TODO: Fetch mood-based recommendations
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            slivers: [
              // App bar
              _buildAppBar(),

              // Greeting section
              SliverToBoxAdapter(child: _buildGreeting()),

              // Mood selector
              SliverToBoxAdapter(child: _buildMoodSection()),

              // Quick picks / Recommendations
              SliverToBoxAdapter(child: _buildRecommendationsSection()),

              // Recently played
              SliverToBoxAdapter(child: _buildRecentlyPlayedSection()),

              // Made for you
              SliverToBoxAdapter(child: _buildMadeForYouSection()),

              // Bottom padding for mini player
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 100),
              ),
            ],
          ),

          // Mini player
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(
              onTap: _showFullPlayer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.background,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Vibe',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.textPrimary,
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          color: AppColors.textPrimary,
          onPressed: () => _showSettings(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGreeting() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final greeting = _getGreeting();
        final name = state.displayName.split(' ').first;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.paddingM,
            AppDimens.paddingL,
            AppDimens.paddingM,
            AppDimens.paddingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "What's your vibe?",
                style: AppTextStyles.h3,
              ),
              if (_selectedMood != null)
                TextButton(
                  onPressed: () => setState(() => _selectedMood = null),
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        MoodChipList(
          selectedMood: _selectedMood,
          onMoodChanged: (mood) {
            if (mood != null) {
              _onMoodSelected(mood);
            } else {
              setState(() => _selectedMood = null);
            }
          },
        ),
        const SizedBox(height: AppDimens.paddingL),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: _selectedMood != null
              ? '${_selectedMood!.displayName} Tracks'
              : 'Recommended for you',
          subtitle: _selectedMood != null
              ? _selectedMood!.description
              : 'Based on your listening patterns',
          onSeeAll: () {},
        ),
        const SizedBox(height: AppDimens.paddingS),
        if (_isLoading)
          _buildLoadingList()
        else if (_recommendations.isEmpty)
          _buildEmptyState(
            icon: Icons.music_note,
            message: 'No recommendations yet',
            subtitle: 'Start listening to get personalized suggestions',
          )
        else
          _buildHorizontalTrackList(_recommendations),
        const SizedBox(height: AppDimens.paddingL),
      ],
    );
  }

  Widget _buildRecentlyPlayedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Recently Played',
          onSeeAll: () {},
        ),
        const SizedBox(height: AppDimens.paddingS),
        if (_recentlyPlayed.isEmpty)
          _buildEmptyState(
            icon: Icons.history,
            message: 'No recent plays',
            subtitle: 'Your listening history will appear here',
          )
        else
          _buildHorizontalTrackList(_recentlyPlayed),
        const SizedBox(height: AppDimens.paddingL),
      ],
    );
  }

  Widget _buildMadeForYouSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Made for You',
          subtitle: 'Discover new music tailored to your taste',
        ),
        const SizedBox(height: AppDimens.paddingM),
        _buildMixCards(),
        const SizedBox(height: AppDimens.paddingL),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h3),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all'),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTrackList(List<Track> tracks) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
        itemCount: tracks.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimens.paddingM),
        itemBuilder: (context, index) {
          final track = tracks[index];
          return TrackCard(
            track: track,
            mode: TrackCardMode.horizontal,
            onTap: () => _playTrack(track),
            onPlayTap: () => _playTrack(track),
          );
        },
      ),
    );
  }

  Widget _buildLoadingList() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimens.paddingM),
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 150,
            child: TrackCardSkeleton(mode: TrackCardMode.horizontal),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMixCards() {
    final mixes = [
      _MixCardData(
        title: 'Discovery Mix',
        subtitle: 'New releases for you',
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        icon: Icons.explore,
      ),
      _MixCardData(
        title: 'Focus Flow',
        subtitle: 'Deep concentration',
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
        ),
        icon: Icons.psychology,
      ),
      _MixCardData(
        title: 'Energy Boost',
        subtitle: 'Get pumped up',
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFF97316)],
        ),
        icon: Icons.flash_on,
      ),
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
        itemCount: mixes.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimens.paddingM),
        itemBuilder: (context, index) {
          final mix = mixes[index];
          return _buildMixCard(mix);
        },
      ),
    );
  }

  Widget _buildMixCard(_MixCardData data) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        gradient: data.gradient,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  data.icon,
                  size: 32,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const Spacer(),
                Text(
                  data.title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning,';
    } else if (hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  void _playTrack(Track track) {
    context.read<PlayerBloc>().add(PlayTrack(track));
  }

  void _showFullPlayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return const FullPlayerSheet();
        },
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusL),
        ),
      ),
      builder: (context) => _buildSettingsSheet(),
    );
  }

  Widget _buildSettingsSheet() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppDimens.paddingL),

          // User info
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    state.displayName.isNotEmpty
                        ? state.displayName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(state.displayName),
                subtitle: Text(state.email ?? ''),
              );
            },
          ),
          const Divider(),

          // Spotify connection
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Icons.music_note, color: Color(0xFF1DB954)),
                title: const Text('Spotify'),
                subtitle: Text(
                  state.isSpotifyConnected ? 'Connected' : 'Not connected',
                ),
                trailing: state.isSpotifyConnected
                    ? TextButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(const DisconnectSpotify());
                        },
                        child: const Text('Disconnect'),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(const ConnectSpotify());
                        },
                        child: const Text('Connect'),
                      ),
              );
            },
          ),
          const Divider(),

          // Sign out
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Sign Out'),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const SignOut());
            },
          ),
          const SizedBox(height: AppDimens.paddingL),
        ],
      ),
    );
  }
}

class _MixCardData {
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final IconData icon;

  const _MixCardData({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
  });
}
