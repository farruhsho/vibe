import 'package:cloud_firestore/cloud_firestore.dart';

/// User listening pattern based on audio feature analysis
class UserPattern {
  final String userId;
  final double avgEnergy;
  final double avgValence;
  final double avgDanceability;
  final double avgTempo;
  final int totalTracksAnalyzed;
  final DateTime lastUpdated;

  // Feature preferences (standard deviation shows variety preference)
  final double energyStdDev;
  final double valenceStdDev;
  final double danceabilityStdDev;
  final double tempoStdDev;

  // Time of day patterns (optional for future enhancement)
  final Map<String, double>? timeOfDayPreferences;

  UserPattern({
    required this.userId,
    required this.avgEnergy,
    required this.avgValence,
    required this.avgDanceability,
    required this.avgTempo,
    required this.totalTracksAnalyzed,
    required this.lastUpdated,
    this.energyStdDev = 0.0,
    this.valenceStdDev = 0.0,
    this.danceabilityStdDev = 0.0,
    this.tempoStdDev = 0.0,
    this.timeOfDayPreferences,
  });

  factory UserPattern.fromJson(Map<String, dynamic> json) {
    return UserPattern(
      userId: json['user_id'] ?? '',
      avgEnergy: (json['avg_energy'] as num?)?.toDouble() ?? 0.5,
      avgValence: (json['avg_valence'] as num?)?.toDouble() ?? 0.5,
      avgDanceability: (json['avg_danceability'] as num?)?.toDouble() ?? 0.5,
      avgTempo: (json['avg_tempo'] as num?)?.toDouble() ?? 120.0,
      totalTracksAnalyzed: (json['total_tracks_analyzed'] as num?)?.toInt() ?? 0,
      lastUpdated: (json['last_updated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      energyStdDev: (json['energy_std_dev'] as num?)?.toDouble() ?? 0.0,
      valenceStdDev: (json['valence_std_dev'] as num?)?.toDouble() ?? 0.0,
      danceabilityStdDev: (json['danceability_std_dev'] as num?)?.toDouble() ?? 0.0,
      tempoStdDev: (json['tempo_std_dev'] as num?)?.toDouble() ?? 0.0,
      timeOfDayPreferences: json['time_of_day_preferences'] != null
          ? Map<String, double>.from(json['time_of_day_preferences'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'avg_energy': avgEnergy,
      'avg_valence': avgValence,
      'avg_danceability': avgDanceability,
      'avg_tempo': avgTempo,
      'total_tracks_analyzed': totalTracksAnalyzed,
      'last_updated': Timestamp.fromDate(lastUpdated),
      'energy_std_dev': energyStdDev,
      'valence_std_dev': valenceStdDev,
      'danceability_std_dev': danceabilityStdDev,
      'tempo_std_dev': tempoStdDev,
      if (timeOfDayPreferences != null)
        'time_of_day_preferences': timeOfDayPreferences,
    };
  }

  /// Get pattern strength (0.0-1.0) - how consistent the user preferences are
  double get patternStrength {
    // Lower std dev = stronger pattern
    final avgStdDev = (energyStdDev + valenceStdDev + danceabilityStdDev) / 3.0;
    return (1.0 - avgStdDev.clamp(0.0, 1.0)).clamp(0.0, 1.0);
  }

  /// Check if pattern has enough data to be reliable
  bool get isReliable => totalTracksAnalyzed >= 10;

  @override
  String toString() {
    return 'UserPattern(energy: ${avgEnergy.toStringAsFixed(2)}, '
           'valence: ${avgValence.toStringAsFixed(2)}, '
           'dance: ${avgDanceability.toStringAsFixed(2)}, '
           'tempo: ${avgTempo.toStringAsFixed(0)}, '
           'tracks: $totalTracksAnalyzed, '
           'strength: ${(patternStrength * 100).toStringAsFixed(0)}%)';
  }
}
