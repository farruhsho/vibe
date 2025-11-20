import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_pattern.dart';
import '../services/pattern_analyzer.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  UserPattern? _userPattern;
  Map<String, double>? _accuracyStats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Get or analyze user pattern
      var pattern = await PatternAnalyzer.getUserPattern(userId) ??
          await PatternAnalyzer.analyzeUserPattern(userId);

      // Get accuracy statistics
      final stats = await PatternAnalyzer.getAccuracyStats(userId);

      setState(() {
        _userPattern = pattern;
        _accuracyStats = stats;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Music Pattern'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _userPattern == null
              ? _buildNoDataView()
              : _buildAnalyticsView(),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No listening data yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Listen to more music to see your pattern!',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.music_note),
            label: const Text('Discover Music'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView() {
    final pattern = _userPattern!;
    final stats = _accuracyStats ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pattern Summary Card
          _buildSummaryCard(pattern, stats),
          const SizedBox(height: 16),

          // Audio Features Breakdown
          const Text(
            'Your Listening Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFeatureBar('Energy', pattern.avgEnergy, Colors.orange, Icons.flash_on),
          _buildFeatureBar('Mood (Valence)', pattern.avgValence, Colors.yellow, Icons.sentiment_satisfied),
          _buildFeatureBar('Danceability', pattern.avgDanceability, Colors.pink, Icons.directions_walk),
          _buildFeatureTempo(pattern.avgTempo),

          const SizedBox(height: 24),

          // Pattern Strength
          _buildPatternStrength(pattern),

          const SizedBox(height: 24),

          // Accuracy Stats
          if (stats['total_ratings'] != null && stats['total_ratings']! > 0)
            _buildAccuracyStats(stats),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(UserPattern pattern, Map<String, double> stats) {
    return Card(
      color: Colors.purple.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: Colors.purple, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pattern Analysis',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${pattern.totalTracksAnalyzed} tracks analyzed',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!pattern.isReliable)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Listen to more tracks for better recommendations',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBar(String label, double value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTempo(double tempo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Average Tempo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                '${tempo.toStringAsFixed(0)} BPM',
                style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatternStrength(UserPattern pattern) {
    final strength = pattern.patternStrength;
    final strengthPercent = (strength * 100).toStringAsFixed(0);

    Color strengthColor;
    String strengthLabel;

    if (strength > 0.7) {
      strengthColor = Colors.green;
      strengthLabel = 'Strong';
    } else if (strength > 0.4) {
      strengthColor = Colors.orange;
      strengthLabel = 'Moderate';
    } else {
      strengthColor = Colors.red;
      strengthLabel = 'Weak';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pattern Consistency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strengthLabel,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: strengthColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$strengthPercent% consistent',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: strengthColor.withValues(alpha: 0.2),
                  child: Text(
                    strengthPercent,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: strengthColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyStats(Map<String, double> stats) {
    final avgRating = stats['average_rating'] ?? 0.0;
    final totalRatings = stats['total_ratings']?.toInt() ?? 0;
    final accuracy = stats['accuracy'] ?? 0.0;

    return Card(
      color: Colors.green.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Recommendation Quality',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '${avgRating.toStringAsFixed(1)}/5',
                  'Avg Rating',
                  Icons.star_rate,
                ),
                _buildStatItem(
                  '$totalRatings',
                  'Ratings',
                  Icons.rate_review,
                ),
                _buildStatItem(
                  '${(accuracy * 100).toStringAsFixed(0)}%',
                  'Accuracy',
                  Icons.verified,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
